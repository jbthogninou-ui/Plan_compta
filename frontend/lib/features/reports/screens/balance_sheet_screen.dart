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

class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceSheetProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Bilan', subtitle: 'Actif, passif et capitaux propres'),
          const SizedBox(height: 20),
          Expanded(
            child: balanceAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(balanceSheetProvider)),
              data: (balance) {
                return SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;
                      final actif = _BalanceColumn(
                        title: 'ACTIF',
                        lines: balance.assets,
                        total: balance.totalAssets,
                        color: AppColors.debit,
                      );
                      final passif = _BalanceColumn(
                        title: 'PASSIF & CAPITAUX PROPRES',
                        lines: [
                          ...balance.liabilities,
                          ...balance.equity,
                          FinancialLine(
                            code: '',
                            name: 'Résultat net de la période',
                            amount: balance.netResultOfPeriod,
                          ),
                        ],
                        total: balance.totalLiabilitiesAndEquity,
                        color: AppColors.credit,
                      );

                      final content = wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: actif),
                                const SizedBox(width: 16),
                                Expanded(child: passif),
                              ],
                            )
                          : Column(children: [actif, const SizedBox(height: 16), passif]);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content,
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: balance.isBalanced ? AppColors.successSoft : AppColors.dangerSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  balance.isBalanced ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle,
                                  size: 17,
                                  color: balance.isBalanced ? AppColors.success : AppColors.danger,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  balance.isBalanced ? 'Bilan équilibré' : 'Bilan déséquilibré',
                                  style: TextStyle(
                                    color: balance.isBalanced ? AppColors.success : AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({required this.title, required this.lines, required this.total, required this.color});

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
                        child: Text(
                          l.code.isEmpty ? l.name : '${l.code} — ${l.name}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
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
