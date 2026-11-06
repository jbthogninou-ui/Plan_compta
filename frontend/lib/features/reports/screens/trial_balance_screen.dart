import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../providers/reports_provider.dart';

final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);

class TrialBalanceScreen extends ConsumerWidget {
  const TrialBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linesAsync = ref.watch(trialBalanceProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Balance générale', subtitle: 'Débit, crédit et solde de chaque compte'),
          const SizedBox(height: 20),
          Expanded(
            child: linesAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(trialBalanceProvider)),
              data: (lines) {
                if (lines.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.scale,
                    title: 'Aucun mouvement',
                    subtitle: 'La balance apparaîtra dès que des écritures existeront.',
                  );
                }
                final totalDebit = lines.fold<double>(0, (s, l) => s + l.totalDebit);
                final totalCredit = lines.fold<double>(0, (s, l) => s + l.totalCredit);

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Code')),
                                  DataColumn(label: Text('Libellé')),
                                  DataColumn(label: Text('Débit'), numeric: true),
                                  DataColumn(label: Text('Crédit'), numeric: true),
                                  DataColumn(label: Text('Solde'), numeric: true),
                                ],
                                rows: [
                                  for (final l in lines)
                                    DataRow(cells: [
                                      DataCell(Text(l.code, style: const TextStyle(fontWeight: FontWeight.w700))),
                                      DataCell(Text(l.name)),
                                      DataCell(Text('${_currency.format(l.totalDebit)} F')),
                                      DataCell(Text('${_currency.format(l.totalCredit)} F')),
                                      DataCell(Text(
                                        '${_currency.format(l.balance)} F',
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      )),
                                    ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('TOTAL', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(width: 32),
                            Text('${_currency.format(totalDebit)} F', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(width: 32),
                            Text('${_currency.format(totalCredit)} F', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ],
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
