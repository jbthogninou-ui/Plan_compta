enum CashAccountType { bank, cash;

  static CashAccountType fromApi(String value) => value == 'CASH' ? CashAccountType.cash : CashAccountType.bank;

  String get api => this == CashAccountType.cash ? 'CASH' : 'BANK';

  String get label => this == CashAccountType.cash ? 'Caisse' : 'Banque';
}

class CashAccount {
  const CashAccount({
    required this.id,
    required this.accountId,
    required this.name,
    required this.type,
    required this.isActive,
    this.iban,
  });

  final String id;
  final String accountId;
  final String name;
  final CashAccountType type;
  final String? iban;
  final bool isActive;

  factory CashAccount.fromJson(Map<String, dynamic> json) => CashAccount(
        id: json['id'] as String,
        accountId: json['account_id'] as String,
        name: json['name'] as String,
        type: CashAccountType.fromApi(json['type'] as String),
        iban: json['iban'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toCreateJson() => {
        'account_id': accountId,
        'name': name,
        'type': type.api,
        if (iban != null) 'iban': iban,
      };
}
