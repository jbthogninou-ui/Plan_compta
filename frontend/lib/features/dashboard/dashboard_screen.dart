import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/state_views.dart';
import '../reports/providers/reports_provider.dart';

final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeStatementProvider);
    final balanceAsync = ref.watch(balanceSheetProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Dashboard',
            subtitle: "Vue d'ensemble de la situation comptable de l'entreprise",
          ),
          const SizedBox(height: 24),
          incomeAsync.when(
            loading: () => const Padding(padding: EdgeInsets.only(top: 40), child: LoadingView()),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(incomeStatementProvider),
            ),
            data: (income) => balanceAsync.when(
              loading: () => const Padding(padding: EdgeInsets.only(top: 40), child: LoadingView()),
              error: (e, _) =>
                  ErrorView(message: e.toString(), onRetry: () => ref.invalidate(balanceSheetProvider)),
              data: (balance) => _DashboardBody(income: income, balance: balance),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.income, required this.balance});

  final dynamic income;
  final dynamic balance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final cards = [
              _KpiCard(
                label: "Chiffre d'affaires",
                value: income.totalRevenue,
                icon: LucideIcons.trendingUp,
                color: AppColors.revenue,
              ),
              _KpiCard(
                label: 'Dépenses',
                value: income.totalExpense,
                icon: LucideIcons.trendingDown,
                color: AppColors.expense,
              ),
              _KpiCard(
                label: 'Résultat net',
                value: income.netResult,
                icon: LucideIcons.piggyBank,
                color: income.netResult >= 0 ? AppColors.success : AppColors.danger,
              ),
              _KpiCard(
                label: 'Total actif',
                value: balance.totalAssets,
                icon: LucideIcons.landmark,
                color: AppColors.cash,
              ),
            ];
            if (wide) {
              return Row(
                children: [
                  for (final c in cards) ...[Expanded(child: c), const SizedBox(width: 14)],
                ]..removeLast(),
              );
            }
            return Column(
              children: [for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 12), child: c)],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 760;
            final revenueChart = _RevenueExpenseCard(income: income);
            final balanceCard = _BalanceSummaryCard(balance: balance);
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: revenueChart),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: balanceCard),
                ],
              );
            }
            return Column(children: [revenueChart, const SizedBox(height: 14), balanceCard]);
          },
        ),
        const SizedBox(height: 14),
        _QuickLinksCard(),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final double value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 14),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${_currency.format(value)} F',
              style: Theme.of(context).textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueExpenseCard extends StatelessWidget {
  const _RevenueExpenseCard({required this.income});
  final dynamic income;

  @override
  Widget build(BuildContext context) {
    final maxVal = [income.totalRevenue, income.totalExpense].reduce((a, b) => a > b ? a : b) as double;
    final safeMax = maxVal <= 0 ? 1.0 : maxVal * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revenus vs Dépenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: safeMax,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final label = value == 0 ? "Chiffre d'affaires" : (value == 1 ? 'Dépenses' : '');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(
                        toY: income.totalRevenue,
                        color: AppColors.revenue,
                        width: 44,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(
                        toY: income.totalExpense,
                        color: AppColors.expense,
                        width: 44,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSummaryCard extends StatelessWidget {
  const _BalanceSummaryCard({required this.balance});
  final dynamic balance;

  @override
  Widget build(BuildContext context) {
    final ok = balance.isBalanced as bool;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Équilibre du bilan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _row(context, 'Total actif', balance.totalAssets),
            const SizedBox(height: 10),
            _row(context, 'Total passif', balance.totalLiabilities),
            const SizedBox(height: 10),
            _row(context, 'Capitaux propres + résultat', balance.totalEquityAndResult),
            const Divider(height: 26),
            Row(
              children: [
                Icon(ok ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                    size: 16, color: ok ? AppColors.success : AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  ok ? 'Bilan équilibré' : 'Bilan déséquilibré',
                  style: TextStyle(
                    color: ok ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text('${_currency.format(value)} F', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final links = [
      ('Nouvelle transaction', LucideIcons.plusCircle, AppRoutes.transactions),
      ('Plan comptable', LucideIcons.listTree, AppRoutes.accounts),
      ('Balance générale', LucideIcons.scale, AppRoutes.trialBalance),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final l in links)
              OutlinedButton.icon(
                onPressed: () => context.go(l.$3),
                icon: Icon(l.$2, size: 16),
                label: Text(l.$1),
              ),
          ],
        ),
      ),
    );
  }
}
