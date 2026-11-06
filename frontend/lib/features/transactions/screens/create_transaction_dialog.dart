import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../models/transaction.dart';
import '../../cash_accounts/providers/cash_accounts_provider.dart';
import '../../parties/providers/parties_provider.dart';
import '../providers/session_transactions_provider.dart';

class CreateTransactionDialog extends ConsumerStatefulWidget {
  const CreateTransactionDialog({super.key});

  @override
  ConsumerState<CreateTransactionDialog> createState() => _CreateTransactionDialogState();
}

class _CreateTransactionDialogState extends ConsumerState<CreateTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.income;
  DateTime _date = DateTime.now();
  PaymentMethod? _paymentMethod = PaymentMethod.bank;
  String? _cashAccountId;
  String? _customerId;
  String? _supplierId;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final draft = TransactionDraft(
        type: _type,
        transactionDate: _date,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
        cashAccountId: _cashAccountId,
        customerId: _type == TransactionType.customerInvoice ? _customerId : null,
        supplierId: _type == TransactionType.expense ? _supplierId : null,
      );
      final created = await ref.read(transactionsRepositoryProvider).create(draft);
      ref.read(sessionTransactionsProvider.notifier).add(created);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashAccountsAsync = ref.watch(cashAccountsListProvider);
    final customersAsync = ref.watch(customersListProvider);
    final suppliersAsync = ref.watch(suppliersListProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nouvelle transaction', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    "L'écriture comptable sera générée automatiquement par le backend.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<TransactionType>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: "Type d'opération"),
                    items: [
                      for (final t in TransactionType.values) DropdownMenuItem(value: t, child: Text(t.label)),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date de la transaction'),
                      child: Text('${_date.day.toString().padLeft(2, '0')}/'
                          '${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Montant'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Champ requis';
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) return 'Montant invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<PaymentMethod?>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Moyen de paiement'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Non renseigné')),
                      for (final p in PaymentMethod.values) DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (v) => setState(() => _paymentMethod = v),
                  ),
                  const SizedBox(height: 14),
                  cashAccountsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => const SizedBox.shrink(),
                    data: (accounts) => DropdownButtonFormField<String?>(
                      initialValue: _cashAccountId,
                      decoration: const InputDecoration(labelText: 'Compte de trésorerie (optionnel)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Aucun')),
                        for (final a in accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                      ],
                      onChanged: (v) => setState(() => _cashAccountId = v),
                    ),
                  ),
                  if (_type == TransactionType.customerInvoice) ...[
                    const SizedBox(height: 14),
                    customersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (customers) => DropdownButtonFormField<String?>(
                        initialValue: _customerId,
                        decoration: const InputDecoration(labelText: 'Client (optionnel)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Aucun')),
                          for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _customerId = v),
                      ),
                    ),
                  ],
                  if (_type == TransactionType.expense) ...[
                    const SizedBox(height: 14),
                    suppliersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => const SizedBox.shrink(),
                      data: (suppliers) => DropdownButtonFormField<String?>(
                        initialValue: _supplierId,
                        decoration: const InputDecoration(labelText: 'Fournisseur (optionnel)'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Aucun')),
                          for (final s in suppliers) DropdownMenuItem(value: s.id, child: Text(s.name)),
                        ],
                        onChanged: (v) => setState(() => _supplierId = v),
                      ),
                    ),
                  ],
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
                            : const Text('Créer et comptabiliser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
