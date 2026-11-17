import 'package:flutter/material.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/validators.dart';
import '../../../catalog/data/catalog_models.dart';
import '../../data/quotation_models.dart';

/// Loan amount and term for every product. Motorcycle loans additionally
/// collect the vehicle, price and down payment, which is the only place the
/// two products differ in the UI.
class LoanStep extends StatefulWidget {
  const LoanStep({
    super.key,
    required this.product,
    required this.loan,
    required this.vehicle,
    required this.saving,
    required this.onSave,
  });

  final Product product;
  final LoanRequestData? loan;
  final VehicleData? vehicle;
  final bool saving;
  final void Function(SaveQuotationRequest request) onSave;

  @override
  State<LoanStep> createState() => _LoanStepState();
}

class _LoanStepState extends State<LoanStep> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(text: widget.loan?.loanAmount.toStringAsFixed(0));
  late final _term = TextEditingController(text: widget.loan?.termMonths.toString());
  late final _purpose = TextEditingController(text: widget.loan?.purposeName);
  late final _price = TextEditingController(text: widget.loan?.productValue?.toStringAsFixed(0));
  late final _down = TextEditingController(text: widget.loan?.downPayment?.toStringAsFixed(0));
  late final _brandCode = TextEditingController(text: widget.vehicle?.brandCode);
  late final _brandName = TextEditingController(text: widget.vehicle?.brandName);
  late final _modelCode = TextEditingController(text: widget.vehicle?.modelCode);
  late final _modelName = TextEditingController(text: widget.vehicle?.modelName);
  late final _year = TextEditingController(text: widget.vehicle?.modelYear?.toString());
  late final _color = TextEditingController(text: widget.vehicle?.colorName);

  @override
  void dispose() {
    for (final c in [
      _amount, _term, _purpose, _price, _down,
      _brandCode, _brandName, _modelCode, _modelName, _year, _color,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.replaceAll(',', '').trim());

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  String? _amountRule(String? v) {
    final base = Validators.positiveNumber(v);
    if (base != null) return base;
    final n = double.parse(v!.replaceAll(',', '').trim());
    final min = widget.product.minAmount;
    final max = widget.product.maxAmount;
    if (min != null && n < min) return 'Minimum is ${min.toStringAsFixed(0)}';
    if (max != null && n > max) return 'Maximum is ${max.toStringAsFixed(0)}';
    return null;
  }

  String? _termRule(String? v) {
    final base = Validators.positiveInt(v);
    if (base != null) return base;
    final n = int.parse(v!.trim());
    final min = widget.product.minTermMonths;
    final max = widget.product.maxTermMonths;
    if (min != null && n < min) return 'Minimum is $min months';
    if (max != null && n > max) return 'Maximum is $max months';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final motorcycle = widget.product.isMotorcycle;
    widget.onSave(
      SaveQuotationRequest(
        loanRequest: LoanRequestData(
          loanAmount: _num(_amount)!,
          termMonths: int.parse(_term.text.trim()),
          purposeName: _text(_purpose),
          productValue: motorcycle ? _num(_price) : null,
          downPayment: motorcycle ? _num(_down) : null,
        ),
        vehicle: motorcycle
            ? VehicleData(
                brandCode: _text(_brandCode),
                brandName: _text(_brandName),
                modelCode: _text(_modelCode),
                modelName: _text(_modelName),
                modelYear: int.tryParse(_year.text.trim()),
                colorName: _text(_color),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motorcycle = widget.product.isMotorcycle;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (motorcycle) ...[
            Text('Motorcycle', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            // Codes are typed for now; replace with pickers when the
            // brand/model master-data API exists.
            AppTextField(label: 'Brand code', controller: _brandCode),
            AppTextField(label: 'Brand', controller: _brandName),
            AppTextField(label: 'Model code', controller: _modelCode),
            AppTextField(label: 'Model', controller: _modelName),
            AppTextField(
              label: 'Model year',
              controller: _year,
              keyboardType: TextInputType.number,
              digitsOnly: true,
              maxLength: 4,
              validator: Validators.positiveInt,
            ),
            AppTextField(label: 'Color', controller: _color, validator: null),
            AppTextField(
              label: 'Price (THB)',
              controller: _price,
              keyboardType: TextInputType.number,
              validator: Validators.positiveNumber,
            ),
            AppTextField(
              label: 'Down payment (THB)',
              controller: _down,
              keyboardType: TextInputType.number,
              validator: Validators.nonNegativeNumber,
            ),
            const Divider(height: 32),
          ],
          Text('Loan', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Loan amount (THB)',
            controller: _amount,
            keyboardType: TextInputType.number,
            validator: _amountRule,
          ),
          AppTextField(
            label: 'Term (months)',
            controller: _term,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            validator: _termRule,
          ),
          AppTextField(label: 'Purpose', controller: _purpose, validator: null),
          FilledButton(
            key: const Key('step-next'),
            onPressed: widget.saving ? null : _save,
            child: const Text('Save and continue'),
          ),
        ],
      ),
    );
  }
}
