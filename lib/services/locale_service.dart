import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// حالة اللغة
@immutable
class LocaleState {
  const LocaleState({
    this.locale,
  });

  final Locale? locale;

  LocaleState copyWith({
    Locale? locale,
  }) =>
      LocaleState(
        locale: locale ?? this.locale,
      );
}

/// Centralized locale management with persistence and change notifications.
class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier() : super(const LocaleState());

  static const String _prefsKey = 'app_locale_code';

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
      state = state.copyWith(locale: Locale(code));
    }
  }

  /// Set and persist locale; notifies listeners for hot update
  Future<void> setLocale(Locale? newLocale) async {
    if (newLocale != null &&
        !supportedLocales
            .any((Locale l) => l.languageCode == newLocale.languageCode)) {
      return;
    }

    state = state.copyWith(locale: newLocale);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, newLocale.languageCode);
    }
  }
}

// ========== Riverpod Providers ==========

/// Provider للـ LocaleNotifier
final StateNotifierProvider<LocaleNotifier, LocaleState>
    localeNotifierProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
        (StateNotifierProviderRef<LocaleNotifier, LocaleState> ref) =>
            LocaleNotifier());

/// Provider للغة الحالية
final Provider<Locale?> currentLocaleProvider = Provider<Locale?>(
    (ProviderRef<Locale?> ref) => ref.watch(localeNotifierProvider).locale);

/// Provider للغات المدعومة
final Provider<List<Locale>> supportedLocalesProvider = Provider<List<Locale>>(
    (ProviderRef<List<Locale>> ref) => LocaleNotifier.supportedLocales);
