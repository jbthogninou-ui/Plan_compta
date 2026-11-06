import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/reports.dart';

final trialBalanceProvider = FutureProvider.autoDispose<List<TrialBalanceLine>>((ref) async {
  return ref.watch(reportsRepositoryProvider).trialBalance();
});

final ledgerProvider = FutureProvider.autoDispose.family<List<LedgerLine>, String?>((ref, accountId) async {
  return ref.watch(reportsRepositoryProvider).ledger(accountId: accountId);
});

final balanceSheetProvider = FutureProvider.autoDispose<BalanceSheet>((ref) async {
  return ref.watch(reportsRepositoryProvider).balanceSheet();
});

final incomeStatementProvider = FutureProvider.autoDispose<IncomeStatement>((ref) async {
  return ref.watch(reportsRepositoryProvider).incomeStatement();
});
