import 'package:flutter/material.dart';

import 'primary_button.dart';

/// Multiline paste box for bulk-adding list items (notepad / Excel).
class QuickListPaste extends StatefulWidget {
  const QuickListPaste({
    super.key,
    required this.onSubmit,
    this.pending = false,
    this.placeholder = 'eggs\nmilk\nrice 5kg',
    this.hint =
        'One item per line. You can also paste from Excel (tabs or commas).',
    this.submitLabel = 'Add all',
  });

  final Future<void> Function(String text) onSubmit;
  final bool pending;
  final String placeholder;
  final String hint;
  final String submitLabel;

  @override
  State<QuickListPaste> createState() => _QuickListPasteState();
}

class _QuickListPasteState extends State<QuickListPaste> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  int get _lines => _text.text
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _text,
          minLines: 6,
          maxLines: 12,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            alignLabelWithHint: true,
            labelText: 'Paste list',
          ),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(widget.hint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        PrimaryButton(
          loading: widget.pending,
          label: _lines == 0
              ? widget.submitLabel
              : '${widget.submitLabel} · $_lines',
          onPressed: _text.text.trim().isEmpty || widget.pending
              ? null
              : () async {
                  final value = _text.text;
                  try {
                    await widget.onSubmit(value);
                    if (mounted) {
                      _text.clear();
                      setState(() {});
                    }
                  } catch (_) {
                    /* keep the paste so a failed add can be retried */
                  }
                },
        ),
      ],
    );
  }
}
