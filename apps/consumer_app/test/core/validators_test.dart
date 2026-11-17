import 'package:consumer_app/core/ui/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('thaiCitizenId', () {
    test('accepts a number with a correct check digit', () {
      expect(Validators.thaiCitizenId('1101700230708'), isNull);
    });

    test('rejects a wrong check digit', () {
      expect(Validators.thaiCitizenId('1101700230709'), 'Invalid ID number');
    });

    test('rejects wrong length and empty values', () {
      expect(Validators.thaiCitizenId('123'), 'Enter 13 digits');
      expect(Validators.thaiCitizenId(''), 'This field is required');
    });
  });

  group('phone', () {
    test('accepts 9-10 digit numbers starting with 0', () {
      expect(Validators.phone('0812345678'), isNull);
      expect(Validators.phone('021234567'), isNull);
    });

    test('rejects other formats', () {
      expect(Validators.phone('812345678'), isNotNull);
      expect(Validators.phone('08123'), isNotNull);
    });
  });

  group('numbers', () {
    test('positiveNumber', () {
      expect(Validators.positiveNumber('50,000'), isNull);
      expect(Validators.positiveNumber('0'), isNotNull);
      expect(Validators.positiveNumber('abc'), isNotNull);
    });

    test('positiveInt', () {
      expect(Validators.positiveInt('24'), isNull);
      expect(Validators.positiveInt('2.5'), isNotNull);
    });
  });

  test('postalCode needs exactly five digits', () {
    expect(Validators.postalCode('10110'), isNull);
    expect(Validators.postalCode('1011'), isNotNull);
  });
}
