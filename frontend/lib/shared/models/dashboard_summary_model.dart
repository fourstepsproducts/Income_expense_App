import 'transaction_model.dart';

class DashboardSummaryModel {
  final DashboardTotals totals;
  final TodayStats today;
  final MonthStats currentMonth;
  final ExpenseComparison expenseComparison;
  final List<TransactionModel> recentTransactions;

  DashboardSummaryModel({
    required this.totals,
    required this.today,
    required this.currentMonth,
    required this.expenseComparison,
    required this.recentTransactions,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totals: DashboardTotals.fromJson(json['totals'] ?? {}),
      today: TodayStats.fromJson(json['today'] ?? {}),
      currentMonth: MonthStats.fromJson(json['currentMonth'] ?? {}),
      expenseComparison: ExpenseComparison.fromJson(json['expenseComparison'] ?? {}),
      recentTransactions: (json['recentTransactions'] as List? ?? [])
          .map((item) => TransactionModel.fromJson(item))
          .toList(),
    );
  }
}

class DashboardTotals {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double savingsRate;

  DashboardTotals({
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.netBalance = 0.0,
    this.savingsRate = 0.0,
  });

  factory DashboardTotals.fromJson(Map<String, dynamic> json) {
    return DashboardTotals(
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['netBalance'] as num?)?.toDouble() ?? 0.0,
      savingsRate: (json['savingsRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TodayStats {
  final double income;
  final double expense;

  TodayStats({this.income = 0.0, this.expense = 0.0});

  factory TodayStats.fromJson(Map<String, dynamic> json) {
    return TodayStats(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MonthStats {
  final int year;
  final int month;
  final double income;
  final double expense;
  final double net;

  MonthStats({
    this.year = 0,
    this.month = 0,
    this.income = 0.0,
    this.expense = 0.0,
    this.net = 0.0,
  });

  factory MonthStats.fromJson(Map<String, dynamic> json) {
    return MonthStats(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseComparison {
  final String trend; // 'increasing' | 'decreasing' | 'neutral'
  final double changePercentage;
  final bool isIncrease;
  final double previousMonthExpense;

  ExpenseComparison({
    this.trend = 'neutral',
    this.changePercentage = 0.0,
    this.isIncrease = false,
    this.previousMonthExpense = 0.0,
  });

  factory ExpenseComparison.fromJson(Map<String, dynamic> json) {
    return ExpenseComparison(
      trend: json['trend'] ?? 'neutral',
      changePercentage: (json['changePercentage'] as num?)?.toDouble() ?? 0.0,
      isIncrease: json['isIncrease'] ?? false,
      previousMonthExpense: (json['previousMonthExpense'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
