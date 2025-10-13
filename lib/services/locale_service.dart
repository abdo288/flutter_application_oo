import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized locale management with persistence and change notifications.
class LocaleService extends ChangeNotifier {
  LocaleService._internal();
  static final LocaleService _instance = LocaleService._internal();
  static LocaleService get instance => _instance;

  static const String _prefsKey = 'app_locale_code';

  Locale? _locale;
  Locale? get locale => _locale;

  /// Supported locales for the application
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// Initialize from SharedPreferences
  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_prefsKey);
    if (code != null &&
        supportedLocales.any((Locale l) => l.languageCode == code)) {
      _locale = Locale(code);
    }
  }

  /// Set and persist locale; notifies listeners for hot update
  Future<void> setLocale(Locale? newLocale) async {
    if (newLocale != null &&
        !supportedLocales
            .any((Locale l) => l.languageCode == newLocale.languageCode)) {
      return;
    }

    _locale = newLocale;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, newLocale.languageCode);
    }
    notifyListeners();
  }
}
