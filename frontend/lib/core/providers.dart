import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/accounts/data/accounts_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/cash_accounts/data/cash_accounts_repository.dart';
import '../features/journals/data/journals_repository.dart';
import '../features/parties/data/parties_repository.dart';
import '../features/reports/data/reports_repository.dart';
import '../features/transactions/data/transactions_repository.dart';
import 'network/api_client.dart';
import 'network/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider), tokenStorage: ref.watch(tokenStorageProvider));
});

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(apiClient: ref.watch(apiClientProvider));
});

final journalsRepositoryProvider = Provider<JournalsRepository>((ref) {
  return JournalsRepository(apiClient: ref.watch(apiClientProvider));
});

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(apiClient: ref.watch(apiClientProvider));
});

final partiesRepositoryProvider = Provider<PartiesRepository>((ref) {
  return PartiesRepository(apiClient: ref.watch(apiClientProvider));
});

final cashAccountsRepositoryProvider = Provider<CashAccountsRepository>((ref) {
  return CashAccountsRepository(apiClient: ref.watch(apiClientProvider));
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(apiClient: ref.watch(apiClientProvider));
});
