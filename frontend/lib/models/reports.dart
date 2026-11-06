double _num(dynamic v) => v == null ? 0 : double.parse(v.toString());

class TrialBalanceLine {
  const TrialBalanceLine({
    required this.accountId,
    required this.code,
    required this.name,
    required this.totalDebit,
    required this.totalCredit,
    required this.balance,
  });

  final String accountId;
  final String code;
  final String name;
  final double totalDebit;
  final double totalCredit;
  final double balance;

  factory TrialBalanceLine.fromJson(Map<String, dynamic> json) => TrialBalanceLine(
        accountId: json['account_id'] as String,
        code: json['code'] as String,
        name: json['name'] as String,
        totalDebit: _num(json['total_debit']),
        totalCredit: _num(json['total_credit']),
        balance: _num(json['balance']),
      );
}

class LedgerLine {
  const LedgerLine({
    required this.entryDate,
    required this.label,
    required this.accountId,
    required this.debit,
    required this.credit,
    this.entryNumber,
  });

  final String? entryNumber;
  final DateTime entryDate;
  final String label;
  final String accountId;
  final double debit;
  final double credit;

  factory LedgerLine.fromJson(Map<String, dynamic> json) => LedgerLine(
        entryNumber: json['entry_number'] as String?,
        entryDate: DateTime.parse(json['entry_date'] as String),
        label: json['label'] as String,
        accountId: json['account_id'] as String,
        debit: _num(json['debit']),
        credit: _num(json['credit']),
      );
}

class FinancialLine {
  const FinancialLine({required this.code, required this.name, required this.amount});

  final String code;
  final String name;
  final double amount;

  factory FinancialLine.fromJson(Map<String, dynamic> json) => FinancialLine(
        code: json['code'] as String,
        name: json['name'] as String,
        amount: _num(json['amount']),
      );
}

class BalanceSheet {
  const BalanceSheet({
    required this.assets,
    required this.totalAssets,
    required this.liabilities,
    required this.totalLiabilities,
    required this.equity,
    required this.totalEquity,
    required this.netResultOfPeriod,
    required this.totalEquityAndResult,
    required this.totalLiabilitiesAndEquity,
    required this.isBalanced,
  });

  final List<FinancialLine> assets;
  final double totalAssets;
  final List<FinancialLine> liabilities;
  final double totalLiabilities;
  final List<FinancialLine> equity;
  final double totalEquity;
  final double netResultOfPeriod;
  final double totalEquityAndResult;
  final double totalLiabilitiesAndEquity;
  final bool isBalanced;

  factory BalanceSheet.fromJson(Map<String, dynamic> json) => BalanceSheet(
        assets: (json['assets'] as List).map((e) => FinancialLine.fromJson(e)).toList(),
        totalAssets: _num(json['total_assets']),
        liabilities: (json['liabilities'] as List).map((e) => FinancialLine.fromJson(e)).toList(),
        totalLiabilities: _num(json['total_liabilities']),
        equity: (json['equity'] as List).map((e) => FinancialLine.fromJson(e)).toList(),
        totalEquity: _num(json['total_equity']),
        netResultOfPeriod: _num(json['net_result_of_period']),
        totalEquityAndResult: _num(json['total_equity_and_result']),
        totalLiabilitiesAndEquity: _num(json['total_liabilities_and_equity']),
        isBalanced: json['is_balanced'] as bool? ?? false,
      );
}

class IncomeStatement {
  const IncomeStatement({
    required this.revenue,
    required this.expense,
    required this.totalRevenue,
    required this.totalExpense,
    required this.netResult,
  });

  final List<FinancialLine> revenue;
  final List<FinancialLine> expense;
  final double totalRevenue;
  final double totalExpense;
  final double netResult;

  factory IncomeStatement.fromJson(Map<String, dynamic> json) => IncomeStatement(
        revenue: (json['revenue'] as List).map((e) => FinancialLine.fromJson(e)).toList(),
        expense: (json['expense'] as List).map((e) => FinancialLine.fromJson(e)).toList(),
        totalRevenue: _num(json['total_revenue']),
        totalExpense: _num(json['total_expense']),
        netResult: _num(json['net_result']),
      );
}
