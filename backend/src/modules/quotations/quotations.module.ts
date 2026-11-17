import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CatalogModule } from '../catalog/catalog.module';
import { DocumentsModule } from '../documents/documents.module';
import { MotorcycleLoanHandler } from './products/motorcycle-loan.handler';
import { PersonalLoanHandler } from './products/personal-loan.handler';
import { ProductHandlerRegistry } from './products/product-handler.registry';
import { QuotationAccessModule } from './quotation-access.service';
import { QuotationsController } from './quotations.controller';
import { QuotationsService } from './quotations.service';

@Module({
  imports: [AuthModule, CatalogModule, DocumentsModule, QuotationAccessModule],
  controllers: [QuotationsController],
  providers: [
    QuotationsService,
    ProductHandlerRegistry,
    PersonalLoanHandler,
    MotorcycleLoanHandler,
  ],
  exports: [QuotationsService],
})
export class QuotationsModule {}
