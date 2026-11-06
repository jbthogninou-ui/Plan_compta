import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/party.dart';
import '../providers/parties_provider.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(title: 'Tiers', subtitle: 'Clients et fournisseurs de votre entreprise'),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [Tab(text: 'Clients'), Tab(text: 'Fournisseurs')],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _PartyList(kind: PartyKind.customer),
                _PartyList(kind: PartyKind.supplier),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartyList extends ConsumerWidget {
  const _PartyList({required this.kind});
  final PartyKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomer = kind == PartyKind.customer;
    final partiesAsync = isCustomer ? ref.watch(customersListProvider) : ref.watch(suppliersListProvider);
    final provider = isCustomer ? customersListProvider : suppliersListProvider;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (_) => _PartyFormDialog(kind: kind),
              );
              if (created == true) ref.invalidate(provider);
            },
            icon: const Icon(LucideIcons.plus, size: 15),
            label: Text(isCustomer ? 'Nouveau client' : 'Nouveau fournisseur'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: partiesAsync.when(
            loading: () => const LoadingView(),
            error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(provider)),
            data: (parties) {
              if (parties.isEmpty) {
                return EmptyView(
                  icon: isCustomer ? LucideIcons.userPlus : LucideIcons.truck,
                  title: isCustomer ? 'Aucun client' : 'Aucun fournisseur',
                  subtitle: 'Ajoutez-en un pour pouvoir le lier à vos transactions.',
                );
              }
              return ListView.separated(
                itemCount: parties.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = parties[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                      ),
                      title: Text(p.name),
                      subtitle: Text([if (p.email != null) p.email!, if (p.phone != null) p.phone!].join(' · ')),
                      trailing: StatusBadge(
                        label: p.isActive ? 'Actif' : 'Inactif',
                        tone: p.isActive ? AppStatusTone.success : AppStatusTone.neutral,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PartyFormDialog extends ConsumerStatefulWidget {
  const _PartyFormDialog({required this.kind});
  final PartyKind kind;

  @override
  ConsumerState<_PartyFormDialog> createState() => _PartyFormDialogState();
}

class _PartyFormDialogState extends ConsumerState<_PartyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final draft = Party(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        isActive: true,
      );
      final repo = ref.read(partiesRepositoryProvider);
      if (widget.kind == PartyKind.customer) {
        await repo.createCustomer(draft);
      } else {
        await repo.createSupplier(draft);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.kind == PartyKind.customer;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(isCustomer ? 'Nouveau client' : 'Nouveau fournisseur',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail (optionnel)'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
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
