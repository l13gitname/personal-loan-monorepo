import 'package:flutter/material.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/validators.dart';
import '../../data/quotation_models.dart';

class WorkStep extends StatefulWidget {
  const WorkStep({
    super.key,
    required this.initial,
    required this.saving,
    required this.onSave,
  });

  final OccupationData? initial;
  final bool saving;
  final void Function(SaveQuotationRequest request) onSave;

  @override
  State<WorkStep> createState() => _WorkStepState();
}

class _WorkStepState extends State<WorkStep> {
  final _formKey = GlobalKey<FormState>();
  late final _career = TextEditingController(text: widget.initial?.careerName);
  late final _workplace = TextEditingController(text: widget.initial?.workplaceName);
  late final _position = TextEditingController(text: widget.initial?.position);
  late final _salary = TextEditingController(
    text: widget.initial?.salaryPerMonth?.toStringAsFixed(0),
  );
  late final _phone = TextEditingController(text: widget.initial?.workplacePhone1);

  @override
  void dispose() {
    for (final c in [_career, _workplace, _position, _salary, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      SaveQuotationRequest(
        occupations: [
          OccupationData(
            kind: 'MAIN',
            careerName: _career.text.trim(),
            workplaceName: _workplace.text.trim(),
            position: _position.text.trim().isEmpty ? null : _position.text.trim(),
            salaryPerMonth: double.parse(_salary.text.replaceAll(',', '').trim()),
            workplacePhone1: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(label: 'Occupation', controller: _career),
          AppTextField(label: 'Workplace name', controller: _workplace),
          AppTextField(label: 'Position', controller: _position, validator: null),
          AppTextField(
            label: 'Monthly income (THB)',
            controller: _salary,
            keyboardType: TextInputType.number,
            validator: Validators.positiveNumber,
          ),
          AppTextField(
            label: 'Workplace phone',
            controller: _phone,
            keyboardType: TextInputType.phone,
            digitsOnly: true,
            validator: null,
          ),
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
