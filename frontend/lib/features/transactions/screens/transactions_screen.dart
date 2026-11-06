import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/transaction.dart';
import '../providers/session_transactions_provider.dart';
import 'create_transaction_dialog.dart';

final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0);
final _dateFormat = DateFormat('dd/MM/yy');

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(sessionTransactionsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Transactions',
            subtitle: "Saisissez une opération métier — l'écriture comptable est générée par le backend",
            action: ElevatedButton.icon(
              onPressed: () => showDialog(context: context, builder: (_) => const CreateTransactionDialog()),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Nouvelle transaction'),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.infoSoft, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(LucideIcons.info, size: 15, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "L'historique complet des transactions n'est pas encore disponible côté API "
                    "(GET /transactions manquant) — cette liste ne montre que les transactions "
                    "créées durant cette session.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: transactions.isEmpty
                ? const EmptyView(
                    icon: LucideIcons.repeat,
                    title: 'Aucune transaction cette session',
                    subtitle: 'Créez une transaction pour voir le résultat du traitement comptable.',
                  )
                : ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _TransactionTile(transaction: transactions[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});
  final AppTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tone = switch (transaction.status) {
      TransactionStatus.posted => AppStatusTone.success,
      TransactionStatus.pending => AppStatusTone.warning,
      TransactionStatus.cancelled => AppStatusTone.danger,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(9)),
              child: Icon(
                transaction.type == TransactionType.expense ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                size: 17,
                color: transaction.type == TransactionType.expense ? AppColors.danger : AppColors.success,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.description,
                      style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${transaction.type.label} · ${_dateFormat.format(transaction.transactionDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${_currency.format(transaction.amount)} F', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 14),
            StatusBadge(label: transaction.status.label, tone: tone),
          ],
        ),
      ),
    );
  }
}
