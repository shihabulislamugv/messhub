import 'package:flutter/material.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.uninitialized;
  AuthStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfile? get currentUser => _repo.currentUser;
  bool get isAuthenticated => _repo.currentUser != null;

  AuthProvider(this._repo) {
    _init();
  }

  Future<void> _init() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _repo.initSession();
      _status = _repo.currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repo.signUp(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _repo.resetPassword(email);
  }

  Future<void> updateProfile({required String name, String? phone}) async {
    await _repo.updateProfile(name: name, phone: phone);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
