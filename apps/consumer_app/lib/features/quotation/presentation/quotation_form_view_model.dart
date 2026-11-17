import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../catalog/data/catalog_models.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../documents/data/documents_repository.dart';
import '../data/quotation_models.dart';
import '../data/quotation_repository.dart';
import '../../../core/network/api_exception.dart';

enum QuotationStep { applicant, addresses, work, loan, documents, consent }

/// Immutable UI state of the multi-step quotation form.
class QuotationFormState {
  const QuotationFormState({
    this.loading = true,
    this.saving = false,
    this.step = QuotationStep.applicant,
    this.productCode,
    this.quotationId,
    this.detail,
    this.productDetail,
    this.documents = const [],
    this.error,
    this.errors = const [],
    this.submitted = false,
  });

  final bool loading;
  final bool saving;
  final QuotationStep step;
  final String? productCode;
  final String? quotationId;
  final QuotationDetail? detail;
  final ProductDetail? productDetail;
  final List<DocumentInfo> documents;

  /// Main message of the last failure.
  final String? error;

  /// Detailed rule messages (e.g. what is missing on submit).
  final List<String> errors;
  final bool submitted;

  bool get isMotorcycle => productDetail?.product.isMotorcycle ?? false;

  QuotationFormState copyWith({
    bool? loading,
    bool? saving,
    QuotationStep? step,
    String? productCode,
    String? quotationId,
    QuotationDetail? detail,
    ProductDetail? productDetail,
    List<DocumentInfo>? documents,
    bool? submitted,
    String? error,
    List<String>? errors,
    bool clearError = false,
  }) {
    return QuotationFormState(
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      step: step ?? this.step,
      productCode: productCode ?? this.productCode,
      quotationId: quotationId ?? this.quotationId,
      detail: detail ?? this.detail,
      productDetail: productDetail ?? this.productDetail,
      documents: documents ?? this.documents,
      submitted: submitted ?? this.submitted,
      error: clearError ? null : (error ?? this.error),
      errors: clearError ? const [] : (errors ?? this.errors),
    );
  }
}

/// ViewModel: all form logic and API calls. Widgets only render state and
/// call these methods. The draft is saved on the server after every step, so
/// the user can leave and resume from `/quotations/:id`.
class QuotationFormViewModel extends Notifier<QuotationFormState> {
  @override
  QuotationFormState build() => const QuotationFormState();

  /// Start a new draft for [productCode], or resume [quotationId].
  Future<void> start({String? productCode, String? quotationId}) async {
    state = const QuotationFormState(loading: true);
    try {
      QuotationDetail? detail;
      var code = productCode;
      if (quotationId != null) {
        detail = await ref.read(quotationRepositoryProvider).get(quotationId);
        code = detail.product.code;
      }
      final productDetail = await ref.read(catalogRepositoryProvider).detail(code!);
      final documents = quotationId == null
          ? const <DocumentInfo>[]
          : await ref.read(documentsRepositoryProvider).list(quotationId);

      state = QuotationFormState(
        loading: false,
        productCode: code,
        quotationId: quotationId,
        detail: detail,
        productDetail: productDetail,
        documents: documents,
      );
    } on ApiException catch (e) {
      state = QuotationFormState(loading: false, error: e.message);
    }
  }

  void goTo(QuotationStep step) => state = state.copyWith(step: step, clearError: true);

  void back() {
    if (state.step.index > 0) goTo(QuotationStep.values[state.step.index - 1]);
  }

  /// Saves one or more sections (creating the draft on first save), then
  /// moves to the next step. Returns false if the server rejected the data.
  Future<bool> saveStep(SaveQuotationRequest request, {bool advance = true}) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      final repo = ref.read(quotationRepositoryProvider);
      final id = state.quotationId;
      final detail = id == null
          ? await repo.create(state.productCode!, request)
          : await repo.save(id, request);

      state = state.copyWith(
        saving: false,
        detail: detail,
        quotationId: detail.id,
        step: advance && state.step.index < QuotationStep.values.length - 1
            ? QuotationStep.values[state.step.index + 1]
            : state.step,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message, errors: e.errors);
      return false;
    }
  }

  Future<void> uploadDocument({
    required String documentTypeCode,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final id = state.quotationId;
    if (id == null) return;
    state = state.copyWith(saving: true, clearError: true);
    try {
      final doc = await ref.read(documentsRepositoryProvider).upload(
            quotationId: id,
            documentTypeCode: documentTypeCode,
            fileName: fileName,
            bytes: bytes,
          );
      state = state.copyWith(saving: false, documents: [...state.documents, doc]);
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
    }
  }

  Future<void> removeDocument(DocumentInfo doc) async {
    final id = state.quotationId;
    if (id == null) return;
    state = state.copyWith(saving: true, clearError: true);
    try {
      await ref.read(documentsRepositoryProvider).remove(id, doc.id);
      state = state.copyWith(
        saving: false,
        documents: state.documents.where((d) => d.id != doc.id).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message);
    }
  }

  /// Saves the consents, then submits. Server-side rules (common, product,
  /// documents, consents) come back as [QuotationFormState.errors].
  Future<void> submit(List<ConsentData> consents) async {
    final saved = await saveStep(SaveQuotationRequest(consents: consents), advance: false);
    if (!saved) return;

    state = state.copyWith(saving: true, clearError: true);
    try {
      final detail = await ref.read(quotationRepositoryProvider).submit(state.quotationId!);
      state = state.copyWith(saving: false, detail: detail, submitted: true);
      ref.invalidate(myQuotationsProvider);
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, error: e.message, errors: e.errors);
    }
  }
}

final quotationFormViewModelProvider =
    NotifierProvider<QuotationFormViewModel, QuotationFormState>(
  QuotationFormViewModel.new,
);
