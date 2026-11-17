import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/database/prisma.service';

/** Owns products, document types and consent definitions (master data). */
@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  listActiveProducts() {
    return this.prisma.product.findMany({
      where: { isActive: true },
      orderBy: { code: 'asc' },
    });
  }

  async getActiveProductByCode(code: string) {
    const product = await this.prisma.product.findFirst({
      where: { code, isActive: true },
    });
    if (!product) throw new NotFoundException(`Product ${code} not found`);
    return product;
  }

  getProductById(id: string) {
    return this.prisma.product.findUniqueOrThrow({ where: { id } });
  }

  getDocumentRequirements(productId: string) {
    return this.prisma.productDocumentRequirement.findMany({
      where: { productId, documentType: { isActive: true } },
      include: { documentType: true },
      orderBy: { documentType: { sortOrder: 'asc' } },
    });
  }

  getConsentRequirements(productId: string) {
    return this.prisma.productConsentRequirement.findMany({
      where: { productId, definition: { isActive: true } },
      include: { definition: true },
    });
  }

  async consentDefinitionExists(code: string, version: string) {
    const found = await this.prisma.consentDefinition.findUnique({
      where: { code_version: { code, version } },
      select: { code: true },
    });
    return !!found;
  }
}
