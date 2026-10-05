import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/mess.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            tooltip: 'Add Member / রুমমেট যোগ করুন',
            onPressed: () => _showAddMemberDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Member (মেম্বার যোগ)'),
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
                    'Share this 6-digit code with roommates to join ${mess.name}, or add them directly below.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${context.tr("mess_members")} (${members.length})',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => _showAddMemberDialog(context),
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text('+ Add Member', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (members.length <= 1) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'এখন শুধু আপনি ১ জন মেম্বার আছেন। বাসা ভাড়া বা অন্যান্য হিসাব ভাগ করার জন্য আপনার রুমমেটদের (যেমন: রহিম, করিম, তানভীর) যোগ করুন।',
                      style: TextStyle(fontSize: 13, color: AppColors.onSecondaryContainer, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),

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
                      if (!member.isAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.negative, size: 20),
                          tooltip: 'Remove Roommate',
                          onPressed: () => _confirmRemoveMember(context, member),
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

  void _showAddMemberDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Roommate / মেম্বার যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Roommate Name (নাম)',
                hintText: 'e.g. Rahim / তানভীর',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone / Details (ঐচ্ছিক)',
                hintText: '017XXXXXXXX',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final messProvider = context.read<MessProvider>();
              final member = await messProvider.addMember(
                name: name,
                phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
              );
              if (context.mounted && member != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name কে মেস-এ যোগ করা হয়েছে!')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, MessMember member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${member.userName ?? "Member"}?'),
        content: Text('Are you sure you want to remove ${member.userName ?? "this member"} from the mess?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () async {
              Navigator.pop(ctx);
              final messProvider = context.read<MessProvider>();
              await messProvider.removeMember(member.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${member.userName} removed from mess')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
