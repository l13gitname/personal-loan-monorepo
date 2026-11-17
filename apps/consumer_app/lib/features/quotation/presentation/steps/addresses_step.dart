import 'package:flutter/material.dart';
import '../../../../core/ui/app_text_field.dart';
import '../../../../core/ui/validators.dart';
import '../../data/quotation_models.dart';

/// Collects the ID-card address and the contact address.
class AddressesStep extends StatefulWidget {
  const AddressesStep({
    super.key,
    required this.idCard,
    required this.contact,
    required this.saving,
    required this.onSave,
  });

  final AddressEntry? idCard;
  final AddressEntry? contact;
  final bool saving;
  final void Function(SaveQuotationRequest request) onSave;

  @override
  State<AddressesStep> createState() => _AddressesStepState();
}

class _AddressFields {
  _AddressFields(AddressEntry? a)
      : houseNo = TextEditingController(text: a?.houseNo),
        subDistrict = TextEditingController(text: a?.subDistrict),
        district = TextEditingController(text: a?.district),
        province = TextEditingController(text: a?.provinceName),
        postal = TextEditingController(text: a?.postalCode);

  final TextEditingController houseNo;
  final TextEditingController subDistrict;
  final TextEditingController district;
  final TextEditingController province;
  final TextEditingController postal;

  void dispose() {
    for (final c in [houseNo, subDistrict, district, province, postal]) {
      c.dispose();
    }
  }

  AddressEntry toEntry(String kind) => AddressEntry(
        kind: kind,
        houseNo: houseNo.text.trim(),
        subDistrict: subDistrict.text.trim(),
        district: district.text.trim(),
        provinceName: province.text.trim(),
        postalCode: postal.text.trim(),
      );
}

class _AddressesStepState extends State<AddressesStep> {
  final _formKey = GlobalKey<FormState>();
  late final _idCard = _AddressFields(widget.idCard);
  late final _contact = _AddressFields(widget.contact);
  late bool _same = widget.contact == null ||
      (widget.contact?.houseNo == widget.idCard?.houseNo &&
          widget.contact?.postalCode == widget.idCard?.postalCode);

  @override
  void dispose() {
    _idCard.dispose();
    _contact.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final idEntry = _idCard.toEntry('ID_CARD');
    final contactEntry =
        _same ? idEntry.copyWith(kind: 'CONTACT') : _contact.toEntry('CONTACT');
    widget.onSave(SaveQuotationRequest(addresses: [idEntry, contactEntry]));
  }

  Widget _fields(_AddressFields f) => Column(
        children: [
          AppTextField(label: 'House no. / street', controller: f.houseNo),
          AppTextField(label: 'Sub-district', controller: f.subDistrict),
          AppTextField(label: 'District', controller: f.district),
          AppTextField(label: 'Province', controller: f.province),
          AppTextField(
            label: 'Postal code',
            controller: f.postal,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            maxLength: 5,
            validator: Validators.postalCode,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Address on ID card', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          _fields(_idCard),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Contact address is the same'),
            value: _same,
            onChanged: (v) => setState(() => _same = v),
          ),
          if (!_same) ...[
            Text('Contact address', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            _fields(_contact),
          ],
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
