import 'package:consumer_app/core/network/api_exception.dart';
import 'package:consumer_app/features/catalog/data/catalog_models.dart';
import 'package:consumer_app/features/catalog/data/catalog_repository.dart';
import 'package:consumer_app/features/documents/data/documents_repository.dart';
import 'package:consumer_app/features/quotation/data/quotation_models.dart';
import 'package:consumer_app/features/quotation/data/quotation_repository.dart';
import 'package:consumer_app/features/quotation/presentation/quotation_form_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQuotationRepository extends Mock implements QuotationRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockDocumentsRepository extends Mock implements DocumentsRepository {}

const _product = Product(
  id: 'p-1',
  code: 'MOTORCYCLE_LOAN',
  type: 'MOTORCYCLE_LOAN',
  name: 'Motorcycle hire-purchase',
);

const _productDetail = ProductDetail(product: _product);

const _draft = QuotationDetail(
  id: 'q-1',
  quotationNo: 1,
  status: 'DRAFT',
  product: _product,
);

void main() {
  late MockQuotationRepository quotations;
  late MockCatalogRepository catalog;
  late MockDocumentsRepository documents;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(const SaveQuotationRequest()));

  setUp(() {
    quotations = MockQuotationRepository();
    catalog = MockCatalogRepository();
    documents = MockDocumentsRepository();
    when(() => catalog.detail(any())).thenAnswer((_) async => _productDetail);
    when(() => documents.list(any())).thenAnswer((_) async => []);

    container = ProviderContainer(
      overrides: [
        quotationRepositoryProvider.overrideWithValue(quotations),
        catalogRepositoryProvider.overrideWithValue(catalog),
        documentsRepositoryProvider.overrideWithValue(documents),
      ],
    );
    addTearDown(container.dispose);
  });

  QuotationFormViewModel vm() => container.read(quotationFormViewModelProvider.notifier);
  QuotationFormState state() => container.read(quotationFormViewModelProvider);

  test('starting a new draft loads the product but does not call the API for a quotation', () async {
    await vm().start(productCode: 'MOTORCYCLE_LOAN');

    expect(state().loading, isFalse);
    expect(state().isMotorcycle, isTrue);
    expect(state().quotationId, isNull);
    verifyNever(() => quotations.get(any()));
  });

  test('first save creates the draft and advances; second save patches it', () async {
    when(() => quotations.create(any(), any())).thenAnswer((_) async => _draft);
    when(() => quotations.save(any(), any())).thenAnswer((_) async => _draft);

    await vm().start(productCode: 'MOTORCYCLE_LOAN');
    final first = await vm().saveStep(const SaveQuotationRequest());

    expect(first, isTrue);
    expect(state().quotationId, 'q-1');
    expect(state().step, QuotationStep.addresses);
    verify(() => quotations.create('MOTORCYCLE_LOAN', any())).called(1);

    await vm().saveStep(const SaveQuotationRequest());
    verify(() => quotations.save('q-1', any())).called(1);
    expect(state().step, QuotationStep.work);
  });

  test('a rejected save stays on the step and shows the message', () async {
    when(() => quotations.create(any(), any()))
        .thenThrow(const ApiException('Unknown or inactive product'));

    await vm().start(productCode: 'MOTORCYCLE_LOAN');
    final ok = await vm().saveStep(const SaveQuotationRequest());

    expect(ok, isFalse);
    expect(state().step, QuotationStep.applicant);
    expect(state().error, 'Unknown or inactive product');
    expect(state().saving, isFalse);
  });

  group('submit', () {
    setUp(() {
      when(() => quotations.get('q-1')).thenAnswer((_) async => _draft);
      when(() => quotations.save(any(), any())).thenAnswer((_) async => _draft);
    });

    test('marks the form as submitted on success', () async {
      when(() => quotations.submit('q-1')).thenAnswer((_) async => _draft);

      await vm().start(quotationId: 'q-1');
      await vm().submit(const []);

      expect(state().submitted, isTrue);
      expect(state().error, isNull);
    });

    test('exposes the server rule messages when the quotation is incomplete', () async {
      when(() => quotations.submit('q-1')).thenThrow(
        const ApiException(
          'Quotation is incomplete',
          errors: ['documents: National ID card (ID_CARD) is required'],
        ),
      );

      await vm().start(quotationId: 'q-1');
      await vm().submit(const []);

      expect(state().submitted, isFalse);
      expect(state().error, 'Quotation is incomplete');
      expect(state().errors, ['documents: National ID card (ID_CARD) is required']);
    });
  });
}
