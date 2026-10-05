import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/status_badge.dart';
import 'record_payment_sheet.dart';

class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final financials = messProvider.financialResult;
    final activeCycle = messProvider.selectedCycle;

    final monthLabel = activeCycle != null
        ? '${DateFormatter.getMonthName(activeCycle.month)} ${activeCycle.year}'
        : 'Monthly Settlement';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('monthly_settlement')),
        actions: [
          IconButton(
            icon: const Icon(Icons.payment_rounded, color: AppColors.primary),
            tooltip: 'Record Payment',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const RecordPaymentSheet(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Settlement Summary Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthLabel Summary',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol('Total Expense', CurrencyFormatter.format(financials?.totalMessExpense ?? 0.0)),
                    _buildStatCol('Total Meals', '${financials?.totalMeals.toStringAsFixed(0) ?? 0}'),
                    _buildStatCol('Meal Rate', CurrencyFormatter.format(financials?.mealRate ?? 0.0, showDecimals: true)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Member Balances Breakdown
          Text(
            'Member Balances',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          if (financials != null)
            ...financials.memberSummaries.values.map((summary) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                summary.memberName.isNotEmpty ? summary.memberName[0].toUpperCase() : 'M',
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              summary.memberName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: summary.shouldReceive
                              ? '${context.tr("you_should_receive")} ${CurrencyFormatter.format(summary.balanceAmount)}'
                              : summary.needsToPay
                                  ? '${context.tr("you_need_to_pay")} ${CurrencyFormatter.format(summary.balanceAmount)}'
                                  : context.tr('settled'),
                          type: summary.shouldReceive
                              ? BadgeType.receive
                              : summary.needsToPay
                                  ? BadgeType.pay
                                  : BadgeType.settled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: AppColors.divider, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Share: ${CurrencyFormatter.format(summary.totalShare)}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        Text('Paid: ${CurrencyFormatter.format(summary.totalPaid)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),

          // Recommended Settlement Transactions
          Text(
            context.tr('settlement_summary'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),

          if (financials?.recommendations.isEmpty ?? true)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.positiveBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.positive.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.positive, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('no_settlements_pending'),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.positive),
                    ),
                  ),
                ],
              ),
            )
          else
            ...financials!.recommendations.map((rec) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                          children: [
                            TextSpan(text: rec.senderName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            const TextSpan(text: ' needs to pay '),
                            TextSpan(text: rec.receiverName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(rec.amount),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.negative),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),

          // Payment Records
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recorded Payments',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const RecordPaymentSheet(),
                  );
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Record Payment'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (messProvider.settlements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No payments recorded yet.',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            )
          else
            ...messProvider.settlements.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.senderName ?? "Sender"} paid ${s.receiverName ?? "Receiver"}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormatter.formatShortDate(s.paymentDate)}${s.note != null ? " • ${s.note}" : ""}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(s.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.positive),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 28),

          // Admin Monthly Cycle Close Button
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Close Monthly Cycle?'),
                  content: Text(context.tr('cycle_closed_msg')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('confirm'))),
                  ],
                ),
              );
              if (confirm == true) {
                await messProvider.closeMonthlyCycle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('cycle_closed_msg'))),
                  );
                }
              }
            },
            icon: const Icon(Icons.archive_outlined, size: 18),
            label: Text(context.tr('close_cycle')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
