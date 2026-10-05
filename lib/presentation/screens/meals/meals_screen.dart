import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/translations.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/mess_provider.dart';
import '../../widgets/custom_button.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  DateTime _selectedDate = DateTime.now();

  // Local state for recording meals for selected date per member
  // memberId -> {breakfast: double, lunch: double, dinner: double}
  final Map<String, Map<String, double>> _dailyMeals = {};
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDailyMealsWithDate();
  }

  void _syncDailyMealsWithDate() {
    final messProvider = context.read<MessProvider>();
    for (final m in messProvider.members) {
      final existing = messProvider.meals.where(
        (entry) => entry.memberId == m.userId &&
                   entry.mealDate.year == _selectedDate.year &&
                   entry.mealDate.month == _selectedDate.month &&
                   entry.mealDate.day == _selectedDate.day,
      );

      if (existing.isNotEmpty) {
        final rec = existing.first;
        _dailyMeals[m.userId] = {
          'breakfast': rec.breakfast,
          'lunch': rec.lunch,
          'dinner': rec.dinner,
        };
      } else {
        _dailyMeals[m.userId] = {
          'breakfast': 1.0,
          'lunch': 1.0,
          'dinner': 1.0,
        };
      }
    }
  }

  void _toggleMeal(String memberId, String mealType) {
    setState(() {
      final current = _dailyMeals[memberId]?[mealType] ?? 0.0;
      _dailyMeals[memberId]?[mealType] = current > 0 ? 0.0 : 1.0;
    });
  }

  Future<void> _saveDateMeals() async {
    final messProvider = context.read<MessProvider>();
    setState(() => _isSaving = true);

    for (final member in messProvider.members) {
      final meals = _dailyMeals[member.userId] ?? {'breakfast': 0.0, 'lunch': 0.0, 'dinner': 0.0};
      await messProvider.recordMeal(
        memberId: member.userId,
        mealDate: _selectedDate,
        breakfast: meals['breakfast'] ?? 0.0,
        lunch: meals['lunch'] ?? 0.0,
        dinner: meals['dinner'] ?? 0.0,
      );
    }

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meals saved for ${DateFormatter.formatShortDate(_selectedDate)}!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messProvider = context.watch<MessProvider>();
    final financials = messProvider.financialResult;
    final members = messProvider.members;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('meals')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meal Rate KPI Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFB45309)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
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
                      context.tr('meal_rate'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Icon(Icons.calculate_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(financials?.mealRate ?? 0.0, showDecimals: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Food: ${CurrencyFormatter.format(financials?.totalFoodAndBazar ?? 0.0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Total Meals: ${financials?.totalMeals.toStringAsFixed(0) ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Date Selector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('record_daily_meals'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _syncDailyMealsWithDate();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        DateFormatter.formatShortDate(_selectedDate),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Member Daily Meal Entry Cards
          ...members.map((member) {
            final meals = _dailyMeals[member.userId] ?? {'breakfast': 0.0, 'lunch': 0.0, 'dinner': 0.0};
            final bf = (meals['breakfast'] ?? 0.0) > 0;
            final ln = (meals['lunch'] ?? 0.0) > 0;
            final dn = (meals['dinner'] ?? 0.0) > 0;
            final total = (meals['breakfast'] ?? 0.0) + (meals['lunch'] ?? 0.0) + (meals['dinner'] ?? 0.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        member.userName ?? 'Member',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Total: $total',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMealToggle(
                        label: context.tr('breakfast'),
                        isActive: bf,
                        onTap: () => _toggleMeal(member.userId, 'breakfast'),
                      ),
                      const SizedBox(width: 8),
                      _buildMealToggle(
                        label: context.tr('lunch'),
                        isActive: ln,
                        onTap: () => _toggleMeal(member.userId, 'lunch'),
                      ),
                      const SizedBox(width: 8),
                      _buildMealToggle(
                        label: context.tr('dinner'),
                        isActive: dn,
                        onTap: () => _toggleMeal(member.userId, 'dinner'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          CustomButton(
            text: 'Save Meals for Date',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _saveDateMeals,
          ),
          const SizedBox(height: 28),

          // Monthly Member Meal Summaries Table
          Text(
            'Monthly Member Meals',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: members.map((m) {
                final summary = financials?.memberSummaries[m.userId];
                final mealsCount = summary?.mealsCount ?? 0.0;
                final cost = summary?.mealCost ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.userName ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${mealsCount.toStringAsFixed(0)} meals',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            CurrencyFormatter.format(cost),
                            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                          ),
                        ],
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

  Widget _buildMealToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryContainer : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppColors.primaryLight : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isActive ? AppColors.primaryDark : AppColors.neutral,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
