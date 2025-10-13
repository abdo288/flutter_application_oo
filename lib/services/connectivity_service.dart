import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// خدمة الاتصال المحسنة
class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;
  static bool _isConnected = true;
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  /// Stream للاستماع لحالة الاتصال
  static Stream<bool> get connectionStream => _connectionController.stream;

  /// الحصول على حالة الاتصال الحالية
  static bool get isConnected => _isConnected;

  /// الحصول على حالة الاتصال الحالية (اسم بديل)
  static bool get isOnline => _isConnected;

  /// تهيئة خدمة الاتصال
  static Future<void> initialize() async {
    try {
      // التحقق من حالة الاتصال الأولية
      await _checkInitialConnection();

      // الاستماع لتغييرات الاتصال
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (Object error) {
          debugPrint('خطأ في مراقبة الاتصال: $error');
        },
      );

      debugPrint('تم تهيئة خدمة الاتصال بنجاح');
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة الاتصال: $e');
    }
  }

  /// التحقق من الاتصال الأولي
  static Future<void> _checkInitialConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _isConnected = _hasConnection(results);
      _connectionController.add(_isConnected);
    } catch (e) {
      debugPrint('خطأ في التحقق من الاتصال الأولي: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  /// معالج تغيير الاتصال
  static void _onConnectivityChanged(List<ConnectivityResult> results) {
    final bool wasConnected = _isConnected;
    _isConnected = _hasConnection(results);

    if (wasConnected != _isConnected) {
      _connectionController.add(_isConnected);
      debugPrint('تغيرت حالة الاتصال: ${_isConnected ? "متصل" : "غير متصل"}');
    }
  }

  /// التحقق من وجود اتصال
  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.bluetooth ||
          result == ConnectivityResult.other);

  /// التحقق من الاتصال يدوياً
  static Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      _isConnected = _hasConnection(results);
      return _isConnected;
    } catch (e) {
      debugPrint('خطأ في التحقق من الاتصال: $e');
      return false;
    }
  }

  /// إضافة مستمع لحالة الاتصال
  static void addConnectivityListener(void Function(bool) listener) {
    _connectionController.stream.listen(listener);
  }

  /// إزالة مستمع لحالة الاتصال
  static void removeConnectivityListener(void Function(bool) listener) {
    // في التطبيق الحالي، لا نحتاج لإزالة المستمعين
    // لأن StreamController.broadcast يدير ذلك تلقائياً
  }

  /// تنظيف الموارد
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}
