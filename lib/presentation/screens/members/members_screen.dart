import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/status_badge.dart';

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final mess = messProvider.currentMess;
    final members = messProvider.members;
    final financials = messProvider.financialResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('mess_members')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Invite Code Banner
          if (mess != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('invite_code'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18, color: AppColors.primaryDark),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mess.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('code_copied'))),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mess.inviteCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share this 6-digit code with roommates to join ${mess.name}.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          Text(
            '${context.tr("mess_members")} (${members.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          ...members.map((member) {
            final summary = financials?.memberSummaries[member.userId];
            final meals = summary?.mealsCount ?? 0.0;
            final paid = summary?.totalPaid ?? 0.0;
            final share = summary?.totalShare ?? 0.0;
            final balance = summary?.netBalance ?? 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          member.userName?.isNotEmpty == true ? member.userName![0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member.userName ?? 'Member',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: member.isAdmin ? context.tr('admin') : context.tr('member'),
                                  type: member.isAdmin ? BadgeType.admin : BadgeType.member,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              member.userEmail ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 12),

                  // Member KPIs: Meals, Paid, Share, Balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMemberMetric('Meals', meals.toStringAsFixed(0)),
                      _buildMemberMetric('Paid', CurrencyFormatter.format(paid)),
                      _buildMemberMetric('Share', CurrencyFormatter.format(share)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Balance', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          const SizedBox(height: 2),
                          Text(
                            balance >= 0 ? '+${CurrencyFormatter.format(balance)}' : CurrencyFormatter.format(balance),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: balance > 0.01
                                  ? AppColors.positive
                                  : balance < -0.01
                                      ? AppColors.negative
                                      : AppColors.neutral,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMemberMetric(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
