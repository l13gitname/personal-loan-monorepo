import { Injectable, Module, NotFoundException, BadRequestException } from '@nestjs/common';
import { QuotationStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/database/prisma.service';

export interface QuotationAccess {
  id: string;
  productId: string;
  status: QuotationStatus;
  userId: string;
}

/**
 * Narrow read-only facade that other modules (documents, ...) use to ask
 * "may this user touch this quotation?" without reading its tables.
 * After a service extraction this becomes a small client/API call.
 */
@Injectable()
export class QuotationAccessService {
  constructor(private readonly prisma: PrismaService) {}

  /** 404 (not 403) for other people's quotations to avoid leaking existence. */
  async getForUser(userId: string, quotationId: string): Promise<QuotationAccess> {
    const q = await this.prisma.loanQuotation.findFirst({
      where: { id: quotationId, userId, deletedAt: null },
      select: { id: true, productId: true, status: true, userId: true },
    });
    if (!q) throw new NotFoundException('Quotation not found');
    return q;
  }

  async getEditableForUser(userId: string, quotationId: string, allowed: QuotationStatus[] = ['DRAFT']) {
    const q = await this.getForUser(userId, quotationId);
    if (!allowed.includes(q.status)) {
      throw new BadRequestException(`Quotation in status ${q.status} cannot be modified`);
    }
    return q;
  }
}

@Module({ providers: [QuotationAccessService], exports: [QuotationAccessService] })
export class QuotationAccessModule {}
