import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';
import '../models/mess.dart';
import '../models/monthly_cycle.dart';
import '../services/mock_seed_service.dart';

class MessRepository {
  static const String _keyCurrentMess = 'messhub_cached_mess';
  static const String _keyMembers = 'messhub_cached_members';
  static const String _keyCycles = 'messhub_cached_cycles';

  final SharedPreferences _prefs;

  MessRepository(this._prefs);

  Mess? _currentMess;
  Mess? get currentMess => _currentMess;

  List<MessMember> _members = [];
  List<MessMember> get members => _members;

  List<MonthlyCycle> _cycles = [];
  List<MonthlyCycle> get cycles => _cycles;

  MonthlyCycle? get activeCycle {
    try {
      return _cycles.firstWhere((c) => !c.isClosed);
    } catch (_) {
      return _cycles.isNotEmpty ? _cycles.last : null;
    }
  }

  Future<void> initMessData(String userId, {bool allowDemoFallback = true}) async {
    final cachedMess = _prefs.getString(_keyCurrentMess);
    if (cachedMess != null) {
      try {
        _currentMess = Mess.fromJson(jsonDecode(cachedMess));
      } catch (_) {}
    }

    if (_currentMess == null && allowDemoFallback) {
      _currentMess = MockSeedService.sampleMess;
      await _prefs.setString(_keyCurrentMess, jsonEncode(_currentMess!.toJson()));
    }

    final cachedMembers = _prefs.getString(_keyMembers);
    if (cachedMembers != null) {
      try {
        final List list = jsonDecode(cachedMembers);
        _members = list.map((m) => MessMember.fromJson(m)).toList();
      } catch (_) {}
    }
    if (_members.isEmpty && _currentMess?.id == MockSeedService.sampleMess.id) {
      _members = List.from(MockSeedService.sampleMembers);
      await _saveMembersToCache();
    }

    final cachedCycles = _prefs.getString(_keyCycles);
    if (cachedCycles != null) {
      try {
        final List list = jsonDecode(cachedCycles);
        _cycles = list.map((c) => MonthlyCycle.fromJson(c)).toList();
      } catch (_) {}
    }
    if (_cycles.isEmpty && _currentMess?.id == MockSeedService.sampleMess.id) {
      _cycles = [MockSeedService.currentCycle];
      await _saveCyclesToCache();
    }

    // Attempt Supabase fetch if connected
    if (SupabaseConfig.isConfigured && _currentMess != null) {
      await _fetchFromSupabase();
    }
  }

  Future<void> _fetchFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null || _currentMess == null) return;
    try {
      final membersRes = await client
          .from('mess_members')
          .select('*, profiles(name, email, avatar_url)')
          .eq('mess_id', _currentMess!.id);
      if (membersRes.isNotEmpty) {
        _members = membersRes.map((m) => MessMember.fromJson(m)).toList();
        await _saveMembersToCache();
      }

      final cyclesRes = await client
          .from('monthly_cycles')
          .select()
          .eq('mess_id', _currentMess!.id)
          .order('year', ascending: true)
          .order('month', ascending: true);
      if (cyclesRes.isNotEmpty) {
        _cycles = cyclesRes.map((c) => MonthlyCycle.fromJson(c)).toList();
        await _saveCyclesToCache();
      }
    } catch (_) {}
  }

  Future<Mess> createMess({
    required String name,
    required String area,
    required int cycleStartDay,
    String? description,
    required String creatorId,
    String? creatorName,
    String? creatorEmail,
  }) async {
    final inviteCode = _generateInviteCode();
    final newMess = Mess(
      id: 'mess_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      area: area,
      inviteCode: inviteCode,
      cycleStartDay: cycleStartDay,
      description: description,
      createdBy: creatorId,
      createdAt: DateTime.now(),
    );

    _currentMess = newMess;
    await _prefs.setString(_keyCurrentMess, jsonEncode(newMess.toJson()));

    // Create admin member (Only creator initially - 0 other members)
    _members = [
      MessMember(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        messId: newMess.id,
        userId: creatorId,
        role: MemberRole.admin,
        joinedAt: DateTime.now(),
        userName: creatorName ?? 'Manager',
        userEmail: creatorEmail ?? '',
      ),
    ];
    await _saveMembersToCache();

    // Create initial monthly cycle
    final now = DateTime.now();
    _cycles = [
      MonthlyCycle(
        id: 'cycle_${now.year}_${now.month}',
        messId: newMess.id,
        year: now.year,
        month: now.month,
        isClosed: false,
        createdAt: now,
      ),
    ];
    await _saveCyclesToCache();

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('messes').insert(newMess.toJson());
          await client.from('mess_members').insert(_members.first.toJson());
          await client.from('monthly_cycles').insert(_cycles.first.toJson());
        } catch (_) {}
      }
    }

    return newMess;
  }

  Future<bool> joinMess({required String inviteCode, required String userId}) async {
    final code = inviteCode.trim().toUpperCase();

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          final messRes = await client.from('messes').select().eq('invite_code', code).maybeSingle();
          if (messRes != null) {
            final mess = Mess.fromJson(messRes);
            _currentMess = mess;
            await _prefs.setString(_keyCurrentMess, jsonEncode(mess.toJson()));

            await client.from('mess_members').insert({
              'mess_id': mess.id,
              'user_id': userId,
              'role': 'MEMBER',
            });
            await _fetchFromSupabase();
            return true;
          }
        } catch (_) {}
      }
    }

    // Sandbox check
    if (code == MockSeedService.sampleMess.inviteCode || code == 'MH8824' || code.length >= 4) {
      _currentMess = MockSeedService.sampleMess;
      await _prefs.setString(_keyCurrentMess, jsonEncode(_currentMess!.toJson()));
      return true;
    }

    return false;
  }

  Future<bool> removeMember(String memberId) async {
    _members.removeWhere((m) => m.id == memberId || m.userId == memberId);
    await _saveMembersToCache();

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client?.from('mess_members').delete().eq('id', memberId);
      } catch (_) {}
    }
    return true;
  }

  Future<MonthlyCycle> closeCurrentCycleAndStartNew() async {
    final current = activeCycle;
    final now = DateTime.now();

    if (current != null) {
      final closedIndex = _cycles.indexWhere((c) => c.id == current.id);
      if (closedIndex != -1) {
        _cycles[closedIndex] = MonthlyCycle(
          id: current.id,
          messId: current.messId,
          year: current.year,
          month: current.month,
          isClosed: true,
          closedAt: now,
          createdAt: current.createdAt,
        );
      }
    }

    int nextMonth = (current?.month ?? now.month) + 1;
    int nextYear = current?.year ?? now.year;
    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear += 1;
    }

    final newCycle = MonthlyCycle(
      id: 'cycle_${nextYear}_$nextMonth',
      messId: _currentMess?.id ?? 'mess_active',
      year: nextYear,
      month: nextMonth,
      isClosed: false,
      createdAt: now,
    );

    _cycles.add(newCycle);
    await _saveCyclesToCache();

    if (SupabaseConfig.isConfigured && current != null) {
      try {
        await SupabaseConfig.client
            ?.from('monthly_cycles')
            .update({'is_closed': true, 'closed_at': now.toIso8601String()})
            .eq('id', current.id);
        await SupabaseConfig.client?.from('monthly_cycles').insert(newCycle.toJson());
      } catch (_) {}
    }

    return newCycle;
  }

  Future<MessMember> addMember({
    required String messId,
    required String name,
    String? email,
    String? phone,
    MemberRole role = MemberRole.member,
  }) async {
    final rand = Random().nextInt(9999);
    final now = DateTime.now();
    final newUserId = 'user_${now.millisecondsSinceEpoch}_$rand';
    final member = MessMember(
      id: 'mem_${now.millisecondsSinceEpoch}_$rand',
      messId: messId,
      userId: newUserId,
      role: role,
      joinedAt: now,
      userName: name,
      userEmail: email ?? (phone != null && phone.isNotEmpty ? phone : null),
    );

    _members.add(member);
    await _saveMembersToCache();

    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        try {
          await client.from('mess_members').insert(member.toJson());
        } catch (_) {}
      }
    }

    return member;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _saveMembersToCache() async {
    await _prefs.setString(_keyMembers, jsonEncode(_members.map((m) => m.toJson()).toList()));
  }

  Future<void> clearAllData() async {
    _currentMess = null;
    _members = [];
    _cycles = [];
    await _prefs.remove(_keyCurrentMess);
    await _prefs.remove(_keyMembers);
    await _prefs.remove(_keyCycles);
  }

  Future<void> _saveCyclesToCache() async {
    await _prefs.setString(_keyCycles, jsonEncode(_cycles.map((c) => c.toJson()).toList()));
  }
}
