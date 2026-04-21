import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/features/categories/data/category_repository.dart';

final _categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(_categoriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('categories'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text('add_category'.tr()),
      ),
      body: cats.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: list.length,
          itemBuilder: (ctx, i) => _CategoryTile(category: list[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, WidgetRef ref, [Category? cat]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CategorySheet(category: cat),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(category.color).withOpacity(0.2),
          child: Text(category.icon, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(category.name.tr()),
        trailing: category.isDefault
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(categoryRepositoryProvider).delete(category.id),
              ),
      ),
    );
  }
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({this.category});
  final Category? category;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '📦';
  int _color = 0xFFB2BEC3;

  final _icons = ['📦', '🍔', '🚌', '🏠', '💊', '🎮', '🛍️', '📚', '💰', '💻', '✈️', '🎵', '🏋️', '🐾', '⚽'];
  final _colors = [
    0xFFFF6B6B, 0xFF4ECDC4, 0xFF45B7D1, 0xFF96CEB4, 0xFFFF9F43,
    0xFFA29BFE, 0xFF6C5CE7, 0xFF00B894, 0xFF00CEC9, 0xFFB2BEC3,
    0xFFFD79A8, 0xFFE17055, 0xFF74B9FF, 0xFF55EFC4,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameCtrl.text = widget.category!.name;
      _icon = widget.category!.icon;
      _color = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final repo = ref.read(categoryRepositoryProvider);
    final entry = CategoriesCompanion(
      name: Value(_nameCtrl.text),
      icon: Value(_icon),
      color: Value(_color),
    );
    if (widget.category != null) {
      await repo.update(widget.category!.id, entry);
    } else {
      await repo.insert(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (widget.category != null ? 'edit_category' : 'add_category').tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: InputDecoration(labelText: 'category_name'.tr()),
          ),
          const SizedBox(height: 16),
          Text('Icon', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((icon) => GestureDetector(
              onTap: () => setState(() => _icon = icon),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _icon == icon ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                ),
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
          Text('Color', style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((c) => GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: _color == c ? Colors.white : Colors.transparent, width: 3),
                  boxShadow: _color == c ? [BoxShadow(color: Color(c), blurRadius: 6)] : null,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text('save'.tr())),
        ],
      ),
    );
  }
}
