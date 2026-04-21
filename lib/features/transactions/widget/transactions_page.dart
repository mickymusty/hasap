import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/features/transactions/data/transaction_repository.dart';

final _txPeriodProvider = StateProvider<PeriodFilter>((ref) => PeriodFilter.month);

final _transactionsProvider = StreamProvider.family<List<TransactionWithCategory>, PeriodFilter>(
  (ref, period) => ref.watch(transactionRepositoryProvider).watchAll(period),
);

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_txPeriodProvider);
    final txs = ref.watch(_transactionsProvider(period));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: Text('transactions'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        icon: const Icon(Icons.add),
        label: Text('add_transaction'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  (PeriodFilter.today, 'today'.tr()),
                  (PeriodFilter.week, 'this_week'.tr()),
                  (PeriodFilter.month, 'this_month'.tr()),
                  (PeriodFilter.all, 'All'),
                ].map((item) {
                  final isSelected = period == item.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(item.$2),
                      selected: isSelected,
                      onSelected: (_) => ref.read(_txPeriodProvider.notifier).state = item.$1,
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: txs.when(
              data: (list) => list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text('no_transactions'.tr(), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _TransactionTile(item: list[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.item});
  final TransactionWithCategory item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tx = item.transaction;
    final cat = item.category;
    final isIncome = tx.type == TransactionType.income;
    final amountColor = isIncome ? const Color(0xFF00B894) : const Color(0xFFE17055);
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('dd MMM', context.locale.toString());

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('delete'.tr()),
          content: Text('confirm_delete'.tr()),
          actions: [
            TextButton(onPressed: () => ctx.pop(false), child: Text('cancel'.tr())),
            FilledButton(onPressed: () => ctx.pop(true), child: Text('delete'.tr())),
          ],
        ),
      ),
      onDismissed: (_) => ref.read(transactionRepositoryProvider).delete(tx.id),
      child: GestureDetector(
        onTap: () => context.push('/transactions/add', extra: tx.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(cat.color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note?.isNotEmpty == true ? tx.note! : cat.name.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(fmt.format(tx.date), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
