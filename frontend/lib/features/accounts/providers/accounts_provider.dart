import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/account.dart';

final accountsListProvider = FutureProvider.autoDispose<List<Account>>((ref) async {
  return ref.watch(accountsRepositoryProvider).list();
});
