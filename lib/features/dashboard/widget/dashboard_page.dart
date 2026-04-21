import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasap/core/db/db.dart';
import 'package:hasap/features/transactions/data/transaction_repository.dart';

final _periodProvider = StateProvider<PeriodFilter>((ref) => PeriodFilter.month);

final _summaryProvider = StreamProvider.family<_Summary, PeriodFilter>((ref, period) {
  return ref.watch(transactionRepositoryProvider).watchAll(period).map((txs) {
    double income = 0, expense = 0;
    final Map<String, _CatSlice> byCategory = {};
    for (final tx in txs) {
      if (tx.transaction.type == TransactionType.income) {
        income += tx.transaction.amount;
      } else {
        expense += tx.transaction.amount;
        final key = tx.category.id.toString();
        byCategory[key] = _CatSlice(
          icon: tx.category.icon,
          color: tx.category.color,
          amount: (byCategory[key]?.amount ?? 0) + tx.transaction.amount,
        );
      }
    }
    return _Summary(income: income, expense: expense, byCategory: byCategory);
  });
});

class _CatSlice {
  _CatSlice({required this.icon, required this.color, required this.amount});
  final String icon;
  final int color;
  final double amount;
}

class _Summary {
  const _Summary({required this.income, required this.expense, required this.byCategory});
  final double income;
  final double expense;
  final Map<String, _CatSlice> byCategory;
  double get balance => income - expense;
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final summary = ref.watch(_summaryProvider(period));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        title: Text('app_name'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => context.push('/transactions/add'),
              icon: const Icon(Icons.add, size: 18),
              label: Text('add_transaction'.tr()),
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_summaryProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _PeriodChips(selected: period, onChanged: (p) => ref.read(_periodProvider.notifier).state = p),
            const SizedBox(height: 16),
            summary.when(
              data: (s) => Column(
                children: [
                  _BalanceCard(summary: s),
                  const SizedBox(height: 12),
                  _StatsRow(summary: s),
                  if (s.byCategory.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SpendingChart(slices: s.byCategory),
                  ],
                ],
              ),
              loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChips extends StatelessWidget {
  const _PeriodChips({required this.selected, required this.onChanged});
  final PeriodFilter selected;
  final ValueChanged<PeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (PeriodFilter.today, 'today'.tr()),
      (PeriodFilter.week, 'this_week'.tr()),
      (PeriodFilter.month, 'this_month'.tr()),
    ];
    return Row(
      children: items.map((item) {
        final isSelected = selected == item.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(item.$2),
            selected: isSelected,
            onSelected: (_) => onChanged(item.$1),
            showCheckmark: false,
          ),
        );
      }).toList(),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final _Summary summary;

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.balance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF6C5CE7), const Color(0xFF9B59B6)]
              : [const Color(0xFFE74C3C), const Color(0xFFC0392B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? const Color(0xFF6C5CE7) : const Color(0xFFE74C3C)).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('balance'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}${summary.balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});
  final _Summary summary;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _StatCard(label: 'total_income'.tr(), amount: summary.income, icon: Icons.south_west_rounded, color: const Color(0xFF00B894))),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(label: 'total_expense'.tr(), amount: summary.expense, icon: Icons.north_east_rounded, color: const Color(0xFFE17055))),
    ],
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.amount, required this.icon, required this.color});
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 10),
          Text(amount.toStringAsFixed(2), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({required this.slices});
  final Map<String, _CatSlice> slices;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = slices.values.fold(0.0, (a, b) => a + b.amount);
    final entries = slices.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('expense'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    sections: entries.map((e) => PieChartSectionData(
                      value: e.amount,
                      color: Color(e.color),
                      title: '',
                      radius: 55,
                    )).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.take(5).map((e) {
                    final pct = (e.amount / total * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(e.color), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(e.icon, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(child: Text('$pct%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
