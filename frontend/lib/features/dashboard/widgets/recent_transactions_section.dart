import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/models/transaction_model.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String currency;
  final VoidCallback onViewAll;
  final Function(TransactionModel) onTransactionTap;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.currency,
    required this.onViewAll,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'View All',
                style: TextStyle(
                  color: AppColors.vibrantBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (transactions.isEmpty)
          const AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No transactions recorded yet',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.border,
                indent: 64,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final category = tx.category;
                final isIncome = tx.isIncome;
                final catColor = category?.parsedColor ??
                    (isIncome ? AppColors.incomeGreen : AppColors.expenseRed);

                return ListTile(
                  onTap: () => onTransactionTap(tx),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category?.iconData ?? (isIncome ? Icons.work : Icons.shopping_bag),
                      color: catColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    tx.description,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${category?.name ?? (isIncome ? 'Income' : 'Expense')} • ${DateFormatter.formatRelative(tx.date)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount, currency: currency)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
