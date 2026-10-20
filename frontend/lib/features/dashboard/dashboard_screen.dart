import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../shared/models/analytics_models.dart';
import '../../shared/providers.dart';
import '../transactions/transaction_entry_screen.dart';
import 'widgets/cash_flow_line_chart_widget.dart';
import 'widgets/category_doughnut_widget.dart';
import 'widgets/monthly_bar_chart_widget.dart';
import 'widgets/recent_transactions_section.dart';
import 'widgets/summary_cards_section.dart';

// Dashboard chart providers
final dashboardBarChartProvider = FutureProvider.autoDispose<List<IncomeVsExpenseItem>>((ref) async {
  final analytics = ref.watch(analyticsServiceProvider);
  return analytics.getIncomeVsExpense(period: 'month');
});

final dashboardCategoryBreakdownProvider = FutureProvider.autoDispose<ExpenseCategoryBreakdown>((ref) async {
  final analytics = ref.watch(analyticsServiceProvider);
  return analytics.getExpenseCategoryBreakdown();
});

final dashboardCashFlowProvider = FutureProvider.autoDispose<List<CashFlowItem>>((ref) async {
  final analytics = ref.watch(analyticsServiceProvider);
  return analytics.getCashFlow();
});

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToAdd;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTransactions,
    required this.onNavigateToAdd,
  });

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSummaryProvider);
    ref.invalidate(dashboardBarChartProvider);
    ref.invalidate(dashboardCategoryBreakdownProvider);
    ref.invalidate(dashboardCashFlowProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final currency = ref.watch(currencyProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.wallet_rounded, color: AppColors.accentCyan, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.name.split(' ').first ?? 'User'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Your Financial Overview',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh Data',
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.vibrantBlue,
        backgroundColor: AppColors.surface,
        onRefresh: () => _refresh(ref),
        child: summaryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.vibrantBlue),
          ),
          error: (err, stack) => ErrorView(
            message: err.toString(),
            onRetry: () => _refresh(ref),
          ),
          data: (summary) {
            // Check for empty state
            if (summary.totals.totalIncome == 0 &&
                summary.totals.totalExpense == 0 &&
                summary.recentTransactions.isEmpty) {
              return EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No Transactions Recorded Yet',
                message: 'Start tracking your daily income and expenses to unlock real-time financial dashboards and smart charts.',
                buttonText: 'Add First Transaction',
                onAction: onNavigateToAdd,
              );
            }

            final barChartAsync = ref.watch(dashboardBarChartProvider);
            final categoryAsync = ref.watch(dashboardCategoryBreakdownProvider);
            final cashFlowAsync = ref.watch(dashboardCashFlowProvider);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Totals & Comparison
                SummaryCardsSection(
                  summary: summary,
                  currency: currency,
                ),
                const SizedBox(height: 16),

                // Income vs Expense Bar Chart
                barChartAsync.when(
                  data: (barData) => MonthlyBarChartWidget(
                    data: barData,
                    currency: currency,
                  ),
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator(color: AppColors.vibrantBlue)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Category Doughnut Breakdown
                categoryAsync.when(
                  data: (breakdown) => CategoryDoughnutWidget(
                    breakdown: breakdown,
                    currency: currency,
                  ),
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator(color: AppColors.vibrantBlue)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Cash Flow Trend Line Chart
                cashFlowAsync.when(
                  data: (cashFlow) => CashFlowLineChartWidget(
                    data: cashFlow,
                    currency: currency,
                  ),
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator(color: AppColors.vibrantBlue)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                // Recent Transactions
                RecentTransactionsSection(
                  transactions: summary.recentTransactions,
                  currency: currency,
                  onViewAll: onNavigateToTransactions,
                  onTransactionTap: (tx) async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransactionEntryScreen(transactionToEdit: tx),
                      ),
                    );
                    if (updated == true) {
                      _refresh(ref);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
