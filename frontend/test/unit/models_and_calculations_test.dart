import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/core/utils/currency_formatter.dart';
import 'package:personal_finance_tracker/shared/models/category_model.dart';
import 'package:personal_finance_tracker/shared/models/dashboard_summary_model.dart';
import 'package:personal_finance_tracker/shared/models/transaction_model.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats INR currency with Indian grouping', () {
      final formatted = CurrencyFormatter.format(150000.50, currency: 'INR');
      expect(formatted, contains('1,50,000.50'));
      expect(formatted, contains('₹'));
    });

    test('formats USD currency with standard grouping', () {
      final formatted = CurrencyFormatter.format(150000.50, currency: 'USD');
      expect(formatted, contains('150,000.50'));
      expect(formatted, contains('\$'));
    });

    test('formats compact amounts correctly', () {
      expect(CurrencyFormatter.formatCompact(15000000, currency: 'INR'), '₹1.50 Cr');
      expect(CurrencyFormatter.formatCompact(250000, currency: 'INR'), '₹2.50 L');
      expect(CurrencyFormatter.formatCompact(4500, currency: 'INR'), '₹4.5k');
      expect(CurrencyFormatter.formatCompact(750, currency: 'INR'), '₹750');
    });
  });

  group('Model Serialization Tests', () {
    test('CategoryModel deserializes correctly and parses color & icons', () {
      final json = {
        '_id': 'cat123',
        'name': 'Groceries',
        'type': 'expense',
        'icon': 'restaurant',
        'color': '#EF4444',
        'isDefault': true,
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.id, 'cat123');
      expect(cat.name, 'Groceries');
      expect(cat.type, 'expense');
      expect(cat.isDefault, true);
      expect(cat.parsedColor.toARGB32(), 0xFFEF4444);
    });

    test('TransactionModel deserializes correctly with nested category', () {
      final json = {
        '_id': 'tx999',
        'userId': 'usr123',
        'type': 'income',
        'amount': 85000.0,
        'categoryId': {
          '_id': 'catSalary',
          'name': 'Salary',
          'type': 'income',
          'icon': 'work',
          'color': '#10B981',
          'isDefault': true,
        },
        'date': '2026-10-20T10:00:00.000Z',
        'paymentMethod': 'Bank Transfer',
        'description': 'Monthly Paycheck',
        'notes': 'Direct deposit',
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.id, 'tx999');
      expect(tx.isIncome, true);
      expect(tx.isExpense, false);
      expect(tx.amount, 85000.0);
      expect(tx.description, 'Monthly Paycheck');
      expect(tx.category?.name, 'Salary');
    });

    test('DashboardSummaryModel calculates and deserializes correctly', () {
      final json = {
        'totals': {
          'totalIncome': 100000.0,
          'totalExpense': 40000.0,
          'netBalance': 60000.0,
          'savingsRate': 60.0,
        },
        'today': {'income': 5000.0, 'expense': 1200.0},
        'currentMonth': {
          'year': 2026,
          'month': 10,
          'income': 85000.0,
          'expense': 30000.0,
          'net': 55000.0,
        },
        'expenseComparison': {
          'trend': 'decreasing',
          'changePercentage': 12.5,
          'isIncrease': false,
          'previousMonthExpense': 34200.0,
        },
        'recentTransactions': [],
      };

      final summary = DashboardSummaryModel.fromJson(json);
      expect(summary.totals.totalIncome, 100000.0);
      expect(summary.totals.netBalance, 60000.0);
      expect(summary.totals.savingsRate, 60.0);
      expect(summary.expenseComparison.isIncrease, false);
      expect(summary.expenseComparison.trend, 'decreasing');
    });
  });
}
