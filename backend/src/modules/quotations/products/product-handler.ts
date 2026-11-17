import { Prisma, Product, ProductType } from '@prisma/client';

export const FULL_QUOTATION_INCLUDE = {
  product: true,
  applicant: true,
  loanRequest: true,
  vehicle: true,
  insurance: true,
  bankAccount: true,
  signature: true,
  addresses: { include: { address: true } },
  occupations: true,
  persons: { include: { address: true } },
  consents: true,
} satisfies Prisma.LoanQuotationInclude;

export type FullQuotation = Prisma.LoanQuotationGetPayload<{
  include: typeof FULL_QUOTATION_INCLUDE;
}>;

/**
 * Product layer. Add a new loan product by implementing this interface and
 * registering it in ProductHandlerRegistry; the workflow stays untouched.
 */
export interface ProductHandler {
  readonly type: ProductType;
  /** Whether the vehicle section is meaningful for this product. */
  readonly acceptsVehicle: boolean;
  /** Product-specific completeness/business rules checked on submit. */
  validateForSubmit(quotation: FullQuotation, product: Product): string[];
}
