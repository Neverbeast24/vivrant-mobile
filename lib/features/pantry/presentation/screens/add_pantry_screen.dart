import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/constants/enums.dart';

class AddPantryScreen extends ConsumerStatefulWidget {
  const AddPantryScreen({super.key});

  @override
  ConsumerState<AddPantryScreen> createState() => _AddPantryScreenState();
}

class _AddPantryScreenState extends ConsumerState<AddPantryScreen> {
  final _name = TextEditingController();
  String _category = 'other';
  double _stock = 50;
  bool _loading = false;
  EasyEntryMode _formMode = EasyEntryMode.list;

  @override
  void initState() {
    super.initState();
    loadEasyEntryMode('pantry-add').then((mode) {
      if (mounted) setState(() => _formMode = mode);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.showError('Enter a pantry item name.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).addPantry({
        'name': name,
        'category': _category,
        'stock_level': _stock.round(),
      });
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pasteSave(String text) async {
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).addPantryBulk(text);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
      rethrow;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Add pantry item')),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          EasyEntryToggle(
            value: _formMode,
            onChanged: (mode) {
              setState(() => _formMode = mode);
              saveEasyEntryMode('pantry-add', mode);
            },
          ),
          const SizedBox(height: 16),
          if (_formMode == EasyEntryMode.paste)
            QuickListPaste(
              pending: _loading,
              placeholder: 'brown rice\neggs\nmilk',
              onSubmit: _pasteSave,
            )
          else if (_formMode == EasyEntryMode.sheet) ...[
            Text(
              'Type a name and press add. Category and stock fill in.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Item name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: Text(_loading ? 'Saving…' : 'Add item'),
            ),
          ] else ...[
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: [
                for (final c in pantryCategories)
                  DropdownMenuItem(value: c, child: Text(labelForOption(c))),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'other'),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            Text(
              'Stock: ${_stock.round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              value: _stock,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_stock.round()}%',
              onChanged: (v) => setState(() => _stock = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: Text(_loading ? 'Saving…' : 'Save item'),
            ),
          ],
        ],
      ),
    );
  }
}
