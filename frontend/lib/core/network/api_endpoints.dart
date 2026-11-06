/// Centralise tous les chemins d'API du backend Compta.
///
/// Le frontend n'appelle jamais une URL en dur ailleurs que dans ce fichier
/// (cf. principe "couche d'accès API centralisée").
class ApiEndpoints {
  ApiEndpoints._();

  // Défini via --dart-define=API_BASE_URL=... au build/run.
  // Par défaut : émulateur Android -> hôte de la machine.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';

  // Plan comptable
  static const String accounts = '/accounts';
  static String account(String id) => '/accounts/$id';

  // Journaux
  static const String journals = '/journals';

  // Transactions
  static const String transactions = '/transactions';

  // Tiers
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';

  // Trésorerie
  static const String cashAccounts = '/cash-accounts';

  // Justificatifs
  static const String documents = '/documents';

  // Rapports
  static const String trialBalance = '/reports/trial-balance';
  static const String ledger = '/reports/ledger';
  static const String balanceSheet = '/reports/balance-sheet';
  static const String incomeStatement = '/reports/income-statement';
}
