import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomUUID } from 'crypto';
import { PrismaService } from '../../infrastructure/database/prisma.service';
import {
  STORAGE_PROVIDER,
  StorageProvider,
} from '../../infrastructure/storage/storage.provider';
import { CatalogService } from '../catalog/catalog.service';
import { QuotationAccessService } from '../quotations/quotation-access.service';

/** Allowed content, verified by magic bytes (never trust the client MIME). */
const SIGNATURES: { mime: string; test: (b: Buffer) => boolean }[] = [
  { mime: 'application/pdf', test: (b) => b.subarray(0, 5).toString('latin1') === '%PDF-' },
  { mime: 'image/jpeg', test: (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  {
    mime: 'image/png',
    test: (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
  },
];

@Injectable()
export class DocumentsService {
  readonly maxBytes: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly catalog: CatalogService,
    private readonly access: QuotationAccessService,
    private readonly config: ConfigService,
    @Inject(STORAGE_PROVIDER) private readonly storage: StorageProvider,
  ) {
    this.maxBytes = Number(config.get('MAX_UPLOAD_MB') ?? 10) * 1024 * 1024;
  }

  async upload(
    userId: string,
    quotationId: string,
    documentTypeCode: string,
    file: Express.Multer.File | undefined,
  ) {
    if (!file?.buffer?.length) throw new BadRequestException('file is required');
    if (file.size > this.maxBytes) throw new BadRequestException('File is too large');

    const quotation = await this.access.getEditableForUser(userId, quotationId, [
      'DRAFT',
      'SUBMITTED',
    ]);

    const requirements = await this.catalog.getDocumentRequirements(quotation.productId);
    const requirement = requirements.find((r) => r.documentTypeCode === documentTypeCode);
    if (!requirement) {
      throw new BadRequestException(`Document type ${documentTypeCode} is not accepted for this product`);
    }

    const detected = SIGNATURES.find((s) => s.test(file.buffer));
    if (!detected) throw new BadRequestException('Only PDF, JPEG and PNG files are accepted');

    const existing = await this.prisma.quotationDocument.count({
      where: { quotationId, documentTypeCode, status: 'ACTIVE' },
    });
    if (existing >= requirement.maxFiles) {
      throw new BadRequestException(`At most ${requirement.maxFiles} file(s) allowed for ${documentTypeCode}`);
    }

    const storageKey = `quotations/${quotationId}/${randomUUID()}`;
    await this.storage.put(storageKey, file.buffer);
    try {
      return await this.prisma.quotationDocument.create({
        data: {
          quotationId,
          documentTypeCode,
          // Display name only; it is never used to build a path.
          originalName: file.originalname.replace(/[\r\n"\\/]/g, '_').slice(0, 255),
          contentType: detected.mime,
          sizeBytes: file.size,
          sha256: createHash('sha256').update(file.buffer).digest('hex'),
          storageProvider: this.storage.name,
          storageKey,
          uploadedBy: userId,
        },
        select: this.publicSelect,
      });
    } catch (error) {
      await this.storage.delete(storageKey).catch(() => undefined);
      throw error;
    }
  }

  async list(userId: string, quotationId: string) {
    await this.access.getForUser(userId, quotationId);
    return this.prisma.quotationDocument.findMany({
      where: { quotationId, status: 'ACTIVE' },
      orderBy: { uploadedAt: 'asc' },
      select: this.publicSelect,
    });
  }

  async openForDownload(userId: string, quotationId: string, documentId: string) {
    await this.access.getForUser(userId, quotationId);
    const doc = await this.prisma.quotationDocument.findFirst({
      where: { id: documentId, quotationId, status: 'ACTIVE' },
    });
    if (!doc) throw new NotFoundException('Document not found');
    return { doc, stream: await this.storage.getStream(doc.storageKey) };
  }

  /** Soft-cancel: the file is kept for audit; a retention job purges it later. */
  async cancel(userId: string, quotationId: string, documentId: string) {
    await this.access.getEditableForUser(userId, quotationId);
    const result = await this.prisma.quotationDocument.updateMany({
      where: { id: documentId, quotationId, status: 'ACTIVE' },
      data: { status: 'CANCELLED', cancelledBy: userId, cancelledAt: new Date() },
    });
    if (result.count !== 1) throw new NotFoundException('Document not found');
    return { success: true };
  }

  /** Used by the quotation submit check. Returns { typeCode: activeFileCount }. */
  async countActiveByType(quotationId: string): Promise<Record<string, number>> {
    const rows = await this.prisma.quotationDocument.groupBy({
      by: ['documentTypeCode'],
      where: { quotationId, status: 'ACTIVE' },
      _count: { _all: true },
    });
    return Object.fromEntries(rows.map((r) => [r.documentTypeCode, r._count._all]));
  }

  private readonly publicSelect = {
    id: true,
    documentTypeCode: true,
    originalName: true,
    contentType: true,
    sizeBytes: true,
    scanStatus: true,
    uploadedAt: true,
  } as const;
}
