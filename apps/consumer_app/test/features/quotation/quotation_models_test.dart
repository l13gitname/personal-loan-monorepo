import 'package:consumer_app/features/quotation/data/quotation_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shape returned by `GET /quotations/:id` (Prisma serialises Decimals as strings).
const _apiResponse = {
  'id': 'q-1',
  'quotationNo': 12,
  'status': 'DRAFT',
  'product': {
    'id': 'p-1',
    'code': 'MOTORCYCLE_LOAN',
    'type': 'MOTORCYCLE_LOAN',
    'name': 'Motorcycle hire-purchase',
    'minAmount': '5000',
    'maxAmount': '300000',
  },
  'applicant': {
    'firstName': 'Demo',
    'lastName': 'User',
    'phoneNumber': '0800000000',
    'birthDate': '1994-01-01T00:00:00.000Z',
  },
  'addresses': [
    {
      'kind': 'ID_CARD',
      'addressId': 'a-1',
      'address': {'houseNo': '1', 'postalCode': '10110'},
    },
  ],
  'occupations': [
    {'kind': 'MAIN', 'careerName': 'Engineer', 'salaryPerMonth': '30000.00'},
  ],
  'loanRequest': {
    'loanAmount': '48000.00',
    'termMonths': 24,
    'productValue': '50000.00',
    'downPayment': '2000.00',
  },
  'vehicle': {'brandCode': 'H', 'modelCode': 'M', 'modelYear': 2025},
  'consents': [
    {'consentCode': 'IDENTITY_APPROVE', 'consentVersion': '1.0', 'accepted': true},
  ],
};

void main() {
  test('parses a quotation detail response', () {
    final q = QuotationDetail.fromJson(_apiResponse);

    expect(q.isDraft, isTrue);
    expect(q.product.isMotorcycle, isTrue);
    expect(q.product.minAmount, 5000);
    expect(q.applicant?.birthDate, '1994-01-01');
    expect(q.address('ID_CARD')?.postalCode, '10110');
    expect(q.occupation('MAIN')?.salaryPerMonth, 30000);
    expect(q.loanRequest?.loanAmount, 48000);
    expect(q.loanRequest?.termMonths, 24);
    expect(q.vehicle?.modelYear, 2025);
    expect(q.consentAccepted('IDENTITY_APPROVE'), isTrue);
  });

  test('a save request only contains the sections that were set', () {
    const request = SaveQuotationRequest(
      loanRequest: LoanRequestData(loanAmount: 50000, termMonths: 24),
    );

    final json = request.toJson();
    expect(json.keys, ['loanRequest']);
    expect(json['loanRequest'], {'loanAmount': 50000, 'termMonths': 24});
  });

  test('consent is sent with the `version` key', () {
    const request = SaveQuotationRequest(
      consents: [
        ConsentData(consentCode: 'IDENTITY_APPROVE', version: '1.0', accepted: true),
      ],
    );

    expect(request.toJson()['consents'], [
      {'consentCode': 'IDENTITY_APPROVE', 'version': '1.0', 'accepted': true},
    ]);
  });
}
