import { ConsentCategory, PrismaClient, ProductType } from '@prisma/client';

const prisma = new PrismaClient();

// NOTE: codes below are placeholders. Replace document codes with the legacy
// 4-char IMAGE_CODE values and load the legal wording for each consent
// (consent_definitions.body) before production.

const DOCUMENT_TYPES = [
  { code: 'ID_CARD', name: 'National ID card (front)', sortOrder: 10 },
  { code: 'SELFIE', name: 'Customer selfie / face compare', sortOrder: 20 },
  { code: 'PAYSLIP', name: 'Payslip / income proof', sortOrder: 30 },
  { code: 'BANK_STMT', name: 'Bank statement', sortOrder: 40 },
  { code: 'VEHICLE_PHOTO', name: 'Motorcycle photo', sortOrder: 50 },
  { code: 'BOOK_REG', name: 'Vehicle registration book', sortOrder: 60 },
  { code: 'SIGNATURE', name: 'Customer signature', sortOrder: 70 },
  { code: 'OTHER', name: 'Other supporting document', sortOrder: 99 },
];

const V = '1.0';
const consent = (
  code: string,
  title: string,
  category: ConsentCategory,
) => ({ code, version: V, title, category });

const CONSENTS = [
  // PDPA (legacy MPLS_CONSENT *_CONSENT_VALUE)
  consent('IDENTITY_APPROVE', 'Identity verification for credit approval and contracts', 'PDPA'),
  consent('MOTOR_INSURANCE', 'Share data for motor insurance', 'PDPA'),
  consent('NON_MOTOR_INSURANCE', 'Share data for life insurance (e.g. MRTA)', 'PDPA'),
  consent('ANALYZE', 'Analyze/research data to improve products', 'PDPA'),
  consent('INFO', 'Marketing information about products and services', 'PDPA'),
  consent('INFO_PARTY', 'Marketing by affiliates', 'PDPA'),
  consent('ANALYZE_PARTY', 'Analyze/research data by affiliates', 'PDPA'),
  consent('PRODUCT_INFO_PARTY', 'Product offers by affiliates', 'PDPA'),
  consent('FOLLOWUP', 'After-sales service and follow-up', 'PDPA'),
  consent('INFO_DEVELOP', 'IT system development', 'PDPA'),
  consent('FACE_COMPARE', 'Face comparison', 'PDPA'),
  consent('E_CONSENT', 'E-consent disclosure', 'PDPA'),
  consent('SALESHEET_ACCEPT', 'Sale sheet acknowledged', 'PDPA'),
  // Service
  consent('E_PAPER', 'e-contract / e-bill (1 sign-up, 2 change email, 3 cancel)', 'SERVICE'),
  // Staff checklist (legacy IS_CHECK_*)
  consent('CHK_SALE_SHEET', 'Staff explained the sale sheet', 'STAFF_CHECKLIST'),
  consent('CHK_PRODUCT_DETAIL', 'Staff explained product, fees and late-payment charges', 'STAFF_CHECKLIST'),
  consent('CHK_PAYMENT_RULE', 'Staff compared products and explained default consequences', 'STAFF_CHECKLIST'),
  consent('CHK_CONTRACT', 'Staff reviewed the hire-purchase contract', 'STAFF_CHECKLIST'),
  consent('CHK_TOTAL_LOSS', 'Staff explained total-loss insurance', 'STAFF_CHECKLIST'),
  consent('CHK_TOTAL_LOSS_COMPANY', 'Staff stated the insurer is the company\'s', 'STAFF_CHECKLIST'),
  consent('CHK_LIFE_LICENSE', 'Staff showed life-insurance broker licence', 'STAFF_CHECKLIST'),
  consent('CHK_LIFE_DETAIL', 'Staff explained life insurance is not a deposit', 'STAFF_CHECKLIST'),
  consent('CHK_LIFE_PLAN', 'Staff presented suitable life-insurance plans', 'STAFF_CHECKLIST'),
  consent('CHK_LIFE_COMPANY', 'Staff stated insurer, coverage and premium period', 'STAFF_CHECKLIST'),
  consent('CHK_LIFE_REFUND', 'Staff explained partial refund on early cancellation', 'STAFF_CHECKLIST'),
  consent('CHK_LIFE_CANCEL_15D', 'Staff explained 15-day cancellation right', 'STAFF_CHECKLIST'),
];

async function main() {
  for (const d of DOCUMENT_TYPES) {
    await prisma.documentType.upsert({ where: { code: d.code }, create: d, update: d });
  }
  for (const c of CONSENTS) {
    await prisma.consentDefinition.upsert({
      where: { code_version: { code: c.code, version: c.version } },
      create: c,
      update: { title: c.title, category: c.category },
    });
  }

  const personal = await prisma.product.upsert({
    where: { code: 'PERSONAL_LOAN' },
    create: {
      code: 'PERSONAL_LOAN',
      type: ProductType.PERSONAL_LOAN,
      name: 'Personal loan',
      minAmount: 5000,
      maxAmount: 500000,
      minTermMonths: 6,
      maxTermMonths: 60,
    },
    update: {},
  });
  const motorcycle = await prisma.product.upsert({
    where: { code: 'MOTORCYCLE_LOAN' },
    create: {
      code: 'MOTORCYCLE_LOAN',
      type: ProductType.MOTORCYCLE_LOAN,
      name: 'Motorcycle hire-purchase',
      minAmount: 5000,
      maxAmount: 300000,
      minTermMonths: 6,
      maxTermMonths: 48,
      rules: { maxLtv: 1.0 },
    },
    update: {},
  });
  // Amounts/terms/LTV above are illustrative development values only.

  const docs = (productId: string, rows: [string, boolean, number?][]) =>
    Promise.all(
      rows.map(([documentTypeCode, isRequired, maxFiles]) =>
        prisma.productDocumentRequirement.upsert({
          where: { productId_documentTypeCode: { productId, documentTypeCode } },
          create: { productId, documentTypeCode, isRequired, maxFiles: maxFiles ?? 1 },
          update: { isRequired, maxFiles: maxFiles ?? 1 },
        }),
      ),
    );

  await docs(personal.id, [
    ['ID_CARD', true],
    ['SELFIE', true],
    ['PAYSLIP', true],
    ['BANK_STMT', false, 3],
    ['SIGNATURE', false],
    ['OTHER', false, 5],
  ]);
  await docs(motorcycle.id, [
    ['ID_CARD', true],
    ['SELFIE', true],
    ['PAYSLIP', false],
    ['BANK_STMT', false, 3],
    ['VEHICLE_PHOTO', true, 4],
    ['BOOK_REG', false],
    ['SIGNATURE', false],
    ['OTHER', false, 5],
  ]);

  const mandatory = ['IDENTITY_APPROVE'];
  const everything = CONSENTS.filter((c) => c.category !== 'STAFF_CHECKLIST').map((c) => c.code);
  const motorOnly = CONSENTS.map((c) => c.code);
  const link = (productId: string, codes: string[]) =>
    Promise.all(
      codes.map((consentCode) =>
        prisma.productConsentRequirement.upsert({
          where: {
            productId_consentCode_consentVersion: { productId, consentCode, consentVersion: V },
          },
          create: { productId, consentCode, consentVersion: V, isMandatory: mandatory.includes(consentCode) },
          update: { isMandatory: mandatory.includes(consentCode) },
        }),
      ),
    );
  await link(personal.id, everything.filter((c) => !['MOTOR_INSURANCE', 'NON_MOTOR_INSURANCE'].includes(c)));
  await link(motorcycle.id, motorOnly);

  console.log('Seed completed: products, document types, consents. No customer data inserted.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
