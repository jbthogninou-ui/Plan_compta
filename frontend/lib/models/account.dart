enum AccountType { asset, liability, equity, revenue, expense;

  static AccountType fromApi(String value) => AccountType.values.firstWhere(
        (e) => e.name.toUpperCase() == value,
        orElse: () => AccountType.asset,
      );

  String get api => name.toUpperCase();

  String get label {
    switch (this) {
      case AccountType.asset:
        return 'Actif';
      case AccountType.liability:
        return 'Passif';
      case AccountType.equity:
        return 'Capitaux propres';
      case AccountType.revenue:
        return 'Produit';
      case AccountType.expense:
        return 'Charge';
    }
  }
}

enum NormalBalance { debit, credit;

  static NormalBalance fromApi(String value) => value == 'CREDIT' ? NormalBalance.credit : NormalBalance.debit;

  String get api => name.toUpperCase();

  String get label => this == NormalBalance.debit ? 'Débit' : 'Crédit';
}

class Account {
  const Account({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.normalBalance,
    required this.isActive,
    this.parentId,
  });

  final String id;
  final String code;
  final String name;
  final AccountType type;
  final NormalBalance normalBalance;
  final String? parentId;
  final bool isActive;

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        type: AccountType.fromApi(json['type'] as String),
        normalBalance: NormalBalance.fromApi(json['normal_balance'] as String),
        parentId: json['parent_id'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toCreateJson() => {
        'code': code,
        'name': name,
        'type': type.api,
        'normal_balance': normalBalance.api,
        if (parentId != null) 'parent_id': parentId,
      };
}
