import 'package:flutter/material.dart';
import '../../data/models/mess.dart';
import '../../data/models/monthly_cycle.dart';
import '../../data/models/bill.dart';
import '../../data/models/expense.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/mess_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/settlement_repository.dart';
import '../../domain/calculations/bill_split_validator.dart';
import '../../domain/calculations/meal_rate_calculator.dart';
import '../../domain/calculations/balance_calculator.dart';

class MessProvider extends ChangeNotifier {
  final MessRepository _messRepo;
  final BillRepository _billRepo;
  final ExpenseRepository _expenseRepo;
  final MealRepository _mealRepo;
  final SettlementRepository _settlementRepo;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MonthlyCycle? _selectedCycle;
  MonthlyCycle? get selectedCycle => _selectedCycle ?? _messRepo.activeCycle;

  MonthlyFinancialResult? _financialResult;
  MonthlyFinancialResult? get financialResult => _financialResult;

  MessProvider({
    required MessRepository messRepo,
    required BillRepository billRepo,
    required ExpenseRepository expenseRepo,
    required MealRepository mealRepo,
    required SettlementRepository settlementRepo,
  })  : _messRepo = messRepo,
        _billRepo = billRepo,
        _expenseRepo = expenseRepo,
        _mealRepo = mealRepo,
        _settlementRepo = settlementRepo;

  Mess? get currentMess => _messRepo.currentMess;
  List<MessMember> get members => _messRepo.members;
  List<MonthlyCycle> get cycles => _messRepo.cycles;

  List<Bill> get bills => _billRepo.bills;
  List<Expense> get expenses => _expenseRepo.expenses;
  List<MealEntry> get meals => _mealRepo.meals;
  List<SettlementRecord> get settlements => _settlementRepo.records;

  Map<String, String> get memberNamesMap {
    final map = <String, String>{};
    for (final m in members) {
      map[m.userId] = m.userName ?? 'Member';
    }
    return map;
  }

  List<String> get memberIds => members.map((m) => m.userId).toList();

  Future<void> loadMessData(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _messRepo.initMessData(userId);
      _selectedCycle = _messRepo.activeCycle;

      if (_messRepo.currentMess != null && _selectedCycle != null) {
        final messId = _messRepo.currentMess!.id;
        final cycleId = _selectedCycle!.id;

        await Future.wait([
          _billRepo.initBills(messId, cycleId),
          _expenseRepo.initExpenses(messId, cycleId),
          _mealRepo.initMeals(messId, cycleId),
          _settlementRepo.initSettlements(messId, cycleId),
        ]);

        _recalculateFinancials();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCycle(MonthlyCycle cycle) async {
    _selectedCycle = cycle;
    _isLoading = true;
    notifyListeners();

    if (_messRepo.currentMess != null) {
      final messId = _messRepo.currentMess!.id;
      final cycleId = cycle.id;

      await Future.wait([
        _billRepo.initBills(messId, cycleId),
        _expenseRepo.initExpenses(messId, cycleId),
        _mealRepo.initMeals(messId, cycleId),
        _settlementRepo.initSettlements(messId, cycleId),
      ]);

      _recalculateFinancials();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _recalculateFinancials() {
    final names = memberNamesMap;
    final ids = memberIds;

    // 1. Rent shares (Basha Vara)
    final rentShares = <String, double>{};
    // 2. Utility & other bill shares
    final utilityShares = <String, double>{};

    for (final id in ids) {
      rentShares[id] = 0.0;
      utilityShares[id] = 0.0;
    }

    for (final bill in bills) {
      for (final split in bill.splits) {
        if (bill.billType == BillType.rent) {
          rentShares[split.memberId] = (rentShares[split.memberId] ?? 0.0) + split.amount;
        } else {
          utilityShares[split.memberId] = (utilityShares[split.memberId] ?? 0.0) + split.amount;
        }
      }
    }

    // 3. Member meals count
    final memberMeals = _mealRepo.getMemberMealTotals(ids);

    // 4. Food & Bazar total
    final totalFood = _expenseRepo.getTotalFoodAndBazarExpense();

    // 5. Other shared expenses (Cleaning, Repair, Transport, Other)
    final totalOther = _expenseRepo.getTotalOtherExpenses();

    // 6. Member Total Paid:
    // SUM(Bills paid by m) + SUM(Expenses paid by m) + SUM(Settlements paid) - SUM(Settlements received)
    final totalPaid = <String, double>{};
    for (final id in ids) {
      totalPaid[id] = 0.0;
    }

    for (final bill in bills) {
      totalPaid[bill.paidBy] = (totalPaid[bill.paidBy] ?? 0.0) + bill.totalAmount;
    }

    for (final exp in expenses) {
      totalPaid[exp.paidBy] = (totalPaid[exp.paidBy] ?? 0.0) + exp.amount;
    }

    final settlementOffsets = _settlementRepo.getNetSettlementOffsets(ids);
    settlementOffsets.forEach((id, offset) {
      totalPaid[id] = (totalPaid[id] ?? 0.0) + offset;
    });

    _financialResult = BalanceCalculator.computeMonthlyBalances(
      memberNames: names,
      bashaVaraShares: rentShares,
      utilityBillsShares: utilityShares,
      memberMeals: memberMeals,
      totalOtherExpenses: totalOther,
      memberTotalPaid: totalPaid,
      totalFoodAndBazarExpense: totalFood,
    );
  }

  MemberFinancialSummary? getMemberSummary(String userId) {
    return _financialResult?.memberSummaries[userId];
  }

  // --- ACTIONS ---

  Future<bool> createMess({
    required String name,
    required String area,
    required int cycleStartDay,
    String? description,
    required String creatorId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _messRepo.createMess(
        name: name,
        area: area,
        cycleStartDay: cycleStartDay,
        description: description,
        creatorId: creatorId,
      );
      _selectedCycle = _messRepo.activeCycle;
      _recalculateFinancials();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinMess({required String inviteCode, required String userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _messRepo.joinMess(inviteCode: inviteCode, userId: userId);
      if (success) {
        await loadMessData(userId);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<BillSplitResult> addBill({
    required BillType billType,
    required String title,
    required double totalAmount,
    required String paidBy,
    required SplitMethod splitMethod,
    Map<String, double>? customAllocations,
    DateTime? dueDate,
    String? note,
  }) async {
    if (currentMess == null || selectedCycle == null) {
      return const BillSplitResult(
        isValid: false,
        errorMessage: 'Active mess or cycle not found.',
        memberAllocations: {},
      );
    }

    final paidByName = memberNamesMap[paidBy] ?? 'Member';

    final res = await _billRepo.addBill(
      messId: currentMess!.id,
      cycleId: selectedCycle!.id,
      billType: billType,
      title: title,
      totalAmount: totalAmount,
      paidBy: paidBy,
      paidByName: paidByName,
      splitMethod: splitMethod,
      memberIds: memberIds,
      memberNames: memberNamesMap,
      customAllocations: customAllocations,
      dueDate: dueDate,
      note: note,
    );

    if (res.isValid) {
      _recalculateFinancials();
      notifyListeners();
    }

    return res;
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required ExpenseCategory category,
    required String paidBy,
    required DateTime expenseDate,
    String? note,
    String? receiptUrl,
    List<BazarItem> bazarItems = const [],
  }) async {
    if (currentMess == null || selectedCycle == null) return;
    final paidByName = memberNamesMap[paidBy] ?? 'Member';

    await _expenseRepo.addExpense(
      messId: currentMess!.id,
      cycleId: selectedCycle!.id,
      title: title,
      amount: amount,
      category: category,
      paidBy: paidBy,
      paidByName: paidByName,
      expenseDate: expenseDate,
      note: note,
      receiptUrl: receiptUrl,
      bazarItems: bazarItems,
    );

    _recalculateFinancials();
    notifyListeners();
  }

  Future<void> recordMeal({
    required String memberId,
    required DateTime mealDate,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    if (currentMess == null || selectedCycle == null) return;
    final memberName = memberNamesMap[memberId] ?? 'Member';

    await _mealRepo.recordMeal(
      messId: currentMess!.id,
      cycleId: selectedCycle!.id,
      memberId: memberId,
      memberName: memberName,
      mealDate: mealDate,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
    );

    _recalculateFinancials();
    notifyListeners();
  }

  Future<void> recordPayment({
    required String senderId,
    required String receiverId,
    required double amount,
    required DateTime paymentDate,
    String? note,
  }) async {
    if (currentMess == null || selectedCycle == null) return;
    final senderName = memberNamesMap[senderId] ?? 'Member';
    final receiverName = memberNamesMap[receiverId] ?? 'Member';

    await _settlementRepo.recordPayment(
      messId: currentMess!.id,
      cycleId: selectedCycle!.id,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      amount: amount,
      paymentDate: paymentDate,
      note: note,
    );

    _recalculateFinancials();
    notifyListeners();
  }

  Future<void> closeMonthlyCycle() async {
    final newCycle = await _messRepo.closeCurrentCycleAndStartNew();
    selectCycle(newCycle);
  }

  Future<void> removeMember(String memberId) async {
    await _messRepo.removeMember(memberId);
    _recalculateFinancials();
    notifyListeners();
  }

  Future<void> deleteBill(String billId, {required String cycleId}) async {
    await _billRepo.deleteBill(billId, cycleId);
    _recalculateFinancials();
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId, {required String cycleId}) async {
    await _expenseRepo.deleteExpense(expenseId, cycleId);
    _recalculateFinancials();
    notifyListeners();
  }
}
