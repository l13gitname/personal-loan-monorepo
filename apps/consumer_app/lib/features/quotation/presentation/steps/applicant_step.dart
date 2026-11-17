import 'package:flutter/material.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/validators.dart';
import '../../data/quotation_models.dart';

class ApplicantStep extends StatefulWidget {
  const ApplicantStep({
    super.key,
    required this.initial,
    required this.saving,
    required this.onSave,
  });

  final ApplicantData? initial;
  final bool saving;
  final void Function(SaveQuotationRequest request) onSave;

  @override
  State<ApplicantStep> createState() => _ApplicantStepState();
}

class _ApplicantStepState extends State<ApplicantStep> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.titleName);
  late final _first = TextEditingController(text: widget.initial?.firstName);
  late final _last = TextEditingController(text: widget.initial?.lastName);
  late final _birth = TextEditingController(text: widget.initial?.birthDate);
  late final _phone = TextEditingController(text: widget.initial?.phoneNumber);
  late final _idCard = TextEditingController(text: widget.initial?.idCardNumber);

  @override
  void dispose() {
    for (final c in [_title, _first, _last, _birth, _phone, _idCard]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    String? clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    widget.onSave(
      SaveQuotationRequest(
        applicant: ApplicantData(
          titleName: clean(_title),
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          birthDate: clean(_birth),
          phoneNumber: _phone.text.trim(),
          idCardNumber: clean(_idCard),
        ),
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
          AppTextField(label: 'Title (e.g. Mr., Ms.)', controller: _title, validator: null),
          AppTextField(label: 'First name', controller: _first),
          AppTextField(label: 'Last name', controller: _last),
          AppDateField(label: 'Date of birth', controller: _birth),
          AppTextField(
            label: 'Phone number',
            controller: _phone,
            keyboardType: TextInputType.phone,
            digitsOnly: true,
            maxLength: 10,
            validator: Validators.phone,
          ),
          AppTextField(
            label: 'National ID number',
            controller: _idCard,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            maxLength: 13,
            validator: Validators.thaiCitizenId,
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
