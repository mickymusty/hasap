import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/features/transactions/data/transaction_repository.dart';

final _txPeriodProvider = StateProvider<PeriodFilter>((ref) => PeriodFilter.month);

final _transactionsProvider = StreamProvider.family<List<TransactionWithCategory>, PeriodFilter>((ref, period) {
  return ref.watch(transactionRepositoryProvider).watchAll(period);
});

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_txPeriodProvider);
    final txs = ref.watch(_transactionsProvider(period));

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/transactions/add'),
        icon: const Icon(Icons.add),
        label: Text('add_transaction'.tr()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<PeriodFilter>(
              segments: [
                ButtonSegment(value: PeriodFilter.today, label: Text('today'.tr())),
                ButtonSegment(value: PeriodFilter.week, label: Text('this_week'.tr())),
                ButtonSegment(value: PeriodFilter.month, label: Text('this_month'.tr())),
                ButtonSegment(value: PeriodFilter.all, label: const Text('All')),
              ],
              selected: {period},
              onSelectionChanged: (s) => ref.read(_txPeriodProvider.notifier).state = s.first,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: txs.when(
              data: (list) => list.isEmpty
                  ? Center(child: Text('no_transactions'.tr(), style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
    final color = isIncome ? const Color(0xFF00B894) : const Color(0xFFFF6B6B);
    final fmt = DateFormat('dd MMM yyyy', context.locale.toString());

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('delete'.tr()),
            content: Text('confirm_delete'.tr()),
            actions: [
              TextButton(onPressed: () => ctx.pop(false), child: Text('cancel'.tr())),
              FilledButton(onPressed: () => ctx.pop(true), child: Text('delete'.tr())),
            ],
          ),
        );
      },
      onDismissed: (_) => ref.read(transactionRepositoryProvider).delete(tx.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          onTap: () => context.push('/transactions/add', extra: tx.id),
          leading: CircleAvatar(
            backgroundColor: Color(cat.color).withOpacity(0.2),
            child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(
            tx.note?.isNotEmpty == true ? tx.note! : cat.name.tr(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(fmt.format(tx.date), style: const TextStyle(fontSize: 12)),
          trailing: Text(
            '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
