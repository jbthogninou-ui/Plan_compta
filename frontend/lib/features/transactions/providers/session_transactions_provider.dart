import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/transaction.dart';

/// NOTE ARCHITECTURE : le backend V1 n'expose pas encore `GET /transactions`.
/// En attendant cet endpoint, on garde ici un historique de session (perdu au
/// redémarrage) des transactions créées, uniquement pour donner un retour
/// visuel immédiat à l'utilisateur. Ce n'est pas une source de vérité.
class SessionTransactionsNotifier extends StateNotifier<List<AppTransaction>> {
  SessionTransactionsNotifier() : super([]);

  void add(AppTransaction transaction) => state = [transaction, ...state];
}

final sessionTransactionsProvider =
    StateNotifierProvider<SessionTransactionsNotifier, List<AppTransaction>>(
  (ref) => SessionTransactionsNotifier(),
);
