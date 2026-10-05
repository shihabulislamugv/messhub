import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';
import '../models/meal.dart';
import '../services/mock_seed_service.dart';

class SettlementRepository {
  static const String _keySettlements = 'messhub_cached_settlements';
  final SharedPreferences _prefs;

  SettlementRepository(this._prefs);

  List<SettlementRecord> _records = [];
  List<SettlementRecord> get records => _records;

  Future<void> initSettlements(String messId, String cycleId) async {
    final cached = _prefs.getString('${_keySettlements}_$cycleId');
    if (cached != null) {
      try {
        final List list = jsonDecode(cached);
        _records = list.map((s) => SettlementRecord.fromJson(s)).toList();
      } catch (_) {}
    }

    if (_records.isEmpty) {
      _records = MockSeedService.getInitialSettlements();
      await _saveSettlementsToCache(cycleId);
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
          .from('settlement_records')
          .select('*, sender:sender_id(name), receiver:receiver_id(name)')
          .eq('mess_id', messId)
          .eq('cycle_id', cycleId)
          .order('payment_date', ascending: false);

      if (res.isNotEmpty) {
        _records = res.map((s) => SettlementRecord.fromJson(s)).toList();
        await _saveSettlementsToCache(cycleId);
      }
    } catch (_) {}
  }

  Future<SettlementRecord> recordPayment({
    required String messId,
    required String cycleId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required double amount,
    required DateTime paymentDate,
    String? note,
  }) async {
    final record = SettlementRecord(
      id: 'set_${DateTime.now().millisecondsSinceEpoch}',
      messId: messId,
      cycleId: cycleId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      amount: amount,
      paymentDate: paymentDate,
      note: note,
      createdAt: DateTime.now(),
    );

    _records.insert(0, record);
    await _saveSettlementsToCache(cycleId);

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('settlement_records').insert(record.toJson());
        } catch (_) {}
      }
    }

    return record;
  }

  /// Calculates net settlement offset per member (Paid as sender - Received as receiver)
  Map<String, double> getNetSettlementOffsets(List<String> memberIds) {
    final map = <String, double>{};
    for (final id in memberIds) {
      map[id] = 0.0;
    }

    for (final rec in _records) {
      map[rec.senderId] = (map[rec.senderId] ?? 0.0) + rec.amount;
      map[rec.receiverId] = (map[rec.receiverId] ?? 0.0) - rec.amount;
    }

    return map;
  }

  Future<void> _saveSettlementsToCache(String cycleId) async {
    await _prefs.setString(
      '${_keySettlements}_$cycleId',
      jsonEncode(_records.map((r) => r.toJson()).toList()),
    );
  }
}
