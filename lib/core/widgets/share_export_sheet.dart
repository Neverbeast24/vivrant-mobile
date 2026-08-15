import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/vivrant_colors.dart';
import '../utils/share_export.dart';

class ShareExportButton extends StatelessWidget {
  const ShareExportButton({
    super.key,
    required this.doc,
    this.enabled = true,
  });

  final ShareExportDoc doc;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Share or export',
      onPressed: enabled ? () => showShareExportSheet(context, doc) : null,
      icon: const Icon(Icons.ios_share_rounded),
    );
  }
}

Future<void> showShareExportSheet(BuildContext context, ShareExportDoc doc) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final c = VivrantColors.of(sheetCtx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share & export',
                style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                doc.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(sheetCtx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'SHARE',
                style: Theme.of(sheetCtx).textTheme.labelSmall?.copyWith(
                      color: c.accent,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              _OptionTile(
                icon: Icons.share_outlined,
                label: 'Share via apps',
                onTap: () => _run(sheetCtx, () => _shareText(doc)),
              ),
              _OptionTile(
                icon: Icons.copy_rounded,
                label: 'Copy as text',
                onTap: () => _run(sheetCtx, () => _copy(doc.text), success: 'Copied as text'),
              ),
              _OptionTile(
                icon: Icons.table_chart_outlined,
                label: 'Copy as CSV',
                onTap: () => _run(sheetCtx, () => _copy(doc.csv), success: 'Copied as CSV'),
              ),
              const SizedBox(height: 8),
              Text(
                'EXPORT',
                style: Theme.of(sheetCtx).textTheme.labelSmall?.copyWith(
                      color: c.accent,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              _OptionTile(
                icon: Icons.description_outlined,
                label: 'Share TXT file',
                onTap: () => _run(sheetCtx, () => _shareFile(doc, doc.text, 'txt', 'text/plain')),
              ),
              _OptionTile(
                icon: Icons.grid_on_outlined,
                label: 'Share CSV file',
                onTap: () => _run(
                  sheetCtx,
                  () => _shareFile(doc, doc.csv, 'csv', 'text/csv'),
                ),
              ),
              _OptionTile(
                icon: Icons.data_object_outlined,
                label: 'Share JSON file',
                onTap: () => _run(
                  sheetCtx,
                  () => _shareFile(doc, doc.json, 'json', 'application/json'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      minVerticalPadding: 12,
      onTap: onTap,
    );
  }
}

Future<void> _copy(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

Future<void> _shareText(ShareExportDoc doc) async {
  await SharePlus.instance.share(
    ShareParams(text: doc.text, subject: doc.title, title: doc.title),
  );
}

Future<void> _shareFile(
  ShareExportDoc doc,
  String content,
  String ext,
  String mime,
) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${doc.filename}.$ext');
  await file.writeAsString(content);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mime, name: '${doc.filename}.$ext')],
      subject: doc.title,
      title: doc.title,
    ),
  );
}

Future<void> _run(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  Navigator.of(context).pop();
  try {
    await action();
    if (success != null) {
      messenger?.showSnackBar(SnackBar(content: Text(success)));
    }
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text("Couldn't complete that. Try another option.")),
    );
  }
}
