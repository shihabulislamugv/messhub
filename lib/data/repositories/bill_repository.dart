import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';
import '../../domain/calculations/bill_split_validator.dart';
import '../models/bill.dart';
import '../services/mock_seed_service.dart';

class BillRepository {
  static const String _keyBills = 'messhub_cached_bills';
  final SharedPreferences _prefs;

  BillRepository(this._prefs);

  List<Bill> _bills = [];
  List<Bill> get bills => _bills;

  Future<void> initBills(String messId, String cycleId) async {
    final cached = _prefs.getString('${_keyBills}_$cycleId');
    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        _bills = list.map((b) => Bill.fromJson(b)).toList();
      } catch (_) {}
    }

    if (_bills.isEmpty) {
      _bills = MockSeedService.getInitialBills();
      await _saveBillsToCache(cycleId);
    }

    if (SupabaseConfig.isConfigured) {
      await _fetchFromSupabase(messId, cycleId);
    }
  }

  Future<void> _fetchFromSupabase(String messId, String cycleId) async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final billsRes = await client
          .from('bills')
          .select('*, profiles(name), bill_splits(*, profiles(name))')
          .eq('mess_id', messId)
          .eq('cycle_id', cycleId)
          .order('created_at', ascending: false);

      if (billsRes.isNotEmpty) {
        _bills = billsRes.map((b) {
          final splitsList = (b['bill_splits'] as List? ?? [])
              .map((s) => BillSplit.fromJson(s))
              .toList();
          return Bill.fromJson(b, splits: splitsList);
        }).toList();
        await _saveBillsToCache(cycleId);
      }
    } catch (_) {}
  }

  Future<BillSplitResult> addBill({
    required String messId,
    required String cycleId,
    required BillType billType,
    required String title,
    required double totalAmount,
    required String paidBy,
    required String paidByName,
    required SplitMethod splitMethod,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    Map<String, double>? customAllocations,
    DateTime? dueDate,
    String? note,
  }) async {
    // 1. Strict validation via Domain Validator
    final validation = BillSplitValidator.calculateAndValidate(
      billType: billType,
      splitMethod: splitMethod,
      totalAmount: totalAmount,
      memberIds: memberIds,
      customAllocations: customAllocations,
    );

    if (!validation.isValid) {
      return validation;
    }

    final billId = 'bill_${DateTime.now().millisecondsSinceEpoch}';
    final splits = <BillSplit>[];
    validation.memberAllocations.forEach((mId, amount) {
      splits.add(
        BillSplit(
          id: 'split_${DateTime.now().millisecondsSinceEpoch}_$mId',
          billId: billId,
          memberId: mId,
          amount: amount,
          memberName: memberNames[mId],
        ),
      );
    });

    final newBill = Bill(
      id: billId,
      messId: messId,
      cycleId: cycleId,
      billType: billType,
      title: title,
      totalAmount: totalAmount,
      paidBy: paidBy,
      paidByName: paidByName,
      splitMethod: splitMethod,
      dueDate: dueDate,
      note: note,
      createdAt: DateTime.now(),
      splits: splits,
    );

    _bills.insert(0, newBill);
    await _saveBillsToCache(cycleId);

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('bills').insert(newBill.toJson());
          final splitsJson = splits.map((s) => s.toJson()).toList();
          await client.from('bill_splits').insert(splitsJson);
        } catch (_) {}
      }
    }

    return validation;
  }

  Future<void> deleteBill(String billId, String cycleId) async {
    _bills.removeWhere((b) => b.id == billId);
    await _saveBillsToCache(cycleId);

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client?.from('bills').delete().eq('id', billId);
      } catch (_) {}
    }
  }

  Future<void> _saveBillsToCache(String cycleId) async {
    await _prefs.setString(
      '${_keyBills}_$cycleId',
      jsonEncode(_bills.map((b) => b.toJson()).toList()),
    );
  }
}
