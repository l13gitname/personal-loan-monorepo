import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CatalogService } from './catalog.service';

@ApiTags('products')
@ApiBearerAuth()
@Controller('products')
@UseGuards(JwtAuthGuard)
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get()
  list() {
    return this.catalog.listActiveProducts();
  }

  /** Product + the documents and consents the client must collect for it. */
  @Get(':code')
  async detail(@Param('code') code: string) {
    const product = await this.catalog.getActiveProductByCode(code);
    const [documents, consents] = await Promise.all([
      this.catalog.getDocumentRequirements(product.id),
      this.catalog.getConsentRequirements(product.id),
    ]);
    return { product, documents, consents };
  }
}
