import { BadRequestException } from '@nestjs/common';
import { QuotationStatus } from '@prisma/client';

/**
 * One workflow for every product. Product differences are expressed through
 * ProductHandler validation, not through different state machines.
 */
const TRANSITIONS: Record<QuotationStatus, QuotationStatus[]> = {
  DRAFT: ['SUBMITTED', 'CANCELLED', 'EXPIRED'],
  SUBMITTED: ['IN_REVIEW', 'CANCELLED'],
  IN_REVIEW: ['APPROVED', 'REJECTED', 'CANCELLED'],
  APPROVED: ['CANCELLED', 'EXPIRED'],
  REJECTED: [],
  CANCELLED: [],
  EXPIRED: [],
};

export function assertTransition(from: QuotationStatus, to: QuotationStatus) {
  if (!TRANSITIONS[from].includes(to)) {
    throw new BadRequestException(`Cannot change status from ${from} to ${to}`);
  }
}
