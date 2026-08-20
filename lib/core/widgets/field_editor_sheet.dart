import 'package:flutter/material.dart';

Future<Map<String, String>?> showFieldEditorSheet(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
}) {
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _FieldEditorSheet(title: title, fields: fields),
  );
}

class _FieldEditorSheet extends StatefulWidget {
  const _FieldEditorSheet({required this.title, required this.fields});

  final String title;
  final Map<String, String> fields;

  @override
  State<_FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<_FieldEditorSheet> {
  late final Map<String, TextEditingController> _controllers = {
    for (final entry in widget.fields.entries)
      entry.key: TextEditingController(text: entry.value),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final entry in widget.fields.entries) ...[
            TextField(
              controller: _controllers[entry.key],
              decoration: InputDecoration(labelText: entry.key),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                for (final entry in _controllers.entries)
                  entry.key: entry.value.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
