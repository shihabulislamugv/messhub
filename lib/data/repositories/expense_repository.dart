import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/calculations/meal_rate_calculator.dart';
import '../models/expense.dart';
import '../services/mock_seed_service.dart';

class ExpenseRepository {
  static const String _keyExpenses = 'messhub_cached_expenses';
  final SharedPreferences _prefs;

  ExpenseRepository(this._prefs);

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  Future<void> initExpenses(String messId, String cycleId) async {
    final cached = _prefs.getString('${_keyExpenses}_$cycleId');
    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        _expenses = list.map((e) => Expense.fromJson(e)).toList();
      } catch (_) {}
    }

    final isDemoMess = messId == MockSeedService.sampleMess.id;
    if (_expenses.isEmpty && isDemoMess) {
      _expenses = MockSeedService.getInitialExpenses();
      await _saveExpensesToCache(cycleId);
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
          .from('expenses')
          .select('*, profiles(name), bazar_items(*)')
          .eq('mess_id', messId)
          .eq('cycle_id', cycleId)
          .order('expense_date', ascending: false);

      if (res.isNotEmpty) {
        _expenses = res.map((e) {
          final items = (e['bazar_items'] as List? ?? [])
              .map((b) => BazarItem.fromJson(b))
              .toList();
          return Expense.fromJson(e, items: items);
        }).toList();
        await _saveExpensesToCache(cycleId);
      }
    } catch (_) {}
  }

  Future<Expense> addExpense({
    required String messId,
    required String cycleId,
    required String title,
    required double amount,
    required ExpenseCategory category,
    required String paidBy,
    required String paidByName,
    required DateTime expenseDate,
    String? note,
    String? receiptUrl,
    List<BazarItem> bazarItems = const [],
  }) async {
    final expenseId = 'exp_${DateTime.now().millisecondsSinceEpoch}';
    final itemsWithId = bazarItems.map((item) => BazarItem(
      id: item.id.isEmpty ? 'bazar_${DateTime.now().millisecondsSinceEpoch}_${item.itemName.hashCode}' : item.id,
      expenseId: expenseId,
      itemName: item.itemName,
      quantity: item.quantity,
      unit: item.unit,
      price: item.price,
    )).toList();

    final newExpense = Expense(
      id: expenseId,
      messId: messId,
      cycleId: cycleId,
      title: title,
      amount: amount,
      category: category,
      paidBy: paidBy,
      paidByName: paidByName,
      expenseDate: expenseDate,
      note: note,
      receiptUrl: receiptUrl,
      createdAt: DateTime.now(),
      bazarItems: itemsWithId,
    );

    _expenses.insert(0, newExpense);
    await _saveExpensesToCache(cycleId);

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('expenses').insert(newExpense.toJson());
          if (itemsWithId.isNotEmpty) {
            final itemsJson = itemsWithId.map((i) => i.toJson()).toList();
            await client.from('bazar_items').insert(itemsJson);
          }
        } catch (_) {}
      }
    }

    return newExpense;
  }

  Future<void> deleteExpense(String expenseId, String cycleId) async {
    _expenses.removeWhere((e) => e.id == expenseId);
    await _saveExpensesToCache(cycleId);

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client?.from('expenses').delete().eq('id', expenseId);
      } catch (_) {}
    }
  }

  /// Calculates total food and bazar expenses in the cycle
  double getTotalFoodAndBazarExpense() {
    double total = 0.0;
    for (final exp in _expenses) {
      if (exp.isFoodOrBazar) {
        total += exp.amount;
      }
    }
    return total;
  }

  /// Calculates total other shared expenses (cleaning, repair, transport, other)
  double getTotalOtherExpenses() {
    double total = 0.0;
    for (final exp in _expenses) {
      if (!exp.isFoodOrBazar) {
        total += exp.amount;
      }
    }
    return total;
  }

  List<BazarItem> getAllBazarItems() {
    final list = <BazarItem>[];
    for (final exp in _expenses) {
      list.addAll(exp.bazarItems);
    }
    return list;
  }

  void clearExpenses() {
    _expenses = [];
  }

  Future<void> clearExpensesCache(String cycleId) async {
    _expenses = [];
    await _prefs.remove('${_keyExpenses}_$cycleId');
  }

  Future<void> _saveExpensesToCache(String cycleId) async {
    await _prefs.setString(
      '${_keyExpenses}_$cycleId',
      jsonEncode(_expenses.map((e) => e.toJson()).toList()),
    );
  }
}
