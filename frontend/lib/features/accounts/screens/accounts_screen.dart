import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/account.dart';
import '../providers/accounts_provider.dart';
import 'account_form_dialog.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  String _query = '';
  AccountType? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Plan comptable',
            subtitle: 'Consultez, recherchez et gérez les comptes de votre entreprise',
            action: ElevatedButton.icon(
              onPressed: () async {
                final created = await showDialog<bool>(
                  context: context,
                  builder: (_) => const AccountFormDialog(),
                );
                if (created == true) ref.invalidate(accountsListProvider);
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Nouveau compte'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(LucideIcons.search, size: 18),
                    hintText: 'Rechercher un compte (code ou libellé)',
                  ),
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<AccountType?>(
                value: _typeFilter,
                hint: const Text('Type'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tous les types')),
                  for (final t in AccountType.values) DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => _typeFilter = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: accountsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(accountsListProvider)),
              data: (accounts) {
                final filtered = accounts.where((a) {
                  final matchesQuery = _query.isEmpty ||
                      a.code.toLowerCase().contains(_query) ||
                      a.name.toLowerCase().contains(_query);
                  final matchesType = _typeFilter == null || a.type == _typeFilter;
                  return matchesQuery && matchesType;
                }).toList()
                  ..sort((a, b) => a.code.compareTo(b.code));

                if (accounts.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.listTree,
                    title: 'Aucun compte configuré',
                    subtitle: "Créez votre premier compte pour démarrer le plan comptable.",
                  );
                }
                if (filtered.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.searchX,
                    title: 'Aucun résultat',
                    subtitle: 'Aucun compte ne correspond à votre recherche.',
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
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Libellé')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Sens normal')),
                            DataColumn(label: Text('Statut')),
                          ],
                          rows: [
                            for (final a in filtered)
                              DataRow(cells: [
                                DataCell(Text(a.code, style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(a.name)),
                                DataCell(_TypeChip(type: a.type)),
                                DataCell(Text(a.normalBalance.label)),
                                DataCell(
                                  StatusBadge(
                                    label: a.isActive ? 'Actif' : 'Désactivé',
                                    tone: a.isActive ? AppStatusTone.success : AppStatusTone.neutral,
                                  ),
                                ),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final AccountType type;

  @override
  Widget build(BuildContext context) {
    final tone = switch (type) {
      AccountType.asset => AppStatusTone.info,
      AccountType.liability => AppStatusTone.warning,
      AccountType.equity => AppStatusTone.neutral,
      AccountType.revenue => AppStatusTone.success,
      AccountType.expense => AppStatusTone.danger,
    };
    return StatusBadge(label: type.label, tone: tone);
  }
}
