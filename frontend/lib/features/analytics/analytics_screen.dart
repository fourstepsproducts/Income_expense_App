import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_view.dart';
import '../../shared/models/analytics_models.dart';
import '../../shared/models/transaction_model.dart';
import '../../shared/providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'year'
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  String? _errorMessage;

  List<IncomeVsExpenseItem> _incomeVsExpenseData = [];
  ExpenseCategoryBreakdown? _categoryBreakdown;
  List<CashFlowItem> _cashFlowData = [];
  List<DailySpendingItem> _dailySpendingData = [];
  MonthlyComparisonData? _monthlyComparison;
  List<TransactionModel> _topExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = ref.read(analyticsServiceProvider);

      final startDate = _customDateRange?.start;
      final endDate = _customDateRange?.end;

      final results = await Future.wait([
        analytics.getIncomeVsExpense(
          period: _selectedPeriod,
          startDate: startDate,
          endDate: endDate,
        ),
        analytics.getExpenseCategoryBreakdown(startDate: startDate, endDate: endDate),
        analytics.getCashFlow(startDate: startDate, endDate: endDate),
        analytics.getDailySpending(startDate: startDate, endDate: endDate),
        analytics.getMonthlyComparison(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ),
        analytics.getTopExpenses(limit: 5, startDate: startDate, endDate: endDate),
      ]);

      setState(() {
        _incomeVsExpenseData = results[0] as List<IncomeVsExpenseItem>;
        _categoryBreakdown = results[1] as ExpenseCategoryBreakdown;
        _cashFlowData = results[2] as List<CashFlowItem>;
        _dailySpendingData = results[3] as List<DailySpendingItem>;
        _monthlyComparison = results[4] as MonthlyComparisonData;
        _topExpenses = results[5] as List<TransactionModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _buildPeriodTab('Daily', 'day'),
                        _buildPeriodTab('Weekly', 'week'),
                        _buildPeriodTab('Monthly', 'month'),
                        _buildPeriodTab('Yearly', 'year'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: _customDateRange != null
                        ? AppColors.vibrantBlue.withOpacity(0.2)
                        : AppColors.surfaceElevated,
                  ),
                  icon: Icon(
                    Icons.date_range_rounded,
                    color: _customDateRange != null ? AppColors.accentCyan : AppColors.textSecondary,
                    size: 20,
                  ),
                  tooltip: 'Custom Date Range',
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDateRange: _customDateRange,
                    );
                    if (picked != null) {
                      setState(() => _customDateRange = picked);
                      _loadAnalytics();
                    } else if (_customDateRange != null) {
                      setState(() => _customDateRange = null);
                      _loadAnalytics();
                    }
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.vibrantBlue))
                : _errorMessage != null
                    ? ErrorView(message: _errorMessage!, onRetry: _loadAnalytics)
                    : RefreshIndicator(
                        color: AppColors.vibrantBlue,
                        backgroundColor: AppColors.surface,
                        onRefresh: _loadAnalytics,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                          children: [
                            // 1. Income vs Expense Bar Chart
                            _buildIncomeVsExpenseChart(currency),
                            const SizedBox(height: 16),

                            // 2. Expense Breakdown Doughnut
                            _buildCategoryBreakdown(currency),
                            const SizedBox(height: 16),

                            // 3. Cash Flow Line Chart
                            _buildCashFlowChart(currency),
                            const SizedBox(height: 16),

                            // 4. Daily Spending Bar Chart
                            _buildDailySpendingChart(currency),
                            const SizedBox(height: 16),

                            // 5. Monthly Comparison Card
                            if (_monthlyComparison != null) ...[
                              _buildMonthlyComparisonCard(currency),
                              const SizedBox(height: 16),
                            ],

                            // 6. Top Expenses
                            _buildTopExpensesCard(currency),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != value) {
            setState(() => _selectedPeriod = value);
            _loadAnalytics();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.vibrantBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpenseChart(String currency) {
    if (_incomeVsExpenseData.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No income vs expense data found', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    double maxY = 1000;
    for (final item in _incomeVsExpenseData) {
      if (item.income > maxY) maxY = item.income;
      if (item.expense > maxY) maxY = item.expense;
    }
    maxY = maxY * 1.15;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Income vs Expense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  _legendDot(AppColors.incomeGreen, 'Income'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.expenseRed, 'Expense'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency: currency),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _incomeVsExpenseData.length) return const SizedBox.shrink();
                        final p = _incomeVsExpenseData[idx].period;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            p.length > 5 ? p.substring(p.length - 5) : p,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _incomeVsExpenseData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.income,
                        color: AppColors.incomeGreen,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: entry.value.expense,
                        color: AppColors.expenseRed,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(String currency) {
    final breakdown = _categoryBreakdown;
    final items = breakdown?.breakdown ?? [];

    if (items.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No expense categories found', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Text(
                'Total: ${CurrencyFormatter.formatCompact(breakdown?.totalExpense ?? 0, currency: currency)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentCyan),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: items.map((cat) {
                      return PieChartSectionData(
                        color: cat.parsedColor,
                        value: cat.totalAmount,
                        title: '',
                        radius: 18,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: items.take(5).map((cat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: cat.parsedColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat.name,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${cat.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(String currency) {
    if (_cashFlowData.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cumulative Cash Flow',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.8),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency: currency),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (_cashFlowData.length / 4).clamp(1.0, 10.0),
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _cashFlowData.length) return const SizedBox.shrink();
                        final d = _cashFlowData[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            d.length > 5 ? d.substring(5) : d,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _cashFlowData.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.cumulativeBalance);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.accentCyan,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentCyan.withOpacity(0.2),
                          AppColors.accentCyan.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpendingChart(String currency) {
    if (_dailySpendingData.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxY = 100;
    for (final item in _dailySpendingData) {
      if (item.totalAmount > maxY) maxY = item.totalAmount;
    }
    maxY = maxY * 1.15;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Spending Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency: currency),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= _dailySpendingData.length) return const SizedBox.shrink();
                        final d = _dailySpendingData[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            d.length >= 10 ? d.substring(8) : d,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _dailySpendingData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalAmount,
                        color: AppColors.vibrantBlue,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonCard(String currency) {
    final comp = _monthlyComparison!;
    final changes = comp.changes;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Month-over-Month Comparison',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCompColumn(
                  'Current Month',
                  comp.currentMonth.income,
                  comp.currentMonth.expense,
                  currency,
                ),
              ),
              Container(height: 48, width: 1, color: AppColors.border),
              Expanded(
                child: _buildCompColumn(
                  'Previous Month',
                  comp.previousMonth.income,
                  comp.previousMonth.expense,
                  currency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense Shift:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Row(
                children: [
                  Icon(
                    changes.expenseDifference > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 16,
                    color: changes.expenseDifference > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${changes.expenseChangePercentage.abs().toStringAsFixed(1)}% (${CurrencyFormatter.format(changes.expenseDifference.abs(), currency: currency)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: changes.expenseDifference > 0 ? AppColors.expenseRed : AppColors.incomeGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompColumn(String title, double inc, double exp, String currency) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('In: ${CurrencyFormatter.formatCompact(inc, currency: currency)}', style: const TextStyle(fontSize: 12, color: AppColors.incomeGreen, fontWeight: FontWeight.w600)),
        Text('Ex: ${CurrencyFormatter.formatCompact(exp, currency: currency)}', style: const TextStyle(fontSize: 12, color: AppColors.expenseRed, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTopExpensesCard(String currency) {
    if (_topExpenses.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Expenses in Period',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _topExpenses.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border),
            itemBuilder: (context, index) {
              final tx = _topExpenses[index];
              return Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentCyan),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                        Text('${tx.category?.name ?? 'Expense'} • ${DateFormatter.formatShort(tx.date)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(tx.amount, currency: currency),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.expenseRed),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
