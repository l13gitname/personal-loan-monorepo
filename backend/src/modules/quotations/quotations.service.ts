import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, QuotationStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import { CatalogService } from '../catalog/catalog.service';
import { DocumentsService } from '../documents/documents.service';
import {
  AddressDto,
  CreateQuotationDto,
  SaveQuotationDto,
} from './dto/quotation.dto';
import { assertTransition } from './quotation-workflow';
import {
  FULL_QUOTATION_INCLUDE,
  FullQuotation,
  ProductHandler,
} from './products/product-handler';
import { ProductHandlerRegistry } from './products/product-handler.registry';

type Tx = Prisma.TransactionClient;

interface Actor {
  userId: string;
  ip?: string;
}

const toDate = (value?: string) => (value ? new Date(value) : undefined);

@Injectable()
export class QuotationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly catalog: CatalogService,
    private readonly documents: DocumentsService,
    private readonly handlers: ProductHandlerRegistry,
  ) {}

  // ── Draft lifecycle ───────────────────────────────────────────────────────

  async createDraft(actor: Actor, dto: CreateQuotationDto) {
    const product = await this.catalog.getActiveProductByCode(dto.productCode);
    const handler = this.handlers.for(product.type);
    await this.assertSectionsAllowed(handler, dto);

    const id = await this.prisma.$transaction(async (tx) => {
      const quotation = await tx.loanQuotation.create({
        data: {
          userId: actor.userId,
          productId: product.id,
          channel: dto.channel,
          dealerCode: dto.dealerCode,
          checkerCode: dto.checkerCode,
          clientVersion: dto.clientVersion,
        },
      });
      await tx.quotationStatusHistory.create({
        data: { quotationId: quotation.id, toStatus: 'DRAFT', actorUserId: actor.userId },
      });
      await this.saveSections(tx, quotation.id, dto, actor);
      return quotation.id;
    });
    return this.findOne(actor.userId, id);
  }

  async saveDraft(actor: Actor, id: string, dto: SaveQuotationDto) {
    const quotation = await this.loadOwned(actor.userId, id);
    if (quotation.status !== 'DRAFT') {
      throw new BadRequestException(`Quotation in status ${quotation.status} cannot be modified`);
    }
    await this.assertSectionsAllowed(this.handlers.for(quotation.product.type), dto);

    await this.prisma.$transaction(async (tx) => {
      await this.saveSections(tx, id, dto, actor);
      await tx.loanQuotation.update({ where: { id }, data: { updatedAt: new Date() } });
    });
    return this.findOne(actor.userId, id);
  }

  // ── Workflow ──────────────────────────────────────────────────────────────

  async submit(actor: Actor, id: string) {
    const quotation = await this.loadOwned(actor.userId, id);
    assertTransition(quotation.status, 'SUBMITTED');

    const handler = this.handlers.for(quotation.product.type);
    const errors = [
      ...this.validateCommon(quotation),
      ...handler.validateForSubmit(quotation, quotation.product),
      ...(await this.validateDocuments(quotation)),
      ...(await this.validateConsents(quotation)),
    ];
    if (errors.length) {
      throw new BadRequestException({ message: 'Quotation is incomplete', errors });
    }

    await this.transition(quotation, 'SUBMITTED', actor.userId, undefined, {
      submittedAt: new Date(),
    });
    return this.findOne(actor.userId, id);
  }

  async cancel(actor: Actor, id: string, reason?: string) {
    const quotation = await this.loadOwned(actor.userId, id);
    assertTransition(quotation.status, 'CANCELLED');
    await this.transition(quotation, 'CANCELLED', actor.userId, reason);
    return this.findOne(actor.userId, id);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  findMine(userId: string) {
    return this.prisma.loanQuotation.findMany({
      where: { userId, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        quotationNo: true,
        status: true,
        createdAt: true,
        updatedAt: true,
        product: { select: { code: true, type: true, name: true } },
        loanRequest: { select: { loanAmount: true, termMonths: true, installmentAmount: true } },
        applicant: { select: { firstName: true, lastName: true } },
      },
    });
  }

  async findOne(userId: string, id: string) {
    const quotation = await this.prisma.loanQuotation.findFirst({
      where: { id, userId, deletedAt: null },
      include: {
        ...FULL_QUOTATION_INCLUDE,
        statusHistory: { orderBy: { createdAt: 'asc' } },
      },
    });
    if (!quotation) throw new NotFoundException('Quotation not found');
    return quotation;
  }

  private async loadOwned(userId: string, id: string): Promise<FullQuotation> {
    const quotation = await this.prisma.loanQuotation.findFirst({
      where: { id, userId, deletedAt: null },
      include: FULL_QUOTATION_INCLUDE,
    });
    if (!quotation) throw new NotFoundException('Quotation not found');
    return quotation;
  }

  // ── Transition + events (one DB transaction) ──────────────────────────────

  private transition(
    quotation: FullQuotation,
    to: QuotationStatus,
    actorUserId: string,
    reason?: string,
    extra: Prisma.LoanQuotationUpdateInput = {},
  ) {
    return this.prisma.$transaction(async (tx) => {
      // Optimistic guard: only move if the status is still what we validated.
      const moved = await tx.loanQuotation.updateMany({
        where: { id: quotation.id, status: quotation.status },
        data: { status: to, ...(extra as Prisma.LoanQuotationUpdateManyMutationInput) },
      });
      if (moved.count !== 1) {
        throw new BadRequestException('Quotation was changed by someone else; reload and retry');
      }
      await tx.quotationStatusHistory.create({
        data: {
          quotationId: quotation.id,
          fromStatus: quotation.status,
          toStatus: to,
          actorUserId,
          reason,
        },
      });
      await tx.outboxEvent.create({
        data: {
          aggregateType: 'quotation',
          aggregateId: quotation.id,
          eventType: `quotation.${to.toLowerCase()}`,
          payload: {
            quotationId: quotation.id,
            quotationNo: quotation.quotationNo,
            productCode: quotation.product.code,
            productType: quotation.product.type,
            loanAmount: quotation.loanRequest?.loanAmount?.toString() ?? null,
            termMonths: quotation.loanRequest?.termMonths ?? null,
          },
        },
      });
    });
  }

  // ── Submit-time validation ────────────────────────────────────────────────

  private validateCommon(q: FullQuotation): string[] {
    const errors: string[] = [];
    if (!q.applicant) errors.push('applicant: personal information is required');
    else {
      if (!q.applicant.idCardNumber && !q.applicant.passportNo) {
        errors.push('applicant: idCardNumber or passportNo is required');
      }
    }
    const kinds = new Set(q.addresses.map((a) => a.kind));
    if (!kinds.has('ID_CARD')) errors.push('addresses: ID_CARD address is required');
    if (!kinds.has('CONTACT')) errors.push('addresses: CONTACT address is required');

    const main = q.occupations.find((o) => o.kind === 'MAIN');
    if (!main || !main.salaryPerMonth) errors.push('occupations: MAIN occupation with salaryPerMonth is required');

    const loan = q.loanRequest;
    if (!loan) errors.push('loanRequest: loan information is required');
    else {
      const { minAmount, maxAmount, minTermMonths, maxTermMonths } = q.product;
      const amount = Number(loan.loanAmount);
      if (minAmount && amount < Number(minAmount)) errors.push(`loanRequest.loanAmount below minimum ${minAmount}`);
      if (maxAmount && amount > Number(maxAmount)) errors.push(`loanRequest.loanAmount above maximum ${maxAmount}`);
      if (minTermMonths && loan.termMonths < minTermMonths) errors.push(`loanRequest.termMonths below minimum ${minTermMonths}`);
      if (maxTermMonths && loan.termMonths > maxTermMonths) errors.push(`loanRequest.termMonths above maximum ${maxTermMonths}`);
    }
    return errors;
  }

  private async validateDocuments(q: FullQuotation): Promise<string[]> {
    const [requirements, counts] = await Promise.all([
      this.catalog.getDocumentRequirements(q.productId),
      this.documents.countActiveByType(q.id),
    ]);
    return requirements
      .filter((r) => r.isRequired && !counts[r.documentTypeCode])
      .map((r) => `documents: ${r.documentType.name} (${r.documentTypeCode}) is required`);
  }

  private async validateConsents(q: FullQuotation): Promise<string[]> {
    const requirements = await this.catalog.getConsentRequirements(q.productId);
    return requirements
      .filter((r) => r.isMandatory)
      .filter(
        (r) =>
          !q.consents.some(
            (c) => c.consentCode === r.consentCode && c.consentVersion === r.consentVersion && c.accepted,
          ),
      )
      .map((r) => `consents: ${r.definition.title} (${r.consentCode} v${r.consentVersion}) must be accepted`);
  }

  // ── Section persistence ───────────────────────────────────────────────────

  private async assertSectionsAllowed(handler: ProductHandler, dto: SaveQuotationDto) {
    if (dto.vehicle && !handler.acceptsVehicle) {
      throw new BadRequestException(`vehicle is not applicable to ${handler.type}`);
    }
    for (const c of dto.consents ?? []) {
      if (!(await this.catalog.consentDefinitionExists(c.consentCode, c.version))) {
        throw new BadRequestException(`Unknown consent ${c.consentCode} v${c.version}`);
      }
    }
  }

  private async saveSections(tx: Tx, quotationId: string, dto: SaveQuotationDto, actor: Actor) {
    if (dto.applicant) {
      const data = {
        ...dto.applicant,
        birthDate: toDate(dto.applicant.birthDate),
        idCardIssuedAt: toDate(dto.applicant.idCardIssuedAt),
        idCardExpiresAt: toDate(dto.applicant.idCardExpiresAt),
      };
      await tx.applicant.upsert({
        where: { quotationId },
        create: { quotationId, ...data },
        update: data,
      });
    }

    for (const { kind, ...address } of dto.addresses ?? []) {
      await this.saveAddress(tx, quotationId, kind, address);
    }

    for (const { kind, ...data } of dto.occupations ?? []) {
      await tx.occupation.upsert({
        where: { quotationId_kind: { quotationId, kind } },
        create: { quotationId, kind, ...data },
        update: data,
      });
    }

    if (dto.bankAccount) {
      await tx.bankAccount.upsert({
        where: { quotationId },
        create: { quotationId, ...dto.bankAccount },
        update: dto.bankAccount,
      });
    }

    if (dto.loanRequest) {
      await tx.loanRequest.upsert({
        where: { quotationId },
        create: { quotationId, ...dto.loanRequest },
        update: dto.loanRequest,
      });
    }

    if (dto.vehicle) {
      const data = { ...dto.vehicle, regDate: toDate(dto.vehicle.regDate) };
      await tx.vehicleDetail.upsert({
        where: { quotationId },
        create: { quotationId, ...data },
        update: data,
      });
    }

    if (dto.insurance) {
      await tx.quotationInsurance.upsert({
        where: { quotationId },
        create: { quotationId, ...dto.insurance },
        update: dto.insurance,
      });
    }

    for (const { address, role, ...rest } of dto.persons ?? []) {
      const existing = await tx.quotationPerson.findUnique({
        where: { quotationId_role: { quotationId, role } },
        select: { addressId: true },
      });
      let addressId = existing?.addressId ?? undefined;
      if (address) {
        if (addressId) await tx.address.update({ where: { id: addressId }, data: address });
        else addressId = (await tx.address.create({ data: address })).id;
      }
      await tx.quotationPerson.upsert({
        where: { quotationId_role: { quotationId, role } },
        create: { quotationId, role, ...rest, addressId },
        update: { ...rest, addressId },
      });
    }

    for (const c of dto.consents ?? []) {
      const data = {
        consentVersion: c.version,
        accepted: c.accepted,
        value: c.value,
        acceptedAt: c.accepted ? new Date() : null,
        ipAddress: actor.ip,
        recordedBy: actor.userId,
      };
      await tx.consentRecord.upsert({
        where: { quotationId_consentCode: { quotationId, consentCode: c.consentCode } },
        create: { quotationId, consentCode: c.consentCode, ...data },
        update: data,
      });
    }
  }

  private async saveAddress(tx: Tx, quotationId: string, kind: AddressKindT, data: AddressDto) {
    const link = await tx.quotationAddress.findUnique({
      where: { quotationId_kind: { quotationId, kind } },
    });
    if (link) {
      await tx.address.update({ where: { id: link.addressId }, data });
      return;
    }
    const address = await tx.address.create({ data });
    await tx.quotationAddress.create({ data: { quotationId, kind, addressId: address.id } });
  }
}

type AddressKindT = Prisma.QuotationAddressCreateInput['kind'];
