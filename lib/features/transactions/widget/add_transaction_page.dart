import 'package:drift/drift.dart' hide Column;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/features/categories/data/category_repository.dart';
import 'package:hasap/features/transactions/data/transaction_repository.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  const AddTransactionPage({this.transactionId, super.key});
  final int? transactionId;

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    final tx = await ref.read(transactionRepositoryProvider).getById(widget.transactionId!);
    if (tx == null || !mounted) return;
    setState(() {
      _type = tx.type;
      _amountCtrl.text = tx.amount.toStringAsFixed(2);
      _noteCtrl.text = tx.note ?? '';
      _date = tx.date;
    });
    final cats = await ref.read(categoryRepositoryProvider).getAll();
    final cat = cats.where((c) => c.id == tx.categoryId).firstOrNull;
    if (mounted) setState(() => _selectedCategory = cat);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    setState(() => _loading = true);
    final repo = ref.read(transactionRepositoryProvider);
    final entry = TransactionsCompanion(
      amount: Value(double.parse(_amountCtrl.text)),
      note: Value(_noteCtrl.text.isEmpty ? null : _noteCtrl.text),
      categoryId: Value(_selectedCategory!.id),
      type: Value(_type),
      date: Value(_date),
    );
    if (widget.transactionId != null) {
      await repo.update(widget.transactionId!, entry);
    } else {
      await repo.insert(entry);
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transactionId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text((isEdit ? 'edit_transaction' : 'add_transaction').tr(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Income / Expense toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SegmentedButton<TransactionType>(
                  segments: [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('expense'.tr()),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('income'.tr()),
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _selectedCategory = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'amount'.tr(),
                prefixIcon: const Icon(Icons.attach_money_rounded),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'amount'.tr();
                if (double.tryParse(v) == null) return 'Invalid amount';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'note'.tr(),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Date picker
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).inputDecorationTheme.fillColor,
              leading: const Icon(Icons.calendar_today_rounded),
              title: Text('date'.tr()),
              trailing: Text(DateFormat('dd MMM yyyy').format(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),

            // Category
            Text('category'.tr(), style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _CategoryGrid(
              selectedId: _selectedCategory?.id,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            if (_selectedCategory == null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('category'.tr(), style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.selectedId, required this.onSelected});
  final int? selectedId;
  final ValueChanged<Category> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(allCategoriesProvider);

    return cats.when(
      data: (list) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.map((cat) {
          final isSelected = cat.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Color(cat.color) : Color(cat.color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Color(cat.color) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.icon),
                  const SizedBox(width: 4),
                  Text(
                    cat.name.tr(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text(e.toString()),
    );
  }
}
