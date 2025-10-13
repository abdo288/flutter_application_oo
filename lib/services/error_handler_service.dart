import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'performance_service.dart';

/// نوع الخطأ
enum ErrorType {
  network,
  validation,
  permission,
  storage,
  firebase,
  sync,
  unknown,
}

/// مستوى شدة الخطأ
enum ErrorSeverity {
  low, // تحذيرات بسيطة
  medium, // أخطاء يمكن التعامل معها
  high, // أخطاء تؤثر على الوظائف الأساسية
  critical // أخطاء تعطل التطبيق
}

/// معلومات الخطأ
class ErrorInfo {
  // الإجراء الذي كان يقوم به المستخدم

  ErrorInfo({
    required this.id,
    required this.message,
    this.details,
    required this.type,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
    this.context,
    this.userAction,
  });
  final String id;
  final String message;
  final String? details;
  final ErrorType type;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? stackTrace;
  final Map<String, dynamic>? context;
  final String? userAction;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'message': message,
        'details': details,
        'type': type.toString(),
        'severity': severity.toString(),
        'timestamp': timestamp.toIso8601String(),
        'stackTrace': stackTrace,
        'context': context,
        'userAction': userAction,
        'platform': _getPlatformInfo(),
        'appVersion': '1.1.0', // يجب أن يكون من pubspec.yaml
      };

  static Map<String, String> _getPlatformInfo() => <String, String>{
        'platform': defaultTargetPlatform.toString(),
        'isWeb': kIsWeb.toString(),
        'isDebug': kDebugMode.toString(),
      };
}

/// خدمة معالجة الأخطاء المحسنة
class ErrorHandlerService {
  static final Logger _logger = Logger('ErrorHandlerService');

  // قائمة انتظار الأخطاء غير المرسلة (للوضع غير المتصل)
  static final List<ErrorInfo> _pendingErrors = <ErrorInfo>[];

  // إحصائيات الأخطاء
  static final Map<ErrorType, int> _errorCounts = <ErrorType, int>{};
  static final Map<ErrorSeverity, int> _severityCounts = <ErrorSeverity, int>{};

  // Callbacks للمعالجة المخصصة
  static final List<void Function(ErrorInfo)> _errorCallbacks =
      <void Function(ErrorInfo p1)>[];

  /// تسجيل خطأ جديد
  static Future<void> handleError(
    Object error, {
    String? message,
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? stackTrace,
    Map<String, dynamic>? context,
    String? userAction,
    bool showToUser = true,
    void Function(String)? showUserMessage,
  }) async {
    try {
      // تحديد نوع الخطأ تلقائياً إذا لم يتم تحديده
      final ErrorType errorType = type ?? _determineErrorType(error);

      // إنشاء معلومات الخطأ
      final ErrorInfo errorInfo = ErrorInfo(
        id: _generateErrorId(),
        message: message ?? error.toString(),
        details: _extractErrorDetails(error),
        type: errorType,
        severity: severity,
        timestamp: DateTime.now(),
        stackTrace: stackTrace ?? StackTrace.current.toString(),
        context: context,
        userAction: userAction,
      );

      // تحديث الإحصائيات
      _updateErrorStats(errorInfo);

      // تسجيل الخطأ محلياً
      _logError(errorInfo);

      // إرسال الخطأ للخادم (إذا كان متاحاً)
      await _sendErrorToServer(errorInfo);

      // عرض رسالة للمستخدم
      if (showToUser && showUserMessage != null) {
        final String userMessage = _getUserFriendlyMessage(errorInfo);
        showUserMessage(userMessage);
      }

      // استدعاء الـ callbacks
      _notifyCallbacks(errorInfo);

      // تسجيل في خدمة الأداء
      PerformanceService.recordNetworkRequest(
        const Duration(milliseconds: 100),
        hasError: true,
      );
    } on Exception catch (e) {
      _logger
        ..severe('خطأ في معالجة الخطأ: $e')
        // في حالة فشل معالجة الخطأ، نسجله بطريقة بسيطة
        ..severe('الخطأ الأصلي: $error');
    }
  }

  /// تحديد نوع الخطأ تلقائياً
  static ErrorType _determineErrorType(Object error) {
    if (error is SocketException) {
      return ErrorType.network;
    } else if (error is FirebaseException) {
      return ErrorType.firebase;
    } else if (error is FileSystemException) {
      return ErrorType.storage;
    } else if (error is ArgumentError || error is FormatException) {
      return ErrorType.validation;
    } else {
      return ErrorType.unknown;
    }
  }

  /// استخراج تفاصيل إضافية من الخطأ
  static String? _extractErrorDetails(Object error) {
    if (error is FirebaseException) {
      return 'كود الخطأ: ${error.code}\nالرسالة: ${error.message}';
    } else if (error is SocketException) {
      return 'عنوان الشبكة: ${error.address?.address}\nالمنفذ: ${error.port}';
    } else if (error is HttpException) {
      return 'رمز الحالة: ${error.message}';
    }
    return error.toString();
  }

  /// إنشاء معرف فريد للخطأ
  static String _generateErrorId() =>
      // ignore: lines_longer_than_80_chars
      '${DateTime.now().millisecondsSinceEpoch}_${_errorCounts.values.fold(0, (int a, int b) => a + b)}';

  /// تحديث إحصائيات الأخطاء
  static void _updateErrorStats(ErrorInfo errorInfo) {
    _errorCounts[errorInfo.type] = (_errorCounts[errorInfo.type] ?? 0) + 1;
    _severityCounts[errorInfo.severity] =
        (_severityCounts[errorInfo.severity] ?? 0) + 1;
  }

  /// تسجيل الخطأ محلياً
  static void _logError(ErrorInfo errorInfo) {
    switch (errorInfo.severity) {
      case ErrorSeverity.low:
        _logger.info('[${errorInfo.type}] ${errorInfo.message}');
        break;
      case ErrorSeverity.medium:
        _logger.warning('[${errorInfo.type}] ${errorInfo.message}');
        break;
      case ErrorSeverity.high:
        _logger.severe('[${errorInfo.type}] ${errorInfo.message}');
        break;
      case ErrorSeverity.critical:
        _logger.shout('[${errorInfo.type}] ${errorInfo.message}');
        break;
    }

    if (errorInfo.stackTrace != null &&
        errorInfo.severity != ErrorSeverity.low) {
      _logger.fine('Stack Trace:\n${errorInfo.stackTrace}');
    }
  }

  /// إرسال الخطأ للخادم
  static Future<void> _sendErrorToServer(ErrorInfo errorInfo) async {
    try {
      // في بيئة الإنتاج، يمكن إرسال الأخطاء إلى خدمة مراقبة مثل Crashlytics
      if (!kDebugMode && errorInfo.severity != ErrorSeverity.low) {
        // إضافة إلى قائمة الانتظار للمعالجة اللاحقة
        _pendingErrors.add(errorInfo);

        // محاولة الإرسال إذا كان الاتصال متاحاً
        await _flushPendingErrors();
      }
    } on Exception catch (e) {
      _logger.warning('فشل في إرسال الخطأ للخادم: $e');
    }
  }

  /// مسح قائمة الأخطاء المعلقة
  static Future<void> _flushPendingErrors() async {
    if (_pendingErrors.isEmpty) return;

    try {
      // محاولة إرسال الأخطاء المعلقة
      for (int i = _pendingErrors.length - 1; i >= 0; i--) {
        // هنا يمكن إرسال الخطأ لخدمة مراقبة خارجية
        // await _sendToExternalService(_pendingErrors[i]);

        // إزالة الخطأ بعد الإرسال الناجح
        _pendingErrors.removeAt(i);
      }
    } on Exception catch (e) {
      _logger.warning('فشل في مسح قائمة الأخطاء المعلقة: $e');
    }
  }

  /// عرض الخطأ للمستخدم (دالة مساعدة للاستخدام مع callback)
  static void showErrorToUser(BuildContext context, ErrorInfo errorInfo) {
    final String userMessage = _getUserFriendlyMessage(errorInfo);

    switch (errorInfo.severity) {
      case ErrorSeverity.low:
        // للأخطاء البسيطة، لا نعرض شيء للمستخدم
        break;
      case ErrorSeverity.medium:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
          ),
        );

        // للأخطاء الحرجة، يمكن إضافة dialog
        if (errorInfo.severity == ErrorSeverity.critical) {
          _showCriticalErrorDialog(context, errorInfo);
        }
        break;
    }
  }

  /// إنشاء رسالة مفهومة للمستخدم
  static String _getUserFriendlyMessage(ErrorInfo errorInfo) {
    switch (errorInfo.type) {
      case ErrorType.network:
        return 'مشكلة في الاتصال بالإنترنت. يرجى المحاولة مرة أخرى.';
      case ErrorType.validation:
        return 'البيانات المدخلة غير صحيحة. يرجى التحقق والمحاولة مرة أخرى.';
      case ErrorType.permission:
        return 'ليس لديك الصلاحية اللازمة لتنفيذ هذا الإجراء.';
      case ErrorType.storage:
        return 'مشكلة في الوصول للملفات. يرجى التحقق من المساحة المتاحة.';
      case ErrorType.firebase:
        return 'مشكلة في الخدمة السحابية. يرجى المحاولة لاحقاً.';
      case ErrorType.sync:
        return 'مشكلة في مزامنة البيانات. يرجى المحاولة مرة أخرى.';
      case ErrorType.unknown:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
    }
  }

  /// عرض dialog للأخطاء الحرجة
  static void _showCriticalErrorDialog(
      BuildContext context, ErrorInfo errorInfo) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('خطأ حرج'),
          ],
        ),
        content: Text(_getUserFriendlyMessage(errorInfo)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
          if (kDebugMode)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showErrorDetails(context, errorInfo);
              },
              child: const Text('التفاصيل'),
            ),
        ],
      ),
    );
  }

  /// عرض تفاصيل الخطأ (للمطورين)
  static void _showErrorDetails(BuildContext context, ErrorInfo errorInfo) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تفاصيل الخطأ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('المعرف: ${errorInfo.id}'),
              const SizedBox(height: 8),
              Text('النوع: ${errorInfo.type}'),
              const SizedBox(height: 8),
              Text('الشدة: ${errorInfo.severity}'),
              const SizedBox(height: 8),
              Text('الوقت: ${errorInfo.timestamp}'),
              const SizedBox(height: 8),
              Text('الرسالة: ${errorInfo.message}'),
              if (errorInfo.details != null) ...<Widget>[
                const SizedBox(height: 8),
                Text('التفاصيل: ${errorInfo.details}'),
              ],
              if (errorInfo.userAction != null) ...<Widget>[
                const SizedBox(height: 8),
                Text('إجراء المستخدم: ${errorInfo.userAction}'),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// إضافة callback لمعالجة مخصصة
  static void addErrorCallback(void Function(ErrorInfo) callback) {
    _errorCallbacks.add(callback);
  }

  /// إزالة callback
  static void removeErrorCallback(void Function(ErrorInfo) callback) {
    _errorCallbacks.remove(callback);
  }

  /// إشعار جميع الـ callbacks
  static void _notifyCallbacks(ErrorInfo errorInfo) {
    for (final void Function(ErrorInfo p1) callback in _errorCallbacks) {
      try {
        callback(errorInfo);
      } on Exception catch (e) {
        _logger.warning('خطأ في callback: $e');
      }
    }
  }

  /// الحصول على إحصائيات الأخطاء
  static Map<String, dynamic> getErrorStatistics() => <String, dynamic>{
        'totalErrors': _errorCounts.values.fold(0, (int a, int b) => a + b),
        'errorsByType': Map.fromEntries(
          _errorCounts.entries.map((MapEntry<ErrorType, int> e) =>
              MapEntry(e.key.toString(), e.value)),
        ),
        'errorsBySeverity': Map.fromEntries(
          _severityCounts.entries.map((MapEntry<ErrorSeverity, int> e) =>
              MapEntry(e.key.toString(), e.value)),
        ),
        'pendingErrors': _pendingErrors.length,
      };

  /// مسح الإحصائيات
  static void clearStatistics() {
    _errorCounts.clear();
    _severityCounts.clear();
    _logger.info('تم مسح إحصائيات الأخطاء');
  }

  /// تهيئة خدمة معالجة الأخطاء
  static void initialize() {
    _logger.info('تم تهيئة خدمة معالجة الأخطاء');

    // إعداد معالج الأخطاء العام
    FlutterError.onError = (FlutterErrorDetails details) {
      handleError(
        details.exception,
        message: 'Flutter Error',
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        stackTrace: details.stack.toString(),
        context: <String, dynamic>{
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };

    // إعداد معالج أخطاء المنطقة
    runZonedGuarded(() {}, (Object error, StackTrace stack) {
      handleError(
        error,
        message: 'Zone Error',
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        stackTrace: stack.toString(),
      );
    });
  }

  /// تنظيف خدمة معالجة الأخطاء
  static void dispose() {
    _errorCallbacks.clear();
    _pendingErrors.clear();
    _logger.info('تم تنظيف خدمة معالجة الأخطاء');
  }

  // ========== دوال مساعدة للتوافق مع الكود الحالي ==========

  /// تسجيل خطأ جديد مع callback لعرض الرسائل
  static Future<void> handleErrorWithCallback(
    Object error, {
    String? message,
    ErrorType? type,
    ErrorSeverity severity = ErrorSeverity.medium,
    String? stackTrace,
    Map<String, dynamic>? contextData,
    String? userAction,
    bool showToUser = true,
    void Function(String)? showUserMessage,
  }) async {
    await handleError(
      error,
      message: message,
      type: type,
      severity: severity,
      stackTrace: stackTrace,
      context: contextData,
      userAction: userAction,
      showToUser: showToUser,
      showUserMessage: showUserMessage,
    );
  }
}

/// مساعد لتسهيل معالجة الأخطاء
class ErrorHelper {
  /// تنفيذ عملية مع معالجة آمنة للأخطاء
  static Future<T?> safeExecute<T>(
    Future<T> Function() operation, {
    String? userAction,
    ErrorSeverity severity = ErrorSeverity.medium,
    void Function(String)? showUserMessage,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } on Exception catch (error, stackTrace) {
      // معالجة خاصة بـ Windows للأخطاء الشائعة
      if (Platform.isWindows) {
        debugPrint('🪟 Windows: معالجة الخطأ - ${error.toString()}');

        // التحقق من أخطاء BuildContext
        if (error.toString().contains('context') ||
            error.toString().contains('widget') ||
            error.toString().contains('mounted')) {
          debugPrint('⚠️ Windows: خطأ BuildContext - تم تجاهل المعالجة');
          return null;
        }
      }

      await ErrorHandlerService.handleError(
        error,
        severity: severity,
        stackTrace: stackTrace.toString(),
        userAction: userAction,
        showUserMessage: showUserMessage,
        showToUser: showError,
      );
      return null;
    }
  }

  /// تنفيذ عملية متزامنة مع معالجة آمنة للأخطاء
  static T? safeExecuteSync<T>(
    T Function() operation, {
    String? userAction,
    ErrorSeverity severity = ErrorSeverity.medium,
    void Function(String)? showUserMessage,
    bool showError = true,
  }) {
    try {
      return operation();
    } on Exception catch (error, stackTrace) {
      ErrorHandlerService.handleError(
        error,
        severity: severity,
        stackTrace: stackTrace.toString(),
        userAction: userAction,
        showUserMessage: showUserMessage,
        showToUser: showError,
      );
      return null;
    }
  }
}
