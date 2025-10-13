import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages appearance-related preferences like selected font family.
class AppearanceService {
  AppearanceService._internal();
  static final AppearanceService instance = AppearanceService._internal();

  /// Notifies app about font changes. Value examples: 'auto', 'cairo', 'tajawal', 'poppins', 'lato'
  final ValueNotifier<String> fontKeyNotifier = ValueNotifier<String>('auto');

  Future<void> initialize() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    fontKeyNotifier.value = prefs.getString('appearance.fontKey') ?? 'auto';
  }

  Future<void> setFontKey(String key) async {
    fontKeyNotifier.value = key;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('appearance.fontKey', key);
  }
}
