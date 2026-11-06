import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/cash_accounts/screens/cash_accounts_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/journals/screens/journals_screen.dart';
import '../../features/parties/screens/parties_screen.dart';
import '../../features/reports/screens/balance_sheet_screen.dart';
import '../../features/reports/screens/income_statement_screen.dart';
import '../../features/reports/screens/ledger_screen.dart';
import '../../features/reports/screens/trial_balance_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../shared/widgets/app_shell.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const accounts = '/accounting/accounts';
  static const journals = '/accounting/journals';
  static const transactions = '/accounting/transactions';
  static const cashAccounts = '/accounting/cash-accounts';
  static const parties = '/accounting/parties';
  static const trialBalance = '/reports/trial-balance';
  static const ledger = '/reports/ledger';
  static const balanceSheet = '/reports/balance-sheet';
  static const incomeStatement = '/reports/income-statement';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register;

      if (authState.status == AuthStatus.unknown) return null;

      if (!authState.isAuthenticated && !loggingIn) return AppRoutes.login;
      if (authState.isAuthenticated && loggingIn) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen()),
          GoRoute(path: AppRoutes.accounts, builder: (context, state) => const AccountsScreen()),
          GoRoute(path: AppRoutes.journals, builder: (context, state) => const JournalsScreen()),
          GoRoute(path: AppRoutes.transactions, builder: (context, state) => const TransactionsScreen()),
          GoRoute(path: AppRoutes.cashAccounts, builder: (context, state) => const CashAccountsScreen()),
          GoRoute(path: AppRoutes.parties, builder: (context, state) => const PartiesScreen()),
          GoRoute(path: AppRoutes.trialBalance, builder: (context, state) => const TrialBalanceScreen()),
          GoRoute(path: AppRoutes.ledger, builder: (context, state) => const LedgerScreen()),
          GoRoute(path: AppRoutes.balanceSheet, builder: (context, state) => const BalanceSheetScreen()),
          GoRoute(path: AppRoutes.incomeStatement, builder: (context, state) => const IncomeStatementScreen()),
        ],
      ),
    ],
  );
});

/// Relie les changements d'[AuthState] au réveil du redirect de go_router.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }

  // ignore: unused_field
  final Ref _ref;
}
