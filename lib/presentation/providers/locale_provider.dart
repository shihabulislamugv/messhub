import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_locale.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _keyLocale = 'messhub_selected_locale';
  final SharedPreferences _prefs;

  Locale _locale = AppLocale.en;
  Locale get locale => _locale;

  LocaleProvider(this._prefs) {
    final code = _prefs.getString(_keyLocale);
    if (code == 'bn') {
      _locale = AppLocale.bn;
    } else {
      _locale = AppLocale.en;
    }
  }

  bool get isBengali => _locale.languageCode == 'bn';

  void toggleLocale() {
    if (_locale.languageCode == 'bn') {
      setLocale(AppLocale.en);
    } else {
      setLocale(AppLocale.bn);
    }
  }

  Future<void> setLocale(Locale loc) async {
    _locale = loc;
    await _prefs.setString(_keyLocale, loc.languageCode);
    notifyListeners();
  }
}
