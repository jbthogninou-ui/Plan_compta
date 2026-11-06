import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/cash_account.dart';

final cashAccountsListProvider = FutureProvider.autoDispose<List<CashAccount>>((ref) async {
  return ref.watch(cashAccountsRepositoryProvider).list();
});
