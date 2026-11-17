import { Injectable } from '@nestjs/common';
import { Product, ProductType } from '@prisma/client';
import { FullQuotation, ProductHandler } from './product-handler';

@Injectable()
export class MotorcycleLoanHandler implements ProductHandler {
  readonly type = ProductType.MOTORCYCLE_LOAN;
  readonly acceptsVehicle = true;

  validateForSubmit(q: FullQuotation, product: Product): string[] {
    const errors: string[] = [];
    const v = q.vehicle;
    const loan = q.loanRequest;

    if (!v) {
      errors.push('vehicle: vehicle details are required');
    } else {
      if (!v.brandCode) errors.push('vehicle.brandCode is required');
      if (!v.modelCode) errors.push('vehicle.modelCode is required');
      if (!v.modelYear) errors.push('vehicle.modelYear is required');
    }

    if (loan) {
      const price = loan.productValue ? Number(loan.productValue) : null;
      const down = Number(loan.downPayment ?? 0);
      if (price === null) errors.push('loanRequest.productValue is required');
      else if (down >= price) {
        errors.push('loanRequest.downPayment must be lower than productValue');
      }

      // Optional LTV rule from product.rules, e.g. { "maxLtv": 0.9 }
      const maxLtv = (product.rules as { maxLtv?: number } | null)?.maxLtv;
      if (maxLtv && price) {
        const ltv = Number(loan.loanAmount) / price;
        if (ltv > maxLtv && !v?.isOverMaxLtv) {
          errors.push(`loanRequest: LTV ${ltv.toFixed(2)} exceeds ${maxLtv}`);
        }
        if (v?.isOverMaxLtv && !v.overMaxLtvReason) {
          errors.push('vehicle.overMaxLtvReason is required when over max LTV');
        }
      }
    }
    return errors;
  }
}
