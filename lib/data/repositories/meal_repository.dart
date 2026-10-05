import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';
import '../models/meal.dart';
import '../services/mock_seed_service.dart';

class MealRepository {
  static const String _keyMeals = 'messhub_cached_meals';
  final SharedPreferences _prefs;

  MealRepository(this._prefs);

  List<MealEntry> _meals = [];
  List<MealEntry> get meals => _meals;

  Future<void> initMeals(String messId, String cycleId) async {
    final cached = _prefs.getString('${_keyMeals}_$cycleId');
    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        _meals = list.map((m) => MealEntry.fromJson(m)).toList();
      } catch (_) {}
    }

    final isDemoMess = messId == MockSeedService.sampleMess.id;
    if (_meals.isEmpty && isDemoMess) {
      _meals = MockSeedService.getInitialMeals();
      await _saveMealsToCache(cycleId);
    }

    if (SupabaseConfig.isConfigured) {
      await _fetchFromSupabase(messId, cycleId);
    }
  }

  Future<void> _fetchFromSupabase(String messId, String cycleId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final res = await client
          .from('meals')
          .select('*, profiles(name)')
          .eq('mess_id', messId)
          .eq('cycle_id', cycleId)
          .order('meal_date', ascending: false);

      if (res.isNotEmpty) {
        _meals = res.map((m) => MealEntry.fromJson(m)).toList();
        await _saveMealsToCache(cycleId);
      }
    } catch (_) {}
  }

  Future<MealEntry> recordMeal({
    required String messId,
    required String cycleId,
    required String memberId,
    required String memberName,
    required DateTime mealDate,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    final dateOnly = DateTime(mealDate.year, mealDate.month, mealDate.day);
    final existingIndex = _meals.indexWhere(
      (m) => m.memberId == memberId &&
             m.mealDate.year == dateOnly.year &&
             m.mealDate.month == dateOnly.month &&
             m.mealDate.day == dateOnly.day,
    );

    final entry = MealEntry(
      id: existingIndex != -1 ? _meals[existingIndex].id : 'meal_${DateTime.now().millisecondsSinceEpoch}_$memberId',
      messId: messId,
      cycleId: cycleId,
      memberId: memberId,
      memberName: memberName,
      mealDate: dateOnly,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      createdAt: DateTime.now(),
    );

    if (existingIndex != -1) {
      _meals[existingIndex] = entry;
    } else {
      _meals.insert(0, entry);
    }

    await _saveMealsToCache(cycleId);

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('meals').upsert(entry.toJson());
        } catch (_) {}
      }
    }

    return entry;
  }

  Map<String, double> getMemberMealTotals(List<String> memberIds, {bool isDemo = false}) {
    final totals = <String, double>{};
    for (final id in memberIds) {
      totals[id] = 0.0;
    }

    // Accumulate actual recorded meals (starts cleanly at 0.0)
    for (final m in _meals) {
      totals[m.memberId] = (totals[m.memberId] ?? 0.0) + m.dailyTotal;
    }

    // Only apply sample baseline if explicitly operating in sample demo mess
    if (isDemo) {
      final defaults = MockSeedService.getMonthlyMemberMealTotals();
      for (final id in memberIds) {
        if ((totals[id] ?? 0) < (defaults[id] ?? 0)) {
          totals[id] = defaults[id] ?? (totals[id] ?? 0);
        }
      }
    }

    return totals;
  }

  double getTotalMessMeals(List<String> memberIds, {bool isDemo = false}) {
    final totals = getMemberMealTotals(memberIds, isDemo: isDemo);
    double sum = 0.0;
    for (final count in totals.values) {
      sum += count;
    }
    return sum;
  }

  void clearMeals() {
    _meals = [];
  }

  Future<void> clearMealsCache(String cycleId) async {
    _meals = [];
    await _prefs.remove('${_keyMeals}_$cycleId');
  }

  Future<void> _saveMealsToCache(String cycleId) async {
    await _prefs.setString(
      '${_keyMeals}_$cycleId',
      jsonEncode(_meals.map((m) => m.toJson()).toList()),
    );
  }
}
