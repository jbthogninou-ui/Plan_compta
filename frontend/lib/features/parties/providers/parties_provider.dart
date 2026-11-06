import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/party.dart';

final customersListProvider = FutureProvider.autoDispose<List<Party>>((ref) async {
  return ref.watch(partiesRepositoryProvider).listCustomers();
});

final suppliersListProvider = FutureProvider.autoDispose<List<Party>>((ref) async {
  return ref.watch(partiesRepositoryProvider).listSuppliers();
});
