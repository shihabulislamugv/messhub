class MemberFinancialSummary {
  final String memberId;
  final String memberName;
  final double bashaVaraShare;
  final double utilityBillsShare;
  final double mealCost;
  final double otherExpensesShare;
  final double totalShare;
  final double totalPaid;
  final double netBalance; // positive = to receive, negative = to pay
  final double mealsCount;

  const MemberFinancialSummary({
    required this.memberId,
    required this.memberName,
    required this.bashaVaraShare,
    required this.utilityBillsShare,
    required this.mealCost,
    required this.otherExpensesShare,
    required this.totalShare,
    required this.totalPaid,
    required this.netBalance,
    required this.mealsCount,
  });

  bool get isSettled => netBalance.abs() <= 0.01;
  bool get shouldReceive => netBalance > 0.01;
  bool get needsToPay => netBalance < -0.01;

  double get balanceAmount => netBalance.abs();
}

class SettlementRecommendation {
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final double amount;

  const SettlementRecommendation({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
  });
}

class MonthlyFinancialResult {
  final double totalMessExpense;
  final double totalBills;
  final double totalFoodAndBazar;
  final double totalOtherExpenses;
  final double totalMeals;
  final double mealRate;
  final Map<String, MemberFinancialSummary> memberSummaries;
  final List<SettlementRecommendation> recommendations;

  const MonthlyFinancialResult({
    required this.totalMessExpense,
    required this.totalBills,
    required this.totalFoodAndBazar,
    required this.totalOtherExpenses,
    required this.totalMeals,
    required this.mealRate,
    required this.memberSummaries,
    required this.recommendations,
  });
}

class BalanceCalculator {
  /// Computes the complete monthly financial report and member-wise balances.
  static MonthlyFinancialResult computeMonthlyBalances({
    required Map<String, String> memberNames, // id -> name
    required Map<String, double> bashaVaraShares, // memberId -> rent share
    required Map<String, double> utilityBillsShares, // memberId -> utility share
    required Map<String, double> memberMeals, // memberId -> meals count
    required double totalOtherExpenses,
    required Map<String, double> memberTotalPaid, // memberId -> total paid by member
    required double totalFoodAndBazarExpense,
  }) {
    final memberIds = memberNames.keys.toList();
    final memberCount = memberIds.isNotEmpty ? memberIds.length : 1;

    // 1. Calculate total meals and meal rate
    double totalMeals = 0.0;
    for (final meals in memberMeals.values) {
      totalMeals += meals;
    }

    final mealRate = totalMeals > 0 ? (totalFoodAndBazarExpense / totalMeals) : 0.0;

    // 2. Other shared expense per member
    final otherSharePerMember = totalOtherExpenses / memberCount;

    // 3. Compute totals and member summaries
    double totalBills = 0.0;
    for (final rent in bashaVaraShares.values) {
      totalBills += rent;
    }
    for (final util in utilityBillsShares.values) {
      totalBills += util;
    }

    final totalMessExpense = totalBills + totalFoodAndBazarExpense + totalOtherExpenses;

    final summaries = <String, MemberFinancialSummary>{};
    final netBalances = <String, double>{};

    for (final id in memberIds) {
      final name = memberNames[id] ?? 'Member';
      final rent = bashaVaraShares[id] ?? 0.0;
      final util = utilityBillsShares[id] ?? 0.0;
      final meals = memberMeals[id] ?? 0.0;
      final mealCost = meals * mealRate;
      final otherShare = otherSharePerMember;

      final totalShare = rent + util + mealCost + otherShare;
      final paid = memberTotalPaid[id] ?? 0.0;
      final net = paid - totalShare; // positive if paid > share (should receive)

      summaries[id] = MemberFinancialSummary(
        memberId: id,
        memberName: name,
        bashaVaraShare: rent,
        utilityBillsShare: util,
        mealCost: mealCost,
        otherExpensesShare: otherShare,
        totalShare: totalShare,
        totalPaid: paid,
        netBalance: net,
        mealsCount: meals,
      );

      netBalances[id] = net;
    }

    // 4. Generate optimal settlement recommendations
    final recommendations = _calculateOptimalSettlements(netBalances, memberNames);

    return MonthlyFinancialResult(
      totalMessExpense: totalMessExpense,
      totalBills: totalBills,
      totalFoodAndBazar: totalFoodAndBazarExpense,
      totalOtherExpenses: totalOtherExpenses,
      totalMeals: totalMeals,
      mealRate: mealRate,
      memberSummaries: summaries,
      recommendations: recommendations,
    );
  }

  /// Calculates simplified settlement transactions minimizing transactions between debtors and creditors.
  static List<SettlementRecommendation> _calculateOptimalSettlements(
    Map<String, double> balances,
    Map<String, String> names,
  ) {
    final recommendations = <SettlementRecommendation>[];

    // Separate debtors (need to pay) and creditors (should receive)
    final debtors = <MapEntry<String, double>>[];
    final creditors = <MapEntry<String, double>>[];

    balances.forEach((id, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(id, -balance)); // positive amount owed
      } else if (balance > 0.01) {
        creditors.add(MapEntry(id, balance));
      }
    });

    int d = 0;
    int c = 0;

    while (d < debtors.length && c < creditors.length) {
      final debtor = debtors[d];
      final creditor = creditors[c];

      final settleAmount = debtor.value < creditor.value ? debtor.value : creditor.value;
      if (settleAmount > 0.01) {
        recommendations.add(
          SettlementRecommendation(
            senderId: debtor.key,
            senderName: names[debtor.key] ?? 'Member',
            receiverId: creditor.key,
            receiverName: names[creditor.key] ?? 'Member',
            amount: settleAmount,
          ),
        );
      }

      debtors[d] = MapEntry(debtor.key, debtor.value - settleAmount);
      creditors[c] = MapEntry(creditor.key, creditor.value - settleAmount);

      if (debtors[d].value <= 0.01) d++;
      if (creditors[c].value <= 0.01) c++;
    }

    return recommendations;
  }
}
