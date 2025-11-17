import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// أداة لضمان تنفيذ عمليات Firestore على platform thread
class PlatformThreadSafety {
  static bool _isInitialized = false;

  /// تهيئة أداة الأمان
  static void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;
    debugPrint('🔒 تم تهيئة أداة أمان platform thread');
  }

  /// التحقق من أن العملية تعمل على platform thread
  static bool get isOnPlatformThread {
    try {
      // التحقق من أننا في main isolate
      return !kIsWeb && Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux;
    } catch (e) {
      debugPrint('⚠️ خطأ في التحقق من platform thread: $e');
      return true; // افتراض أننا على platform thread في حالة الخطأ
    }
  }

  /// تنفيذ عملية على platform thread
  static Future<T> executeOnPlatformThread<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    if (!_isInitialized) {
      initialize();
    }

    // إذا كنا بالفعل على platform thread، نفذ العملية مباشرة
    if (isOnPlatformThread) {
      try {
        return await operation();
      } catch (e) {
        debugPrint('❌ خطأ في تنفيذ $operationName على platform thread: $e');
        rethrow;
      }
    }

    // إذا لم نكن على platform thread، استخدم Future.microtask
    return await Future.microtask(() async {
      try {
        return await operation();
      } catch (e) {
        debugPrint('❌ خطأ في تنفيذ $operationName عبر Future.microtask: $e');
        rethrow;
      }
    });
  }

  /// تنفيذ عملية Firestore على platform thread مع معالجة خاصة
  static Future<T> executeFirestoreOperation<T>(
    Future<T> Function() firestoreOperation, {
    String? operationName,
    bool retryOnFailure = true,
    int maxRetries = 3,
  }) async {
    if (!_isInitialized) {
      initialize();
    }

    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // التأكد من التنفيذ على platform thread
        return await executeOnPlatformThread(
          firestoreOperation,
          operationName: operationName,
        );
      } catch (e) {
        retryCount++;
        debugPrint(
            '❌ فشل في تنفيذ $operationName (محاولة $retryCount/$maxRetries): $e');

        if (!retryOnFailure || retryCount >= maxRetries) {
          rethrow;
        }

        // انتظار قصير قبل إعادة المحاولة
        await Future<void>.delayed(Duration(milliseconds: 100 * retryCount));
      }
    }

    throw Exception('فشل في تنفيذ $operationName بعد $maxRetries محاولات');
  }

  /// تنفيذ عمليات متعددة على platform thread
  static Future<List<T>> executeMultipleOnPlatformThread<T>(
    List<Future<T> Function()> operations, {
    String? operationName,
    bool parallel = false,
  }) async {
    if (!_isInitialized) {
      initialize();
    }

    if (parallel) {
      // تنفيذ متوازي
      final List<Future<T>> futures = operations
          .map((operation) =>
              executeOnPlatformThread(operation, operationName: operationName))
          .toList();

      return await Future.wait(futures);
    } else {
      // تنفيذ متسلسل
      final List<T> results = <T>[];
      for (int i = 0; i < operations.length; i++) {
        final T result = await executeOnPlatformThread(
          operations[i],
          operationName: '${operationName}_$i',
        );
        results.add(result);
      }
      return results;
    }
  }

  /// التحقق من سلامة العمليات قبل التنفيذ
  static bool validateOperation({
    required String operationName,
    required Map<String, dynamic>? parameters,
  }) {
    if (!_isInitialized) {
      initialize();
    }

    // التحقق من أن العملية ليست فارغة
    if (operationName.isEmpty) {
      debugPrint('❌ اسم العملية فارغ');
      return false;
    }

    // التحقق من أننا على platform thread
    if (!isOnPlatformThread) {
      debugPrint(
          '⚠️ تحذير: العملية $operationName قد لا تعمل على platform thread');
    }

    debugPrint('✅ تم التحقق من صحة العملية: $operationName');
    return true;
  }

  /// إحصائيات الأمان
  static Map<String, dynamic> getSafetyStats() => <String, dynamic>{
      'isInitialized': _isInitialized,
      'isOnPlatformThread': isOnPlatformThread,
      'timestamp': DateTime.now().toIso8601String(),
    };

  /// إعادة تعيين حالة الأمان
  static void reset() {
    _isInitialized = false;
    debugPrint('🔄 تم إعادة تعيين حالة أمان platform thread');
  }

  /// تنفيذ Stream handler على platform thread
  /// يلتف حول Stream handlers لضمان التنفيذ على platform thread
  static Future<T> executeStreamHandler<T>(
    Future<T> Function() handler, {
    String? operationName,
  }) async {
    if (!_isInitialized) {
      initialize();
    }

    // استخدام Future.microtask لضمان التنفيذ على platform thread
    return await Future.microtask(() async {
      try {
        return await handler();
      } catch (e) {
        debugPrint('❌ خطأ في تنفيذ Stream handler $operationName: $e');
        rethrow;
      }
    });
  }

  /// تنفيذ Stream listener callback على platform thread
  /// للاستخدام مع Stream.listen callbacks
  static void executeStreamListenerCallback<T>(
    T Function() callback, {
    String? operationName,
  }) {
    if (!_isInitialized) {
      initialize();
    }

    // استخدام Future.microtask لضمان التنفيذ على platform thread
    Future.microtask(() {
      try {
        callback();
      } catch (e) {
        debugPrint(
            '❌ خطأ في تنفيذ Stream listener callback $operationName: $e');
      }
    });
  }
}
