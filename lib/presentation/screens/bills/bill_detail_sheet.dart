import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/bill.dart';
import '../../../domain/calculations/bill_split_validator.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/status_badge.dart';

class BillDetailSheet extends StatelessWidget {
  final Bill bill;

  const BillDetailSheet({super.key, required this.bill});

  @override
  Widget build(BuildContext context) {
    final messProvider = context.read<MessProvider>();
    final isCustom = bill.splitMethod == SplitMethod.custom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Split Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  bill.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(
                label: isCustom ? context.tr('custom_split') : context.tr('equal_split'),
                type: isCustom ? BadgeType.customSplit : BadgeType.equalSplit,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total amount highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('total'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(bill.totalAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr('paid_by'),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bill.paidByName ?? 'Member',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Member Shares list
          Text(
            context.tr('member_shares'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: bill.splits.map((split) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              (split.memberName?.isNotEmpty == true ? split.memberName![0] : 'M').toUpperCase(),
                              style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            split.memberName ?? 'Member',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(split.amount),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          if (bill.note != null && bill.note!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${context.tr("note")}: ${bill.note}',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          if (bill.dueDate != null) ...[
            const SizedBox(height: 6),
            Text(
              'Due Date: ${DateFormatter.formatShortDate(bill.dueDate!)}',
              style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(context.tr('cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final cycleId = messProvider.selectedCycle?.id ?? 'cycle_current';
                    await messProvider.deleteBill(bill.id, cycleId: cycleId);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(context.tr('delete')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.negativeBg,
                    foregroundColor: AppColors.negative,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
