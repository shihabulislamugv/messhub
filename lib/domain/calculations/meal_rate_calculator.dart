enum ExpenseCategory {
  bazar,
  food,
  cleaning,
  repair,
  transport,
  other,
}

class MealRateCalculator {
  /// Calculates Meal Rate:
  /// Total Food & Bazar Expense / Total Meals
  ///
  /// CRITICAL RULE:
  /// Only categories 'bazar' and 'food' count toward food expenses.
  /// Rent, utilities, bills, cleaning, repair, and transport MUST NOT affect the meal rate!
  static double calculateMealRate({
    required double totalFoodAndBazarExpense,
    required double totalMeals,
  }) {
    if (totalMeals <= 0 || totalFoodAndBazarExpense <= 0) {
      return 0.0;
    }
    return totalFoodAndBazarExpense / totalMeals;
  }

  /// Calculates total food and bazar expense from a list of categorized expense amounts.
  static double filterFoodExpenses(List<MapEntry<ExpenseCategory, double>> expenses) {
    double total = 0.0;
    for (final entry in expenses) {
      if (entry.key == ExpenseCategory.bazar || entry.key == ExpenseCategory.food) {
        total += entry.value;
      }
    }
    return total;
  }
}
