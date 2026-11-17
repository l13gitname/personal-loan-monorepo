import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ProductType } from '@prisma/client';
import { MotorcycleLoanHandler } from './motorcycle-loan.handler';
import { PersonalLoanHandler } from './personal-loan.handler';
import { ProductHandler } from './product-handler';

@Injectable()
export class ProductHandlerRegistry {
  private readonly handlers: Map<ProductType, ProductHandler>;

  constructor(personal: PersonalLoanHandler, motorcycle: MotorcycleLoanHandler) {
    this.handlers = new Map([personal, motorcycle].map((h) => [h.type, h]));
  }

  for(type: ProductType): ProductHandler {
    const handler = this.handlers.get(type);
    if (!handler) {
      throw new InternalServerErrorException(`No handler for product type ${type}`);
    }
    return handler;
  }
}
