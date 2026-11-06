import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/reports.dart';
import '../providers/reports_provider.dart';

final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);

class IncomeStatementScreen extends ConsumerWidget {
  const IncomeStatementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeStatementProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Compte de résultat', subtitle: 'Produits, charges et résultat net'),
          const SizedBox(height: 20),
          Expanded(
            child: incomeAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) =>
                  ErrorView(message: e.toString(), onRetry: () => ref.invalidate(incomeStatementProvider)),
              data: (income) => SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 760;
                    final produits = _ResultColumn(
                      title: 'PRODUITS',
                      lines: income.revenue,
                      total: income.totalRevenue,
                      color: AppColors.revenue,
                    );
                    final charges = _ResultColumn(
                      title: 'CHARGES',
                      lines: income.expense,
                      total: income.totalExpense,
                      color: AppColors.expense,
                    );

                    final content = wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: produits),
                              const SizedBox(width: 16),
                              Expanded(child: charges),
                            ],
                          )
                        : Column(children: [produits, const SizedBox(height: 16), charges]);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        content,
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: income.netResult >= 0 ? AppColors.successSoft : AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    income.netResult >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                                    size: 18,
                                    color: income.netResult >= 0 ? AppColors.success : AppColors.danger,
                                  ),
                                  const SizedBox(width: 10),
                                  Text('RÉSULTAT NET',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: income.netResult >= 0 ? AppColors.success : AppColors.danger,
                                      )),
                                ],
                              ),
                              Text(
                                '${_currency.format(income.netResult)} F',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: income.netResult >= 0 ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultColumn extends StatelessWidget {
  const _ResultColumn({required this.title, required this.lines, required this.total, required this.color});

  final String title;
  final List<FinancialLine> lines;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            if (lines.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Aucune ligne', style: Theme.of(context).textTheme.bodyMedium),
              )
            else
              for (final l in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('${l.code} — ${l.name}', style: Theme.of(context).textTheme.bodyLarge),
                      ),
                      Text('${_currency.format(l.amount)} F', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('${_currency.format(total)} F', style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
