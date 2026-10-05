import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/mess_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final financials = messProvider.financialResult;
    final total = financials?.totalMessExpense ?? 0.0;
    final billsTotal = financials?.totalBills ?? 0.0;
    final foodTotal = financials?.totalFoodAndBazar ?? 0.0;
    final otherTotal = financials?.totalOtherExpenses ?? 0.0;

    final billsPct = total > 0 ? (billsTotal / total) : 0.0;
    final foodPct = total > 0 ? (foodTotal / total) : 0.0;
    final otherPct = total > 0 ? (otherTotal / total) : 0.0;

    String highestCategory = 'Housing Bills';
    if (foodTotal > billsTotal && foodTotal > otherTotal) {
      highestCategory = 'Bazar & Food';
    } else if (otherTotal > billsTotal && otherTotal > foodTotal) {
      highestCategory = 'Other Expenses';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('reports')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Highest Category Highlight
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('highest_category'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        highestCategory,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Distribution breakdown
          Text(
            context.tr('expense_distribution'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildProgressItem(
                  label: context.tr('monthly_bills'),
                  amount: billsTotal,
                  percentage: billsPct,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 16),
                _buildProgressItem(
                  label: context.tr('bazar_food'),
                  amount: foodTotal,
                  percentage: foodPct,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                _buildProgressItem(
                  label: context.tr('other_expenses'),
                  amount: otherTotal,
                  percentage: otherPct,
                  color: const Color(0xFFD97706),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Member-wise contributions
          Text(
            context.tr('member_contributions'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          if (financials != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: financials.memberSummaries.values.map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            s.memberName.isNotEmpty ? s.memberName[0].toUpperCase() : 'M',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.memberName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                'Share: ${CurrencyFormatter.format(s.totalShare)} | Paid: ${CurrencyFormatter.format(s.totalPaid)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          s.netBalance >= 0 ? '+${CurrencyFormatter.format(s.netBalance)}' : CurrencyFormatter.format(s.netBalance),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: s.netBalance > 0.01
                                ? AppColors.positive
                                : s.netBalance < -0.01
                                    ? AppColors.negative
                                    : AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              '${CurrencyFormatter.format(amount)} (${(percentage * 100).toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
