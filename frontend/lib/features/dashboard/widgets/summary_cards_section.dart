import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../shared/models/dashboard_summary_model.dart';

class SummaryCardsSection extends StatelessWidget {
  final DashboardSummaryModel summary;
  final String currency;

  const SummaryCardsSection({
    super.key,
    required this.summary,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final totals = summary.totals;
    final comparison = summary.expenseComparison;

    return Column(
      children: [
        // Net Balance Hero Card
        AppCard(
          padding: const EdgeInsets.all(20),
          border: Border.all(color: AppColors.vibrantBlue.withOpacity(0.3), width: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NET BALANCE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: totals.savingsRate >= 20
                          ? AppColors.incomeGreenBg
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: totals.savingsRate >= 20
                            ? AppColors.incomeGreen.withOpacity(0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.savings_rounded,
                          size: 14,
                          color: AppColors.accentCyan,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${totals.savingsRate.toStringAsFixed(1)}% Saved',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                CurrencyFormatter.format(totals.netBalance, currency: currency),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: totals.netBalance >= 0
                      ? AppColors.textPrimary
                      : AppColors.expenseRed,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 14),

              // Total Income & Total Expense Sub-row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.incomeGreenBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: AppColors.incomeGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Income',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(totals.totalIncome, currency: currency),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.incomeGreen,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 32, width: 1, color: AppColors.border),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.expenseRedBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: AppColors.expenseRed,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Expense',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(totals.totalExpense, currency: currency),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.expenseRed,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2x2 Grid: Today & Month Stats
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: "TODAY'S INCOME",
                amount: summary.today.income,
                currency: currency,
                icon: Icons.today_rounded,
                accentColor: AppColors.incomeGreen,
                subtitle: 'Earned today',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: "TODAY'S EXPENSE",
                amount: summary.today.expense,
                currency: currency,
                icon: Icons.payments_rounded,
                accentColor: AppColors.expenseRed,
                subtitle: 'Spent today',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'MONTH INCOME',
                amount: summary.currentMonth.income,
                currency: currency,
                icon: Icons.calendar_month_rounded,
                accentColor: AppColors.vibrantBlue,
                subtitle: 'This month',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: 'MONTH EXPENSE',
                amount: summary.currentMonth.expense,
                currency: currency,
                icon: Icons.shopping_cart_rounded,
                accentColor: AppColors.expenseRed,
                badgeText: comparison.changePercentage > 0
                    ? '${comparison.changePercentage.toStringAsFixed(1)}%'
                    : null,
                isPositiveBadge: !comparison.isIncrease, // Lower expense is positive
                subtitle: comparison.isIncrease ? 'vs last month' : 'saved vs last mo',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
