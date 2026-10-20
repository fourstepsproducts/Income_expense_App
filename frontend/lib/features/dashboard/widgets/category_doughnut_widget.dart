import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/models/analytics_models.dart';

class CategoryDoughnutWidget extends StatefulWidget {
  final ExpenseCategoryBreakdown breakdown;
  final String currency;

  const CategoryDoughnutWidget({
    super.key,
    required this.breakdown,
    required this.currency,
  });

  @override
  State<CategoryDoughnutWidget> createState() => _CategoryDoughnutWidgetState();
}

class _CategoryDoughnutWidgetState extends State<CategoryDoughnutWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final items = widget.breakdown.breakdown;

    if (items.isEmpty) {
      return const AppCard(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No expense data to display',
              style: TextStyle(color: AppColors.textMuted),
            ),
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
                'Expense by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Total: ${CurrencyFormatter.formatCompact(widget.breakdown.totalExpense, currency: widget.currency)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Doughnut Chart
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: items.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          final isTouched = idx == _touchedIndex;
                          final radius = isTouched ? 24.0 : 18.0;

                          return PieChartSectionData(
                            color: item.parsedColor,
                            value: item.totalAmount,
                            title: '',
                            radius: radius,
                          );
                        }).toList(),
                      ),
                    ),
                    Text(
                      _touchedIndex >= 0 && _touchedIndex < items.length
                          ? '${items[_touchedIndex].percentage.toStringAsFixed(0)}%'
                          : '${items.length}\nCats',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Legend items (top 4)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.take(4).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.parsedColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
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
}
