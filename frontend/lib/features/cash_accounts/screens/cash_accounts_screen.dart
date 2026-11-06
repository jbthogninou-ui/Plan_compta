import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/account.dart';
import '../../../models/cash_account.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../providers/cash_accounts_provider.dart';

class CashAccountsScreen extends ConsumerWidget {
  const CashAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashAccountsAsync = ref.watch(cashAccountsListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Trésorerie',
            subtitle: 'Comptes bancaires et caisses reliés au plan comptable',
            action: ElevatedButton.icon(
              onPressed: () async {
                final created =
                    await showDialog<bool>(context: context, builder: (_) => const _CashAccountFormDialog());
                if (created == true) ref.invalidate(cashAccountsListProvider);
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Nouveau compte'),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: cashAccountsAsync.when(
              loading: () => const LoadingView(),
              error: (e, _) =>
                  ErrorView(message: e.toString(), onRetry: () => ref.invalidate(cashAccountsListProvider)),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const EmptyView(
                    icon: LucideIcons.wallet,
                    title: 'Aucun compte de trésorerie',
                    subtitle: 'Ajoutez un compte bancaire ou une caisse.',
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 300,
                    mainAxisExtent: 118,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: accounts.length,
                  itemBuilder: (context, i) => _CashAccountCard(account: accounts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CashAccountCard extends StatelessWidget {
  const _CashAccountCard({required this.account});
  final CashAccount account;

  @override
  Widget build(BuildContext context) {
    final isBank = account.type == CashAccountType.bank;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(9)),
                  child: Icon(isBank ? LucideIcons.landmark : LucideIcons.banknote, size: 17, color: AppColors.primary),
                ),
                const Spacer(),
                StatusBadge(
                  label: account.isActive ? 'Actif' : 'Inactif',
                  tone: account.isActive ? AppStatusTone.success : AppStatusTone.neutral,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(account.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(
              account.iban ?? account.type.label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CashAccountFormDialog extends ConsumerStatefulWidget {
  const _CashAccountFormDialog();

  @override
  ConsumerState<_CashAccountFormDialog> createState() => _CashAccountFormDialogState();
}

class _CashAccountFormDialogState extends ConsumerState<_CashAccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ibanController = TextEditingController();
  CashAccountType _type = CashAccountType.bank;
  String? _accountId;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_accountId == null) {
      setState(() => _error = 'Sélectionnez le compte comptable associé.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final draft = CashAccount(
        id: '',
        accountId: _accountId!,
        name: _nameController.text.trim(),
        type: _type,
        iban: _ibanController.text.trim().isEmpty ? null : _ibanController.text.trim(),
        isActive: true,
      );
      await ref.read(cashAccountsRepositoryProvider).create(draft);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Nouveau compte de trésorerie', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom (ex : Compte principal BOA)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<CashAccountType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: [
                    for (final t in CashAccountType.values) DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ibanController,
                  decoration: const InputDecoration(labelText: 'IBAN / numéro de compte (optionnel)'),
                ),
                const SizedBox(height: 14),
                accountsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Impossible de charger le plan comptable : $e'),
                  data: (accounts) {
                    final relevant = accounts
                        .where((a) => a.type == AccountType.asset)
                        .toList()
                      ..sort((a, b) => a.code.compareTo(b.code));
                    return DropdownButtonFormField<String>(
                      initialValue: _accountId,
                      decoration: const InputDecoration(labelText: 'Compte comptable associé'),
                      items: [
                        for (final a in relevant)
                          DropdownMenuItem(value: a.id, child: Text('${a.code} — ${a.name}')),
                      ],
                      onChanged: (v) => setState(() => _accountId = v),
                    );
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
