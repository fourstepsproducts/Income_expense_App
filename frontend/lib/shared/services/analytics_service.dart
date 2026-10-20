import '../../core/network/api_client.dart';
import '../models/analytics_models.dart';
import '../models/dashboard_summary_model.dart';
import '../models/transaction_model.dart';

class AnalyticsService {
  final ApiClient _client;

  AnalyticsService(this._client);

  Future<DashboardSummaryModel> getDashboardSummary() async {
    final now = DateTime.now();
    final timezoneOffset = now.timeZoneOffset.inMinutes;

    final response = await _client.get('/dashboard/summary', queryParams: {
      'timezoneOffset': timezoneOffset,
    });
    return DashboardSummaryModel.fromJson(response['data']);
  }

  Future<List<IncomeVsExpenseItem>> getIncomeVsExpense({
    String period = 'month',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{'period': period};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();

    final response = await _client.get('/analytics/income-expense', queryParams: query);
    final list = response['data'] as List? ?? [];
    return list.map((item) => IncomeVsExpenseItem.fromJson(item)).toList();
  }

  Future<ExpenseCategoryBreakdown> getExpenseCategoryBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();

    final response = await _client.get('/analytics/expense-categories', queryParams: query);
    return ExpenseCategoryBreakdown.fromJson(response['data']);
  }

  Future<List<CashFlowItem>> getCashFlow({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();

    final response = await _client.get('/analytics/cash-flow', queryParams: query);
    final list = response['data'] as List? ?? [];
    return list.map((item) => CashFlowItem.fromJson(item)).toList();
  }

  Future<MonthlyComparisonData> getMonthlyComparison({int? year, int? month}) async {
    final query = <String, dynamic>{};
    if (year != null) query['year'] = year;
    if (month != null) query['month'] = month;

    final response = await _client.get('/analytics/monthly-comparison', queryParams: query);
    return MonthlyComparisonData.fromJson(response['data']);
  }

  Future<List<TransactionModel>> getTopExpenses({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{'limit': limit};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();

    final response = await _client.get('/analytics/top-expenses', queryParams: query);
    final list = response['data'] as List? ?? [];
    return list.map((item) => TransactionModel.fromJson(item)).toList();
  }

  Future<List<DailySpendingItem>> getDailySpending({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['startDate'] = startDate.toIso8601String();
    if (endDate != null) query['endDate'] = endDate.toIso8601String();

    final response = await _client.get('/analytics/daily-spending', queryParams: query);
    final list = response['data'] as List? ?? [];
    return list.map((item) => DailySpendingItem.fromJson(item)).toList();
  }
}
