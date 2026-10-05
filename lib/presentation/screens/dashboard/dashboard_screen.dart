import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_badge.dart';
import '../bills/add_bill_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../meals/meals_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('good_morning');
    if (hour < 17) return context.tr('good_afternoon');
    return context.tr('good_evening');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final messProvider = context.watch<MessProvider>();
    final user = auth.currentUser;
    final financials = messProvider.financialResult;
    final activeCycle = messProvider.selectedCycle;
    final mySummary = user != null ? messProvider.getMemberSummary(user.id) : null;

    final monthLabel = activeCycle != null
        ? '${DateFormatter.getMonthName(activeCycle.month)} ${activeCycle.year}'
        : DateFormatter.formatMonthYear(DateTime.now());

    final firstName = user?.name.split(' ').first ?? 'Member';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messProvider.currentMess?.name ?? context.tr('app_name'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  messProvider.currentMess?.area ?? 'Bangladesh',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Cycle selector
          if (messProvider.cycles.isNotEmpty)
            PopupMenuButton(
              initialValue: activeCycle,
              onSelected: (cycle) => messProvider.selectCycle(cycle),
              itemBuilder: (ctx) => messProvider.cycles.map((c) {
                final label = '${DateFormatter.getMonthName(c.month)} ${c.year}';
                return PopupMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Icon(
                        c.isClosed ? Icons.lock_clock : Icons.check_circle,
                        size: 16,
                        color: c.isClosed ? AppColors.neutral : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Chip(
                  label: Text(monthLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.surfaceVariant,
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: AppColors.border),
                  avatar: const Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (user != null) await messProvider.loadMessData(user.id);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting(context)}, $firstName 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (mySummary != null)
                    StatusBadge(
                      label: mySummary.shouldReceive
                          ? '${context.tr('you_should_receive')} ${CurrencyFormatter.format(mySummary.balanceAmount)}'
                          : mySummary.needsToPay
                              ? '${context.tr('you_need_to_pay')} ${CurrencyFormatter.format(mySummary.balanceAmount)}'
                              : context.tr('settled'),
                      type: mySummary.shouldReceive
                          ? BadgeType.receive
                          : mySummary.needsToPay
                              ? BadgeType.pay
                              : BadgeType.settled,
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Hero Financial Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('total_mess_expense'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant, color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '${financials?.totalMeals.toStringAsFixed(0) ?? 0} ${context.tr('meals')}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(financials?.totalMessExpense ?? 0.0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('my_share'),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(mySummary?.totalShare ?? 0.0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 32, width: 1, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('my_paid'),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(mySummary?.totalPaid ?? 0.0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 32, width: 1, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('meal_rate'),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(financials?.mealRate ?? 0.0, showDecimals: true),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
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
              const SizedBox(height: 24),

              // Quick Actions Bar
              Text(
                context.tr('quick_actions'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionBtn(
                      context,
                      icon: Icons.add_shopping_cart_rounded,
                      label: context.tr('add_expense'),
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionBtn(
                      context,
                      icon: Icons.restaurant_rounded,
                      label: context.tr('record_meal'),
                      color: const Color(0xFFD97706),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionBtn(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: context.tr('add_bill'),
                      color: AppColors.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddBillScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Three Pillar Expense Category Cards
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: context.tr('monthly_bills'),
                      value: CurrencyFormatter.format(financials?.totalBills ?? 0.0),
                      icon: Icons.home_rounded,
                      iconColor: AppColors.secondary,
                      subtitle: '${messProvider.bills.length} bills',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MetricCard(
                      title: context.tr('bazar_food'),
                      value: CurrencyFormatter.format(financials?.totalFoodAndBazar ?? 0.0),
                      icon: Icons.shopping_basket_rounded,
                      iconColor: AppColors.primary,
                      subtitle: '${financials?.totalMeals.toStringAsFixed(0) ?? 0} meals',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MetricCard(
                title: context.tr('other_expenses'),
                value: CurrencyFormatter.format(financials?.totalOtherExpenses ?? 0.0),
                icon: Icons.miscellaneous_services_rounded,
                iconColor: AppColors.neutral,
                subtitle: 'Cleaning, repairs, maintenance & transport',
              ),
              const SizedBox(height: 24),

              // Recent Mess Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('recent_activity'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (messProvider.expenses.isEmpty && messProvider.bills.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'No activity recorded yet for $monthLabel.',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...messProvider.expenses.take(4).map((exp) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: exp.isFoodOrBazar
                                ? AppColors.primaryContainer.withValues(alpha: 0.6)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            exp.isFoodOrBazar ? Icons.shopping_bag_outlined : Icons.receipt_outlined,
                            size: 18,
                            color: exp.isFoodOrBazar ? AppColors.primary : AppColors.neutral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${exp.paidByName ?? "Member"} • ${DateFormatter.formatDayDate(exp.expenseDate)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(exp.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
