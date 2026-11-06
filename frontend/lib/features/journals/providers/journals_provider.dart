import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/journal.dart';

final journalsListProvider = FutureProvider.autoDispose<List<Journal>>((ref) async {
  return ref.watch(journalsRepositoryProvider).list();
});
