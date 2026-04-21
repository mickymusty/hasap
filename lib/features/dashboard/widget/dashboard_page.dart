import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hasap/features/transactions/data/transaction_repository.dart';

final _periodProvider = StateProvider<PeriodFilter>((ref) => PeriodFilter.month);

final _summaryProvider = StreamProvider.family<_Summary, PeriodFilter>((ref, period) {
  return ref.watch(transactionRepositoryProvider).watchAll(period).map((txs) {
    double income = 0, expense = 0;
    final Map<String, double> byCategory = {};
    for (final tx in txs) {
      if (tx.transaction.type == TransactionType.income) {
        income += tx.transaction.amount;
      } else {
        expense += tx.transaction.amount;
        byCategory[tx.category.icon] = (byCategory[tx.category.icon] ?? 0) + tx.transaction.amount;
      }
    }
    return _Summary(income: income, expense: expense, byCategory: byCategory);
  });
});

class _Summary {
  const _Summary({required this.income, required this.expense, required this.byCategory});
  final double income;
  final double expense;
  final Map<String, double> byCategory;
  double get balance => income - expense;
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_periodProvider);
    final summary = ref.watch(_summaryProvider(period));
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/transactions/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_summaryProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PeriodSelector(selected: period, onChanged: (p) => ref.read(_periodProvider.notifier).state = p),
            const SizedBox(height: 16),
            summary.when(
              data: (s) => Column(
                children: [
                  _BalanceCard(summary: s, colorScheme: cs),
                  const SizedBox(height: 16),
                  _IncomeExpenseRow(summary: s, colorScheme: cs),
                  const SizedBox(height: 16),
                  if (s.byCategory.isNotEmpty) _SpendingChart(byCategory: s.byCategory),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});
  final PeriodFilter selected;
  final ValueChanged<PeriodFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PeriodFilter>(
      segments: [
        ButtonSegment(value: PeriodFilter.today, label: Text('today'.tr())),
        ButtonSegment(value: PeriodFilter.week, label: Text('this_week'.tr())),
        ButtonSegment(value: PeriodFilter.month, label: Text('this_month'.tr())),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary, required this.colorScheme});
  final _Summary summary;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.balance >= 0;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('balance'.tr(), style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              '${isPositive ? '+' : ''}${summary.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({required this.summary, required this.colorScheme});
  final _Summary summary;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'total_income'.tr(),
            amount: summary.income,
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF00B894),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'total_expense'.tr(),
            amount: summary.expense,
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFFF6B6B),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.amount, required this.icon, required this.color});
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ]),
            const SizedBox(height: 8),
            Text(amount.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({required this.byCategory});
  final Map<String, double> byCategory;

  @override
  Widget build(BuildContext context) {
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final colors = [
      const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFF45B7D1),
      const Color(0xFF96CEB4), const Color(0xFFFF9F43), const Color(0xFFA29BFE),
      const Color(0xFF6C5CE7), const Color(0xFF00B894),
    ];

    final entries = byCategory.entries.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('expense'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((e) {
                    final color = colors[e.key % colors.length];
                    final pct = (e.value.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      value: e.value.value,
                      title: '${e.value.key}\n$pct%',
                      color: color,
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
