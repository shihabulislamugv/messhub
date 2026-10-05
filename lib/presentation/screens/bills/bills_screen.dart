import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/calculations/bill_split_validator.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/status_badge.dart';
import 'add_bill_screen.dart';
import 'bill_detail_sheet.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  IconData _getBillIcon(BillType type) {
    switch (type) {
      case BillType.rent:
        return Icons.home_rounded;
      case BillType.electricity:
        return Icons.bolt_rounded;
      case BillType.water:
        return Icons.water_drop_rounded;
      case BillType.housekeeper:
        return Icons.cleaning_services_rounded;
      case BillType.gas:
        return Icons.local_fire_department_rounded;
      case BillType.internet:
        return Icons.wifi_rounded;
      case BillType.other:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getBillColor(BillType type) {
    switch (type) {
      case BillType.rent:
        return const Color(0xFF7E22CE); // Purple
      case BillType.electricity:
        return const Color(0xFFD97706); // Amber
      case BillType.water:
        return const Color(0xFF0284C7); // Blue
      case BillType.housekeeper:
        return const Color(0xFF0F766E); // Teal
      case BillType.gas:
        return const Color(0xFFEA580C); // Orange
      case BillType.internet:
        return const Color(0xFF2563EB); // Indigo
      case BillType.other:
        return AppColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final bills = messProvider.bills;
    final activeCycle = messProvider.selectedCycle;
    final monthLabel = activeCycle != null
        ? '${DateFormatter.getMonthName(activeCycle.month)} ${activeCycle.year}'
        : 'Current Month';

    final totalBills = bills.fold<double>(0.0, (sum, b) => sum + b.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('bills')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBillScreen()),
            ),
          ),
        ],
      ),
      body: bills.isEmpty
          ? EmptyStateView(
              icon: Icons.receipt_long_rounded,
              title: 'No bills added yet',
              message: 'Add your first monthly bill to start tracking your mess rent and utilities.',
              buttonText: context.tr('add_bill'),
              onButtonPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBillScreen()),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Total Bills Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthLabel ${context.tr('bills')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(totalBills),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddBillScreen()),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(context.tr('add')),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Bill Cards
                ...bills.map((bill) {
                  final isCustom = bill.splitMethod == SplitMethod.custom;
                  final billColor = _getBillColor(bill.billType);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => BillDetailSheet(bill: bill),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: billColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_getBillIcon(bill.billType), size: 22, color: billColor),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bill.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${context.tr("paid_by")}: ${bill.paidByName ?? "Member"}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(bill.totalAmount),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      StatusBadge(
                                        label: isCustom ? context.tr('custom_split') : context.tr('equal_split'),
                                        type: isCustom ? BadgeType.customSplit : BadgeType.equalSplit,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (bill.splits.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Divider(color: AppColors.divider, height: 1),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: bill.splits.map((s) {
                                    return Text(
                                      '${s.memberName?.split(" ").first ?? "Member"}: ${CurrencyFormatter.format(s.amount)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
