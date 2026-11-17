import { Injectable } from '@nestjs/common';
import { ProductType } from '@prisma/client';
import { FullQuotation, ProductHandler } from './product-handler';

@Injectable()
export class PersonalLoanHandler implements ProductHandler {
  readonly type = ProductType.PERSONAL_LOAN;
  readonly acceptsVehicle = false;

  // Unsecured loan: the common rules are enough for now. Add personal-loan
  // specific rules here (e.g. minimum income) once they are defined.
  validateForSubmit(_quotation: FullQuotation): string[] {
    return [];
  }
}
