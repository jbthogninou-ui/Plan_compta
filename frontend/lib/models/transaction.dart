enum TransactionType { expense, income, customerInvoice;

  static TransactionType fromApi(String value) {
    switch (value) {
      case 'EXPENSE':
        return TransactionType.expense;
      case 'INCOME':
        return TransactionType.income;
      case 'CUSTOMER_INVOICE':
        return TransactionType.customerInvoice;
      default:
        return TransactionType.expense;
    }
  }

  String get api {
    switch (this) {
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.income:
        return 'INCOME';
      case TransactionType.customerInvoice:
        return 'CUSTOMER_INVOICE';
    }
  }

  String get label {
    switch (this) {
      case TransactionType.expense:
        return 'Dépense';
      case TransactionType.income:
        return 'Recette';
      case TransactionType.customerInvoice:
        return 'Facture client';
    }
  }
}

enum PaymentMethod { bank, cash;

  static PaymentMethod? fromApi(String? value) {
    if (value == null) return null;
    return value == 'CASH' ? PaymentMethod.cash : PaymentMethod.bank;
  }

  String get api => this == PaymentMethod.cash ? 'CASH' : 'BANK';

  String get label => this == PaymentMethod.cash ? 'Caisse' : 'Banque';
}

enum TransactionStatus { pending, posted, cancelled;

  static TransactionStatus fromApi(String value) {
    switch (value) {
      case 'POSTED':
        return TransactionStatus.posted;
      case 'CANCELLED':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.posted:
        return 'Comptabilisée';
      case TransactionStatus.cancelled:
        return 'Annulée';
    }
  }
}

class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.type,
    required this.transactionDate,
    required this.amount,
    required this.description,
    required this.status,
    this.paymentMethod,
  });

  final String id;
  final TransactionType type;
  final DateTime transactionDate;
  final double amount;
  final String description;
  final PaymentMethod? paymentMethod;
  final TransactionStatus status;

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'] as String,
        type: TransactionType.fromApi(json['type'] as String),
        transactionDate: DateTime.parse(json['transaction_date'] as String),
        amount: double.parse(json['amount'].toString()),
        description: json['description'] as String,
        paymentMethod: PaymentMethod.fromApi(json['payment_method'] as String?),
        status: TransactionStatus.fromApi(json['status'] as String),
      );
}

class TransactionDraft {
  TransactionDraft({
    required this.type,
    required this.transactionDate,
    required this.amount,
    required this.description,
    this.paymentMethod,
    this.cashAccountId,
    this.customerId,
    this.supplierId,
  });

  final TransactionType type;
  final DateTime transactionDate;
  final double amount;
  final String description;
  final PaymentMethod? paymentMethod;
  final String? cashAccountId;
  final String? customerId;
  final String? supplierId;

  Map<String, dynamic> toJson() => {
        'type': type.api,
        'transaction_date': transactionDate.toIso8601String().split('T').first,
        'amount': amount,
        'description': description,
        if (paymentMethod != null) 'payment_method': paymentMethod!.api,
        if (cashAccountId != null) 'cash_account_id': cashAccountId,
        if (customerId != null) 'customer_id': customerId,
        if (supplierId != null) 'supplier_id': supplierId,
      };
}

class JournalEntryLine {
  const JournalEntryLine({
    required this.accountId,
    required this.label,
    required this.debit,
    required this.credit,
  });

  final String accountId;
  final String label;
  final double debit;
  final double credit;

  factory JournalEntryLine.fromJson(Map<String, dynamic> json) => JournalEntryLine(
        accountId: json['account_id'] as String,
        label: json['label'] as String,
        debit: double.parse(json['debit'].toString()),
        credit: double.parse(json['credit'].toString()),
      );
}

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.number,
    required this.entryDate,
    required this.label,
    required this.status,
    required this.lines,
  });

  final String id;
  final String? number;
  final DateTime entryDate;
  final String label;
  final String status;
  final List<JournalEntryLine> lines;

  double get totalDebit => lines.fold(0, (sum, l) => sum + l.debit);
  double get totalCredit => lines.fold(0, (sum, l) => sum + l.credit);
  bool get isBalanced => (totalDebit - totalCredit).abs() < 0.005;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        number: json['number'] as String?,
        entryDate: DateTime.parse(json['entry_date'] as String),
        label: json['label'] as String,
        status: json['status'] as String,
        lines: (json['lines'] as List<dynamic>? ?? [])
            .map((e) => JournalEntryLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
