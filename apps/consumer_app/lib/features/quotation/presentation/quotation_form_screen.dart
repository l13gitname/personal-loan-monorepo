import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'quotation_form_view_model.dart';
import 'steps/addresses_step.dart';
import 'steps/applicant_step.dart';
import 'steps/consent_step.dart';
import 'steps/documents_step.dart';
import 'steps/loan_step.dart';
import 'steps/work_step.dart';

/// Multi-step form shared by every loan product. Pass [productCode] for a new
/// draft or [quotationId] to resume one.
class QuotationFormScreen extends ConsumerStatefulWidget {
  const QuotationFormScreen({super.key, this.productCode, this.quotationId})
      : assert(productCode != null || quotationId != null);

  final String? productCode;
  final String? quotationId;

  @override
  ConsumerState<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends ConsumerState<QuotationFormScreen> {
  static const _titles = {
    QuotationStep.applicant: 'Personal information',
    QuotationStep.addresses: 'Addresses',
    QuotationStep.work: 'Work information',
    QuotationStep.loan: 'Loan information',
    QuotationStep.documents: 'Documents',
    QuotationStep.consent: 'Consent',
  };

  /// False until `start` has reset the (app-wide) view-model state, so a
  /// previous draft is never flashed for a frame.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Providers must not be modified while the widget tree is building.
    Future.microtask(() {
      if (!mounted) return;
      setState(() => _started = true);
      unawaited(
        ref.read(quotationFormViewModelProvider.notifier).start(
              productCode: widget.productCode,
              quotationId: widget.quotationId,
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quotationFormViewModelProvider);
    final vm = ref.read(quotationFormViewModelProvider.notifier);

    ref.listen(quotationFormViewModelProvider.select((s) => s.submitted), (_, submitted) {
      if (submitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation submitted')),
        );
        context.go('/');
      }
    });

    final total = QuotationStep.values.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(state.productDetail?.product.name ?? 'Quotation'),
        leading: state.step.index > 0 && !state.loading
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: vm.back)
            : null,
      ),
      body: SafeArea(
        child: !_started || state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.productDetail == null
                ? Center(child: Text(state.error ?? 'Unable to load the product'))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Step ${state.step.index + 1} of $total',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: (state.step.index + 1) / total),
                      const SizedBox(height: 20),
                      Text(
                        _titles[state.step]!,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 20),
                      if (state.error != null) _ErrorBanner(state.error!, state.errors),
                      _buildStep(state, vm),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStep(QuotationFormState state, QuotationFormViewModel vm) {
    final detail = state.detail;
    final product = state.productDetail!;

    // `key` makes each step rebuild its controllers when the step changes.
    switch (state.step) {
      case QuotationStep.applicant:
        return ApplicantStep(
          key: const ValueKey('applicant'),
          initial: detail?.applicant,
          saving: state.saving,
          onSave: vm.saveStep,
        );
      case QuotationStep.addresses:
        return AddressesStep(
          key: const ValueKey('addresses'),
          idCard: detail?.address('ID_CARD'),
          contact: detail?.address('CONTACT'),
          saving: state.saving,
          onSave: vm.saveStep,
        );
      case QuotationStep.work:
        return WorkStep(
          key: const ValueKey('work'),
          initial: detail?.occupation('MAIN'),
          saving: state.saving,
          onSave: vm.saveStep,
        );
      case QuotationStep.loan:
        return LoanStep(
          key: const ValueKey('loan'),
          product: product.product,
          loan: detail?.loanRequest,
          vehicle: detail?.vehicle,
          saving: state.saving,
          onSave: vm.saveStep,
        );
      case QuotationStep.documents:
        return DocumentsStep(
          key: const ValueKey('documents'),
          requirements: product.documents,
          documents: state.documents,
          saving: state.saving,
          onUpload: (type, file) => vm.uploadDocument(
            documentTypeCode: type,
            fileName: file.name,
            bytes: file.bytes,
          ),
          onRemove: vm.removeDocument,
          onContinue: () => vm.goTo(QuotationStep.consent),
        );
      case QuotationStep.consent:
        return ConsentStep(
          key: const ValueKey('consent'),
          requirements: product.consents,
          initial: detail?.consents ?? const [],
          saving: state.saving,
          onSubmit: vm.submit,
        );
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message, this.errors);

  final String message;
  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: scheme.onErrorContainer)),
          for (final e in errors.where((e) => e != message))
            Text('• $e', style: TextStyle(color: scheme.onErrorContainer)),
        ],
      ),
    );
  }
}
