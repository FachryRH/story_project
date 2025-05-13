import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale? _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Locale? get locale => _locale;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    
    if (savedLocale != null) {
      setLocale(Locale(savedLocale));
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    
    _locale = locale;
    notifyListeners();
  }

  Future<void> clearLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localeKey);
    
    _locale = null;
    notifyListeners();
  }
} 