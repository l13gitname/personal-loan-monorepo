import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../catalog/data/catalog_models.dart';
import '../../../documents/data/documents_repository.dart';

typedef PickedFile = ({String name, Uint8List bytes});

class DocumentsStep extends StatelessWidget {
  const DocumentsStep({
    super.key,
    required this.requirements,
    required this.documents,
    required this.saving,
    required this.onUpload,
    required this.onRemove,
    required this.onContinue,
  });

  final List<DocumentRequirement> requirements;
  final List<DocumentInfo> documents;
  final bool saving;
  final void Function(String typeCode, PickedFile file) onUpload;
  final void Function(DocumentInfo doc) onRemove;
  final VoidCallback onContinue;

  Future<void> _pick(BuildContext context, DocumentRequirement r) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Choose a PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    PickedFile? picked;
    if (source == 'pdf') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes != null) picked = (name: file!.name, bytes: file.bytes!);
    } else {
      // Resize/compress on-device to keep uploads small.
      final image = await ImagePicker().pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 2000,
      );
      if (image != null) picked = (name: image.name, bytes: await image.readAsBytes());
    }
    if (picked != null) onUpload(r.documentTypeCode, picked);
  }

  @override
  Widget build(BuildContext context) {
    final missingRequired = requirements.any(
      (r) => r.isRequired && !documents.any((d) => d.documentTypeCode == r.documentTypeCode),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in requirements) ...[
          _RequirementTile(
            requirement: r,
            files: documents.where((d) => d.documentTypeCode == r.documentTypeCode).toList(),
            saving: saving,
            onAdd: () => _pick(context, r),
            onRemove: onRemove,
          ),
          const SizedBox(height: 12),
        ],
        if (missingRequired)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Required documents are still missing.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          key: const Key('step-next'),
          onPressed: saving ? null : onContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _RequirementTile extends StatelessWidget {
  const _RequirementTile({
    required this.requirement,
    required this.files,
    required this.saving,
    required this.onAdd,
    required this.onRemove,
  });

  final DocumentRequirement requirement;
  final List<DocumentInfo> files;
  final bool saving;
  final VoidCallback onAdd;
  final void Function(DocumentInfo doc) onRemove;

  @override
  Widget build(BuildContext context) {
    final canAdd = files.length < requirement.maxFiles;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${requirement.documentType.name}${requirement.isRequired ? ' *' : ''}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (canAdd)
                  TextButton.icon(
                    onPressed: saving ? null : onAdd,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Add'),
                  ),
              ],
            ),
            for (final f in files)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(f.originalName, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(f.sizeBytes / 1024).toStringAsFixed(0)} KB'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: saving ? null : () => onRemove(f),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
