enum JournalType { sales, purchases, bank, cash, misc;

  static JournalType fromApi(String value) => JournalType.values.firstWhere(
        (e) => e.name.toUpperCase() == value,
        orElse: () => JournalType.misc,
      );

  String get api => name.toUpperCase();

  String get label {
    switch (this) {
      case JournalType.sales:
        return 'Ventes';
      case JournalType.purchases:
        return 'Achats';
      case JournalType.bank:
        return 'Banque';
      case JournalType.cash:
        return 'Caisse';
      case JournalType.misc:
        return 'Opérations diverses';
    }
  }
}

class Journal {
  const Journal({required this.id, required this.code, required this.name, required this.type});

  final String id;
  final String code;
  final String name;
  final JournalType type;

  factory Journal.fromJson(Map<String, dynamic> json) => Journal(
        id: json['id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        type: JournalType.fromApi(json['type'] as String),
      );

  Map<String, dynamic> toCreateJson() => {'code': code, 'name': name, 'type': type.api};
}
