import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_config.dart';
import '../models/user_profile.dart';

class AuthRepository {
  static const String _keyProfile = 'messhub_cached_profile';
  final SharedPreferences _prefs;

  AuthRepository(this._prefs);

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  Future<void> initSession() async {
    final cached = _prefs.getString(_keyProfile);
    if (cached != null) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(cached));
        return;
      } catch (_) {}
    }

    if (SupabaseConfig.isConfigured) {
      final supaUser = SupabaseConfig.client?.auth.currentUser;
      if (supaUser != null) {
        await _fetchProfile(supaUser.id);
        return;
      }
    }

    // If no existing cached session or remote auth, leave unauthenticated for clean login/register
    _currentUser = null;
  }

  Future<void> _fetchProfile(String userId) async {
    try {
      final client = SupabaseConfig.client;
      if (client == null) return;
      final res = await client.from('profiles').select().eq('id', userId).maybeSingle();
      if (res != null) {
        _currentUser = UserProfile.fromJson(res);
        await _saveProfileToCache(_currentUser!);
      }
    } catch (_) {}
  }

  Future<UserProfile> signIn({required String email, required String password}) async {
    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        final authRes = await client.auth.signInWithPassword(email: email, password: password);
        if (authRes.user != null) {
          await _fetchProfile(authRes.user!.id);
          if (_currentUser != null) return _currentUser!;
        }
      }
    }

    // Local / Sandbox mode fallback
    final isDemo = email.toLowerCase() == 'shihab@messhub.app' || email.toLowerCase() == 'demo@messhub.local';
    final uid = isDemo ? 'user_shihab' : 'user_${email.hashCode.abs()}';
    _currentUser = UserProfile(
      id: uid,
      name: isDemo ? 'Shihabul Islam' : (email.contains('@') ? email.split('@').first : 'User'),
      email: email,
      phone: '01711223344',
      createdAt: DateTime.now(),
    );
    await _saveProfileToCache(_currentUser!);
    return _currentUser!;
  }

  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (SupabaseConfig.isConfigured) {
      final client = SupabaseConfig.client;
      if (client != null) {
        final authRes = await client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name, 'phone': phone},
        );
        if (authRes.user != null) {
          final newProfile = UserProfile(
            id: authRes.user!.id,
            name: name,
            email: email,
            phone: phone,
            createdAt: DateTime.now(),
          );
          _currentUser = newProfile;
          await _saveProfileToCache(newProfile);
          return newProfile;
        }
      }
    }

    final newProfile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      createdAt: DateTime.now(),
    );
    _currentUser = newProfile;
    await _saveProfileToCache(newProfile);
    return newProfile;
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client?.auth.signOut();
      } catch (_) {}
    }
    _currentUser = null;
    await _prefs.remove(_keyProfile);
  }

  Future<void> resetPassword(String email) async {
    if (SupabaseConfig.isConfigured) {
      await SupabaseConfig.client?.auth.resetPasswordForEmail(email);
    }
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(name: name, phone: phone);
    _currentUser = updated;
    await _saveProfileToCache(updated);

    if (SupabaseConfig.isConfigured) {
      try {
        await SupabaseConfig.client?.from('profiles').update({
          'name': name,
          'phone': phone,
        }).eq('id', updated.id);
      } catch (_) {}
    }
  }

  Future<void> _saveProfileToCache(UserProfile profile) async {
    await _prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }
}
