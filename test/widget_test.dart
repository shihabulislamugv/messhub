import 'package:flutter_test/flutter_test.dart';
import 'package:messhub/domain/calculations/bill_split_validator.dart';
import 'package:messhub/domain/calculations/meal_rate_calculator.dart';

void main() {
  test('MessHub core smoke test', () {
    final rate = MealRateCalculator.calculateMealRate(
      totalFoodAndBazarExpense: 1000.0,
      totalMeals: 20.0,
    );
    expect(rate, 50.0);

    final res = BillSplitValidator.calculateAndValidate(
      billType: BillType.rent,
      splitMethod: SplitMethod.equal,
      totalAmount: 10000.0,
      memberIds: ['m1', 'm2'],
    );
    // Basha Vara must reject Equal split
    expect(res.isValid, isFalse);
  });
}
