import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/reports_provider.dart';

final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);
final _dateFormat = DateFormat('dd/MM/yy');

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String? _accountId;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);
    final ledgerAsync = ref.watch(ledgerProvider(_accountId));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(title: 'Grand livre', subtitle: 'Mouvements détaillés par compte'),
          const SizedBox(height: 20),
          accountsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Impossible de charger les comptes : $e'),
            data: (accounts) {
              final sorted = [...accounts]..sort((a, b) => a.code.compareTo(b.code));
              return DropdownButtonFormField<String?>(
                initialValue: _accountId,
                decoration: const InputDecoration(labelText: 'Filtrer par compte'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous les comptes')),
                  for (final a in sorted) DropdownMenuItem(value: a.id, child: Text('${a.code} — ${a.name}')),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ledgerAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) =>
                  ErrorView(message: e.toString(), onRetry: () => ref.invalidate(ledgerProvider(_accountId))),
              data: (lines) {
                if (lines.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.bookMarked,
                    title: 'Aucun mouvement',
                    subtitle: 'Aucune écriture ne concerne ce compte pour le moment.',
                  );
                }
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('N° écriture')),
                            DataColumn(label: Text('Libellé')),
                            DataColumn(label: Text('Débit'), numeric: true),
                            DataColumn(label: Text('Crédit'), numeric: true),
                          ],
                          rows: [
                            for (final l in lines)
                              DataRow(cells: [
                                DataCell(Text(_dateFormat.format(l.entryDate))),
                                DataCell(Text(l.entryNumber ?? '—')),
                                DataCell(Text(l.label)),
                                DataCell(Text(l.debit == 0 ? '—' : '${_currency.format(l.debit)} F')),
                                DataCell(Text(l.credit == 0 ? '—' : '${_currency.format(l.credit)} F')),
                              ]),
                          ],
                        ),
                      ),
                    ),
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
