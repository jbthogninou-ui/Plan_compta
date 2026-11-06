import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

class _NavItem {
  const _NavItem(this.label, this.icon, this.path);
  final String label;
  final IconData icon;
  final String path;
}

class _NavSection {
  const _NavSection(this.title, this.items);
  final String? title;
  final List<_NavItem> items;
}

const _sections = [
  _NavSection(null, [_NavItem('Dashboard', LucideIcons.layoutDashboard, AppRoutes.dashboard)]),
  _NavSection('COMPTABILITÉ', [
    _NavItem('Transactions', LucideIcons.repeat, AppRoutes.transactions),
    _NavItem('Journaux', LucideIcons.bookOpen, AppRoutes.journals),
    _NavItem('Plan comptable', LucideIcons.listTree, AppRoutes.accounts),
    _NavItem('Tiers', LucideIcons.users, AppRoutes.parties),
    _NavItem('Trésorerie', LucideIcons.wallet, AppRoutes.cashAccounts),
  ]),
  _NavSection('RAPPORTS', [
    _NavItem('Balance', LucideIcons.scale, AppRoutes.trialBalance),
    _NavItem('Grand livre', LucideIcons.bookMarked, AppRoutes.ledger),
    _NavItem('Bilan', LucideIcons.landmark, AppRoutes.balanceSheet),
    _NavItem('Compte de résultat', LucideIcons.trendingUp, AppRoutes.incomeStatement),
  ]),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final authState = ref.watch(authProvider);

    final currentTitle = _sections
        .expand((s) => s.items)
        .firstWhere((i) => i.path == location, orElse: () => _sections.first.items.first)
        .label;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _Sidebar(location: location, email: authState.email),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: currentTitle, showMenuButton: false, email: authState.email),
                  Expanded(child: Container(color: AppColors.background, child: child)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: null,
      drawer: Drawer(child: _Sidebar(location: location, email: authState.email, inDrawer: true)),
      body: Column(
        children: [
          Builder(
            builder: (context) => _TopBar(
              title: currentTitle,
              showMenuButton: true,
              email: authState.email,
              onMenuTap: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Expanded(child: Container(color: AppColors.background, child: child)),
        ],
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.location, this.email, this.inDrawer = false});

  final String location;
  final String? email;
  final bool inDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: inDrawer ? null : 248,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(LucideIcons.calculator, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Text('Compta', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final section in _sections) ...[
                    if (section.title != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                        child: Text(
                          section.title!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    for (final item in section.items)
                      _SidebarTile(item: item, selected: item.path == location),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                dense: true,
                leading: const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(LucideIcons.user, size: 15, color: AppColors.primary),
                ),
                title: Text(
                  email ?? 'Mon compte',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                  tooltip: 'Déconnexion',
                  icon: const Icon(LucideIcons.logOut, size: 17),
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({required this.item, required this.selected});

  final _NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () {
            context.go(item.path);
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.hasDrawer && scaffold.isDrawerOpen) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.showMenuButton, this.onMenuTap, this.email});

  final String title;
  final bool showMenuButton;
  final VoidCallback? onMenuTap;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(icon: const Icon(LucideIcons.menu), onPressed: onMenuTap),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (!showMenuButton && email != null)
            Text(email!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
