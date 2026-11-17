import 'package:flutter/material.dart';
import '../../../catalog/data/catalog_models.dart';
import '../../data/quotation_models.dart';

/// Customer-facing consents. Staff checklist items are filled in by staff
/// tools, so they are not shown here.
class ConsentStep extends StatefulWidget {
  const ConsentStep({
    super.key,
    required this.requirements,
    required this.initial,
    required this.saving,
    required this.onSubmit,
  });

  final List<ConsentRequirement> requirements;
  final List<ConsentData> initial;
  final bool saving;
  final void Function(List<ConsentData> consents) onSubmit;

  @override
  State<ConsentStep> createState() => _ConsentStepState();
}

class _ConsentStepState extends State<ConsentStep> {
  late final Map<String, bool> _accepted;

  List<ConsentRequirement> get _visible => widget.requirements
      .where((r) => r.definition.category != 'STAFF_CHECKLIST')
      .toList();

  @override
  void initState() {
    super.initState();
    _accepted = {
      for (final r in _visible)
        r.consentCode:
            widget.initial.any((c) => c.consentCode == r.consentCode && c.accepted),
    };
  }

  bool get _mandatoryAccepted =>
      _visible.where((r) => r.isMandatory).every((r) => _accepted[r.consentCode] == true);

  void _submit() {
    widget.onSubmit([
      for (final r in _visible)
        ConsentData(
          consentCode: r.consentCode,
          version: r.consentVersion,
          accepted: _accepted[r.consentCode] ?? false,
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in _visible)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _accepted[r.consentCode] ?? false,
            onChanged: (v) => setState(() => _accepted[r.consentCode] = v ?? false),
            title: Text('${r.definition.title}${r.isMandatory ? ' *' : ''}'),
          ),
        const SizedBox(height: 8),
        Text(
          'Consent wording is loaded from the server and must be reviewed and '
          'versioned by legal before production.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('submit-quotation'),
          onPressed: widget.saving || !_mandatoryAccepted ? null : _submit,
          child: const Text('Submit quotation'),
        ),
      ],
    );
  }
}
