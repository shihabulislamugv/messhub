import 'package:flutter_test/flutter_test.dart';
import 'package:messhub/domain/calculations/bill_split_validator.dart';
import 'package:messhub/domain/calculations/meal_rate_calculator.dart';
import 'package:messhub/domain/calculations/balance_calculator.dart';

void main() {
  group('Bill Split Validation & Business Rules', () {
    const memberIds = ['shihab', 'rahim', 'karim', 'hasan'];

    test('Test 1 — Rent Custom Split: Valid (15,000 sum matches)', () {
      final custom = {
        'shihab': 4000.0,
        'rahim': 3500.0,
        'karim': 3500.0,
        'hasan': 4000.0,
      };

      final result = BillSplitValidator.calculateAndValidate(
        billType: BillType.rent,
        splitMethod: SplitMethod.custom,
        totalAmount: 15000.0,
        memberIds: memberIds,
        customAllocations: custom,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.memberAllocations['shihab'], 4000.0);
      expect(result.memberAllocations['rahim'], 3500.0);
    });

    test('Test 2 — Rent Custom Split: Invalid Sum (14,500 != 15,000) Must Reject', () {
      final custom = {
        'shihab': 4000.0,
        'rahim': 3500.0,
        'karim': 3500.0,
        'hasan': 3500.0, // sum = 14500
      };

      final result = BillSplitValidator.calculateAndValidate(
        billType: BillType.rent,
        splitMethod: SplitMethod.custom,
        totalAmount: 15000.0,
        memberIds: memberIds,
        customAllocations: custom,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('The member shares must equal the total bill'));
    });

    test('Rent Equal Split Rule: Equal split for Basha Vara MUST be rejected', () {
      final result = BillSplitValidator.calculateAndValidate(
        billType: BillType.rent,
        splitMethod: SplitMethod.equal,
        totalAmount: 15000.0,
        memberIds: memberIds,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Basha Vara (House Rent) only supports Custom Split'));
    });

    test('Test 3 — Electricity Equal Split: 2,400 across 4 members = 600 each', () {
      final result = BillSplitValidator.calculateAndValidate(
        billType: BillType.electricity,
        splitMethod: SplitMethod.equal,
        totalAmount: 2400.0,
        memberIds: memberIds,
      );

      expect(result.isValid, isTrue);
      expect(result.memberAllocations.length, 4);
      for (final id in memberIds) {
        expect(result.memberAllocations[id], 600.0);
      }
    });

    test('Test 4 — Electricity Custom Split: Valid (800 + 500 + 600 + 500 = 2,400)', () {
      final custom = {
        'shihab': 800.0,
        'rahim': 500.0,
        'karim': 600.0,
        'hasan': 500.0,
      };

      final result = BillSplitValidator.calculateAndValidate(
        billType: BillType.electricity,
        splitMethod: SplitMethod.custom,
        totalAmount: 2400.0,
        memberIds: memberIds,
        customAllocations: custom,
      );

      expect(result.isValid, isTrue);
      expect(result.memberAllocations['shihab'], 800.0);
      expect(result.memberAllocations['rahim'], 500.0);
      expect(result.memberAllocations['karim'], 600.0);
      expect(result.memberAllocations['hasan'], 500.0);
    });
  });

  group('Meal Rate Calculation & Expense Classification', () {
    test('Test 5 — Meal Rate: Food Expense = 20,000, Total Meals = 400 => Meal Rate = 50.0', () {
      final rate = MealRateCalculator.calculateMealRate(
        totalFoodAndBazarExpense: 20000.0,
        totalMeals: 400.0,
      );

      expect(rate, 50.0);
    });

    test('Test 6 — Non-food bills (Rent, Electricity) MUST NOT affect meal rate', () {
      final expenses = [
        const MapEntry(ExpenseCategory.bazar, 15000.0),
        const MapEntry(ExpenseCategory.food, 5000.0),
        const MapEntry(ExpenseCategory.cleaning, 800.0), // Non-food
        const MapEntry(ExpenseCategory.transport, 500.0), // Non-food
      ];

      final foodOnlyTotal = MealRateCalculator.filterFoodExpenses(expenses);
      expect(foodOnlyTotal, 20000.0); // 15000 + 5000, cleaning & transport excluded

      final mealRate = MealRateCalculator.calculateMealRate(
        totalFoodAndBazarExpense: foodOnlyTotal,
        totalMeals: 400.0,
      );

      // Rent and utilities are kept completely separate in monthly bills
      expect(mealRate, 50.0);
    });
  });

  group('Monthly Balances & Financial Settlement', () {
    test('Monthly financial balance reconciliation', () {
      final names = {
        'shihab': 'Shihab',
        'rahim': 'Rahim',
        'karim': 'Karim',
        'hasan': 'Hasan',
      };

      final rentShares = {
        'shihab': 4000.0,
        'rahim': 3500.0,
        'karim': 3500.0,
        'hasan': 4000.0,
      };

      final utilityShares = {
        'shihab': 600.0,
        'rahim': 600.0,
        'karim': 600.0,
        'hasan': 600.0,
      };

      final meals = {
        'shihab': 40.0, // 40 * 50 = 2000
        'rahim': 42.0, // 42 * 50 = 2100
        'karim': 38.0, // 38 * 50 = 1900
        'hasan': 40.0, // 40 * 50 = 2000
      };

      // Total food expense = 8,000, total meals = 160 => Meal Rate = 50.0
      const totalFoodExpense = 8000.0;
      const totalOtherExpenses = 0.0;

      final totalPaid = {
        'shihab': 7500.0, // Share = 4000 + 600 + 2000 = 6600. Net = +900 (Receive)
        'rahim': 6000.0, // Share = 3500 + 600 + 2100 = 6200. Net = -200 (Pay)
        'karim': 5500.0, // Share = 3500 + 600 + 1900 = 6000. Net = -500 (Pay)
        'hasan': 6400.0, // Share = 4000 + 600 + 2000 = 6600. Net = -200 (Pay)
      };

      final result = BalanceCalculator.computeMonthlyBalances(
        memberNames: names,
        bashaVaraShares: rentShares,
        utilityBillsShares: utilityShares,
        memberMeals: meals,
        totalOtherExpenses: totalOtherExpenses,
        memberTotalPaid: totalPaid,
        totalFoodAndBazarExpense: totalFoodExpense,
      );

      expect(result.mealRate, 50.0);
      final shihab = result.memberSummaries['shihab']!;
      expect(shihab.totalShare, 6600.0);
      expect(shihab.totalPaid, 7500.0);
      expect(shihab.netBalance, 900.0);
      expect(shihab.shouldReceive, isTrue);

      final rahim = result.memberSummaries['rahim']!;
      expect(rahim.totalShare, 6200.0);
      expect(rahim.totalPaid, 6000.0);
      expect(rahim.netBalance, -200.0);
      expect(rahim.needsToPay, isTrue);

      // Verify that total net balances sum to approximately 0 (zero-sum conservation)
      double sumNet = 0.0;
      for (final summary in result.memberSummaries.values) {
        sumNet += summary.netBalance;
      }
      expect(sumNet.abs() < 0.01, isTrue);

      // Verify recommendations
      expect(result.recommendations.isNotEmpty, isTrue);
      double totalRecommended = 0.0;
      for (final rec in result.recommendations) {
        totalRecommended += rec.amount;
        expect(rec.receiverId, 'shihab'); // Shihab is the sole creditor
      }
      expect(totalRecommended, 900.0); // Rahim(200) + Karim(500) + Hasan(200) = 900
    });
  });
}
