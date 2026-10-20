import 'package:flutter/material.dart';

class IncomeVsExpenseItem {
  final String period;
  final double income;
  final double expense;
  final double net;

  IncomeVsExpenseItem({
    required this.period,
    required this.income,
    required this.expense,
    required this.net,
  });

  factory IncomeVsExpenseItem.fromJson(Map<String, dynamic> json) {
    return IncomeVsExpenseItem(
      period: json['period'] ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CategoryBreakdownItem {
  final String categoryId;
  final String name;
  final String icon;
  final String color;
  final double totalAmount;
  final int transactionCount;
  final double percentage;

  CategoryBreakdownItem({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItem(
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#3B82F6',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transactionCount'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Color get parsedColor {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }
}

class ExpenseCategoryBreakdown {
  final double totalExpense;
  final List<CategoryBreakdownItem> breakdown;

  ExpenseCategoryBreakdown({
    required this.totalExpense,
    required this.breakdown,
  });

  factory ExpenseCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryBreakdown(
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      breakdown: (json['breakdown'] as List? ?? [])
          .map((i) => CategoryBreakdownItem.fromJson(i))
          .toList(),
    );
  }
}

class CashFlowItem {
  final String date;
  final double income;
  final double expense;
  final double net;
  final double cumulativeBalance;

  CashFlowItem({
    required this.date,
    required this.income,
    required this.expense,
    required this.net,
    required this.cumulativeBalance,
  });

  factory CashFlowItem.fromJson(Map<String, dynamic> json) {
    return CashFlowItem(
      date: json['date'] ?? '',
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
      cumulativeBalance: (json['cumulativeBalance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DailySpendingItem {
  final String date;
  final double totalAmount;
  final int count;

  DailySpendingItem({
    required this.date,
    required this.totalAmount,
    required this.count,
  });

  factory DailySpendingItem.fromJson(Map<String, dynamic> json) {
    return DailySpendingItem(
      date: json['date'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
    );
  }
}

class MonthlyComparisonData {
  final ComparisonMonth currentMonth;
  final ComparisonMonth previousMonth;
  final ComparisonChanges changes;
  final List<ComparisonCategory> categoryComparison;

  MonthlyComparisonData({
    required this.currentMonth,
    required this.previousMonth,
    required this.changes,
    required this.categoryComparison,
  });

  factory MonthlyComparisonData.fromJson(Map<String, dynamic> json) {
    return MonthlyComparisonData(
      currentMonth: ComparisonMonth.fromJson(json['currentMonth'] ?? {}),
      previousMonth: ComparisonMonth.fromJson(json['previousMonth'] ?? {}),
      changes: ComparisonChanges.fromJson(json['changes'] ?? {}),
      categoryComparison: (json['categoryComparison'] as List? ?? [])
          .map((c) => ComparisonCategory.fromJson(c))
          .toList(),
    );
  }
}

class ComparisonMonth {
  final int year;
  final int month;
  final double income;
  final double expense;
  final double net;

  ComparisonMonth({
    this.year = 0,
    this.month = 0,
    this.income = 0.0,
    this.expense = 0.0,
    this.net = 0.0,
  });

  factory ComparisonMonth.fromJson(Map<String, dynamic> json) {
    return ComparisonMonth(
      year: json['year'] ?? 0,
      month: json['month'] ?? 0,
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0.0,
      net: (json['net'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ComparisonChanges {
  final double expenseDifference;
  final double expenseChangePercentage;
  final double incomeDifference;
  final double incomeChangePercentage;

  ComparisonChanges({
    this.expenseDifference = 0.0,
    this.expenseChangePercentage = 0.0,
    this.incomeDifference = 0.0,
    this.incomeChangePercentage = 0.0,
  });

  factory ComparisonChanges.fromJson(Map<String, dynamic> json) {
    return ComparisonChanges(
      expenseDifference: (json['expenseDifference'] as num?)?.toDouble() ?? 0.0,
      expenseChangePercentage: (json['expenseChangePercentage'] as num?)?.toDouble() ?? 0.0,
      incomeDifference: (json['incomeDifference'] as num?)?.toDouble() ?? 0.0,
      incomeChangePercentage: (json['incomeChangePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ComparisonCategory {
  final String categoryId;
  final String name;
  final String? color;
  final String? icon;
  final double total;
  final double previousTotal;
  final double difference;
  final double changePercentage;

  ComparisonCategory({
    required this.categoryId,
    required this.name,
    this.color,
    this.icon,
    required this.total,
    required this.previousTotal,
    required this.difference,
    required this.changePercentage,
  });

  factory ComparisonCategory.fromJson(Map<String, dynamic> json) {
    return ComparisonCategory(
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      color: json['color'],
      icon: json['icon'],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      previousTotal: (json['previousTotal'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      changePercentage: (json['changePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
