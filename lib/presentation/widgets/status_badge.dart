import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum BadgeType {
  receive,
  pay,
  settled,
  customSplit,
  equalSplit,
  admin,
  member,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case BadgeType.receive:
        bg = AppColors.positiveBg;
        fg = AppColors.positive;
        border = AppColors.positive.withValues(alpha: 0.3);
        break;
      case BadgeType.pay:
        bg = AppColors.negativeBg;
        fg = AppColors.negative;
        border = AppColors.negative.withValues(alpha: 0.3);
        break;
      case BadgeType.settled:
        bg = AppColors.neutralBg;
        fg = AppColors.neutral;
        border = AppColors.border;
        break;
      case BadgeType.customSplit:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        border = const Color(0xFFD8B4FE);
        break;
      case BadgeType.equalSplit:
        bg = AppColors.secondaryContainer;
        fg = AppColors.secondary;
        border = const Color(0xFFBAE6FD);
        break;
      case BadgeType.admin:
        bg = AppColors.primaryContainer;
        fg = AppColors.primaryDark;
        border = AppColors.primaryLight.withValues(alpha: 0.4);
        break;
      case BadgeType.member:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        border = AppColors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
