import 'package:flutter/material.dart';

Future<Map<String, String>?> showFieldEditorSheet(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
}) {
  final controllers = {
    for (final entry in fields.entries)
      entry.key: TextEditingController(text: entry.value),
  };
  return showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final bottom = MediaQuery.viewInsetsOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final entry in fields.entries) ...[
              TextField(
                controller: controllers[entry.key],
                decoration: InputDecoration(labelText: entry.key),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    },
  );
}
