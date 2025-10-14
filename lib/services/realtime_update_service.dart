import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'connectivity_service.dart';
import '../repositories/unified_repository.dart';
import '../models/update_log.dart';
import 'realtime_settings_service.dart';
import 'realtime_notification_service.dart';

/// خدمة التحديثات الفورية عبر المنصات
class RealtimeUpdateService {
  RealtimeUpdateService._();
  static RealtimeUpdateService? _instance;
  static RealtimeUpdateService get instance =>
      _instance ??= RealtimeUpdateService._();

  // ========== متغيرات التحديثات الفورية ==========

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _productsListener;
  StreamSubscription<QuerySnapshot>? _inventoryListener;
  StreamSubscription<List<ConnectivityResult>>? _connectivityListener;
  Timer? _healthCheckTimer;
  Timer? _windowsSyncTimer;

  // Callbacks للتحديثات
  final List<void Function(QuerySnapshot)> _productUpdateCallbacks =
      <void Function(QuerySnapshot<Object?> p1)>[];
  final List<void Function(QuerySnapshot)> _inventoryUpdateCallbacks =
      <void Function(QuerySnapshot<Object?> p1)>[];
  final List<VoidCallback> _connectionStatusCallbacks = <VoidCallback>[];

  bool _isListening = false;
  bool _isOnline = false;
  DateTime? _lastUpdateTime;

  // ========== الميزات الجديدة ==========

  // سجل التحديثات
  final List<UpdateLog> _updateLogs = <UpdateLog>[];
  final StreamController<UpdateLog> _updateLogController =
      StreamController<UpdateLog>.broadcast();

  // إحصائيات الأداء
  int _successCount = 0;
  int _failureCount = 0;
  final List<Duration> _responseTimes = <Duration>[];
  DateTime? _startTime;

  // الخدمات المساعدة
  final RealtimeSettingsService _settingsService =
      RealtimeSettingsService.instance;
  final RealtimeNotificationService _notificationService =
      RealtimeNotificationService.instance;

  // Streams
  Stream<UpdateLog> get updateLogStream => _updateLogController.stream;
  List<UpdateLog> get updateLogs => List.unmodifiable(_updateLogs);

  // ========== إعدادات التحديثات ==========

  /// فاصل فحص صحة الاتصال (بالثواني) - محسن لـ Windows
  static const Duration healthCheckInterval = Duration(seconds: 15);

  /// مهلة انتظار التحديثات (بالثواني)
  static const Duration updateTimeout = Duration(seconds: 30);

  // ========== بدء وإيقاف التحديثات الفورية ==========

  /// بدء التحديثات الفورية
  Future<void> startRealtimeUpdates() async {
    if (_isListening) {
      debugPrint('التحديثات الفورية تعمل بالفعل');
      return;
    }

    try {
      debugPrint('🚀 بدء التحديثات الفورية عبر المنصات...');

      // تهيئة إعدادات Firestore
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // تفعيل الشبكة
      await _db.enableNetwork();
      debugPrint('✅ تم تفعيل شبكة Firestore');

      // التأكد من المزامنة
      await _db.waitForPendingWrites();
      debugPrint('✅ تم تأكيد المزامنة مع Firestore');

      // بدء مستمعي Firestore
      await _setupFirestoreListeners();
      debugPrint('✅ تم إعداد مستمعي Firestore');

      // بدء مستمع الاتصال
      _setupConnectivityListener();
      debugPrint('✅ تم إعداد مستمع الاتصال');

      // بدء فحص صحة الاتصال
      _startHealthCheck();
      debugPrint('✅ تم بدء فحص صحة الاتصال');

      _isListening = true;
      _lastUpdateTime = DateTime.now();

      debugPrint('🎉 تم بدء التحديثات الفورية بنجاح - جاهز للاستقبال!');
    } catch (e) {
      debugPrint('❌ خطأ في بدء التحديثات الفورية: $e');
      rethrow;
    }
  }

  /// إيقاف التحديثات الفورية
  Future<void> stopRealtimeUpdates() async {
    if (!_isListening) {
      debugPrint('التحديثات الفورية غير مفعلة');
      return;
    }

    try {
      debugPrint('إيقاف التحديثات الفورية...');

      // إيقاف مستمعي Firestore
      await _productsListener?.cancel();
      await _inventoryListener?.cancel();
      _productsListener = null;
      _inventoryListener = null;

      // إيقاف مستمع الاتصال
      await _connectivityListener?.cancel();
      _connectivityListener = null;

      // إيقاف فحص صحة الاتصال
      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;

      // إيقاف مؤقت Windows
      _windowsSyncTimer?.cancel();
      _windowsSyncTimer = null;

      _isListening = false;

      debugPrint('تم إيقاف التحديثات الفورية بنجاح');
    } catch (e) {
      debugPrint('خطأ في إيقاف التحديثات الفورية: $e');
    }
  }

  // ========== إعداد مستمعي Firestore ==========

  /// إعداد مستمعي Firestore للتحديثات الفورية
  Future<void> _setupFirestoreListeners() async {
    // حارس Windows - استخدام مزامنة دورية بدلاً من snapshots
    if (Platform.isWindows) {
      debugPrint(
          '🪟 Windows detected - using periodic sync instead of snapshots');
      _startWindowsPeriodicSync();
      return;
    }

    try {
      // استخدام scheduleMicrotask للتأكد من تشغيل العمليات على platform thread
      await Future.microtask(() {
        // مستمع المنتجات
        _productsListener = _db
            .collection('products')
            .orderBy('saved_at', descending: true)
            .snapshots()
            .listen(
          _onProductsUpdate,
          onError: (Object error) {
            debugPrint('خطأ في مستمع المنتجات: $error');
            _handleListenerError('products', error);
          },
        );

        // مستمع المخزون - بدون ترتيب لتجنب مشاكل الفهرس
        _inventoryListener = _db.collection('quantities').snapshots().listen(
          _onInventoryUpdate,
          onError: (Object error) {
            debugPrint('خطأ في مستمع المخزون: $error');
            _handleListenerError('inventory', error);
          },
        );
      });

      debugPrint('تم إعداد مستمعي Firestore بنجاح');
    } catch (e) {
      debugPrint('خطأ في إعداد مستمعي Firestore: $e');
      rethrow;
    }
  }

  /// بدء المزامنة الدورية لـ Windows (محسنة للأداء)
  void _startWindowsPeriodicSync() {
    _windowsSyncTimer?.cancel();
    // تحسين: تقليل التكرار من 3 ثوانٍ إلى 10 ثوانٍ لتحسين الأداء
    _windowsSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!_isOnline) return;
      try {
        debugPrint('🪟 Windows periodic sync running...');
        // استخدام UnifiedRepository للمزامنة مع معالجة أفضل للأخطاء
        final UnifiedRepository repository = UnifiedRepository();
        await repository.syncFromFirestore();
        _lastUpdateTime = DateTime.now();
        debugPrint('✅ Windows periodic sync completed');
      } catch (e) {
        debugPrint('❌ Windows periodic sync error: $e');
        // إعادة المحاولة بعد تأخير أطول في حالة الخطأ
        Future<void>.delayed(const Duration(seconds: 30), () {
          if (_isOnline && _isListening) {
            debugPrint('🔄 إعادة محاولة المزامنة على Windows...');
            _startWindowsPeriodicSync();
          }
        });
      }
    });
    debugPrint(
        '🪟 Windows periodic sync started (every 10 seconds) - optimized for performance');
  }

  /// إعداد مستمع الاتصال
  void _setupConnectivityListener() {
    _connectivityListener = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final bool wasOnline = _isOnline;
        _isOnline = results.any(
            (ConnectivityResult result) => result != ConnectivityResult.none);

        if (!wasOnline && _isOnline) {
          debugPrint('تم استعادة الاتصال - إعادة تشغيل التحديثات الفورية');
          _restartListeners();
        } else if (wasOnline && !_isOnline) {
          debugPrint('فقدان الاتصال - إيقاف التحديثات الفورية مؤقتاً');
        }

        // إشعار callbacks بتغيير حالة الاتصال
        for (final VoidCallback callback in _connectionStatusCallbacks) {
          try {
            callback();
          } catch (e) {
            debugPrint('خطأ في callback حالة الاتصال: $e');
          }
        }
      },
      onError: (Object error) {
        debugPrint('خطأ في مستمع الاتصال: $error');
      },
    );
  }

  // ========== معالجة التحديثات ==========

  /// معالجة تحديثات المنتجات
  void _onProductsUpdate(QuerySnapshot snapshot) {
    final DateTime startTime = DateTime.now();

    try {
      debugPrint('📦 تم استلام تحديث للمنتجات: ${snapshot.docs.length} منتج');
      debugPrint(
          '📦 تفاصيل التحديث: ${snapshot.metadata.isFromCache ? "من التخزين المؤقت" : "من الخادم"}');

      // استخدام scheduleMicrotask لمعالجة التحديثات على platform thread
      scheduleMicrotask(() {
        try {
          _lastUpdateTime = DateTime.now();
          final Duration responseTime = DateTime.now().difference(startTime);

          // إشعار callbacks بتحديث المنتجات مع تمرير QuerySnapshot
          for (final void Function(QuerySnapshot) callback
              in _productUpdateCallbacks) {
            try {
              callback(snapshot);
              debugPrint(
                  '📦 تم تنفيذ callback تحديث المنتجات مع ${snapshot.docs.length} منتج');
            } catch (e) {
              debugPrint('❌ خطأ في callback تحديث المنتجات: $e');
            }
          }

          // Note: Sync is handled by provider callbacks to avoid double-syncing
          // Future<void>.delayed(Duration.zero, () async {
          //   try {
          //     final UnifiedRepository repository = UnifiedRepository();
          //     await repository.syncFromFirestore();
          //     debugPrint('✅ تمت المزامنة الفورية للمنتجات من Firestore');
          //   } catch (e) {
          //     debugPrint('❌ خطأ في المزامنة الفورية للمنتجات: $e');
          //   }
          // });

          // إضافة سجل التحديث
          final UpdateLog updateLog = UpdateLog.create(
            type: 'product',
            action: 'sync',
            message: 'تم استلام ${snapshot.docs.length} منتج جديد',
            data: <String, dynamic>{
              'docCount': snapshot.docs.length,
              'isFromCache': snapshot.metadata.isFromCache,
              'hasPendingWrites': snapshot.metadata.hasPendingWrites,
            },
            responseTime: responseTime,
          );
          _addUpdateLog(updateLog);

          // إرسال إشعار محلي
          _showUpdateNotification('تم تحديث المنتجات',
              'تم استلام ${snapshot.docs.length} منتج جديد');
        } catch (e) {
          debugPrint('❌ خطأ في معالجة تحديث المنتجات على platform thread: $e');

          // إضافة سجل خطأ
          final UpdateLog errorLog = UpdateLog.create(
            type: 'product',
            action: 'sync',
            message: 'خطأ في معالجة تحديث المنتجات',
            isSuccessful: false,
            errorMessage: e.toString(),
            responseTime: DateTime.now().difference(startTime),
          );
          _addUpdateLog(errorLog);
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تحديث المنتجات: $e');

      // إضافة سجل خطأ
      final UpdateLog errorLog = UpdateLog.create(
        type: 'product',
        action: 'sync',
        message: 'خطأ في استلام تحديث المنتجات',
        isSuccessful: false,
        errorMessage: e.toString(),
        responseTime: DateTime.now().difference(startTime),
      );
      _addUpdateLog(errorLog);
    }
  }

  /// معالجة تحديثات المخزون
  void _onInventoryUpdate(QuerySnapshot snapshot) {
    final DateTime startTime = DateTime.now();

    try {
      debugPrint('📦 تم استلام تحديث للمخزون: ${snapshot.docs.length} عنصر');
      debugPrint(
          '📦 تفاصيل التحديث: ${snapshot.metadata.isFromCache ? "من التخزين المؤقت" : "من الخادم"}');

      // استخدام scheduleMicrotask لمعالجة التحديثات على platform thread
      scheduleMicrotask(() {
        try {
          _lastUpdateTime = DateTime.now();
          final Duration responseTime = DateTime.now().difference(startTime);

          // إشعار callbacks بتحديث المخزون مع تمرير QuerySnapshot
          for (final void Function(QuerySnapshot) callback
              in _inventoryUpdateCallbacks) {
            try {
              callback(snapshot);
              debugPrint(
                  '📦 تم تنفيذ callback تحديث المخزون مع ${snapshot.docs.length} عنصر');
            } catch (e) {
              debugPrint('❌ خطأ في callback تحديث المخزون: $e');
            }
          }

          // Note: Sync is handled by provider callbacks to avoid double-syncing
          // Future<void>.delayed(Duration.zero, () async {
          //   try {
          //     final UnifiedRepository repository = UnifiedRepository();
          //     await repository.syncFromFirestore();
          //     debugPrint('✅ تمت المزامنة الفورية للمخزون من Firestore');
          //   } catch (e) {
          //     debugPrint('❌ خطأ في المزامنة الفورية للمخزون: $e');
          //   }
          // });

          // إضافة سجل التحديث
          final UpdateLog updateLog = UpdateLog.create(
            type: 'inventory',
            action: 'sync',
            message: 'تم استلام ${snapshot.docs.length} عنصر مخزون جديد',
            data: <String, dynamic>{
              'docCount': snapshot.docs.length,
              'isFromCache': snapshot.metadata.isFromCache,
              'hasPendingWrites': snapshot.metadata.hasPendingWrites,
            },
            responseTime: responseTime,
          );
          _addUpdateLog(updateLog);

          // إرسال إشعار محلي
          _showUpdateNotification('تم تحديث المخزون',
              'تم استلام ${snapshot.docs.length} عنصر مخزون جديد');
        } catch (e) {
          debugPrint('❌ خطأ في معالجة تحديث المخزون على platform thread: $e');

          // إضافة سجل خطأ
          final UpdateLog errorLog = UpdateLog.create(
            type: 'inventory',
            action: 'sync',
            message: 'خطأ في معالجة تحديث المخزون',
            isSuccessful: false,
            errorMessage: e.toString(),
            responseTime: DateTime.now().difference(startTime),
          );
          _addUpdateLog(errorLog);
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تحديث المخزون: $e');

      // إضافة سجل خطأ
      final UpdateLog errorLog = UpdateLog.create(
        type: 'inventory',
        action: 'sync',
        message: 'خطأ في استلام تحديث المخزون',
        isSuccessful: false,
        errorMessage: e.toString(),
        responseTime: DateTime.now().difference(startTime),
      );
      _addUpdateLog(errorLog);
    }
  }

  /// معالجة أخطاء المستمعين
  void _handleListenerError(String listenerType, Object error) {
    debugPrint('خطأ في مستمع $listenerType: $error');

    // استخدام scheduleMicrotask للتأكد من تشغيل العملية على platform thread
    scheduleMicrotask(() {
      // إعادة تشغيل المستمع بعد 5 ثوانٍ
      Timer(const Duration(seconds: 5), () {
        if (_isListening) {
          debugPrint('إعادة تشغيل مستمع $listenerType...');
          _restartListeners();
        }
      });
    });
  }

  /// إعادة تشغيل المستمعين
  Future<void> _restartListeners() async {
    try {
      // إيقاف المستمعين الحاليين
      await _productsListener?.cancel();
      await _inventoryListener?.cancel();

      // إعادة تشغيلهم
      await _setupFirestoreListeners();

      debugPrint('تم إعادة تشغيل المستمعين بنجاح');
    } catch (e) {
      debugPrint('خطأ في إعادة تشغيل المستمعين: $e');
    }
  }

  // ========== فحص صحة الاتصال ==========

  /// بدء فحص صحة الاتصال
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  /// فحص صحة الاتصال
  Future<void> _performHealthCheck() async {
    try {
      final bool isOnline = ConnectivityService.isConnected;

      if (isOnline != _isOnline) {
        _isOnline = isOnline;
        debugPrint('تغيير حالة الاتصال: ${isOnline ? "متصل" : "غير متصل"}');

        // إشعار callbacks بتغيير حالة الاتصال
        for (final VoidCallback callback in _connectionStatusCallbacks) {
          try {
            callback();
          } catch (e) {
            debugPrint('خطأ في callback فحص الاتصال: $e');
          }
        }
      }

      // فحص آخر وقت تحديث
      if (_lastUpdateTime != null) {
        final Duration timeSinceLastUpdate =
            DateTime.now().difference(_lastUpdateTime!);
        if (timeSinceLastUpdate > updateTimeout) {
          debugPrint(
              'تحذير: لم يتم استلام تحديثات منذ ${timeSinceLastUpdate.inSeconds} ثانية');
        }
      }
    } catch (e) {
      debugPrint('خطأ في فحص صحة الاتصال: $e');
    }
  }

  // ========== إدارة Callbacks ==========

  /// إضافة callback لتحديث المنتجات
  void addProductUpdateCallback(void Function(QuerySnapshot) callback) {
    _productUpdateCallbacks.add(callback);
  }

  /// إزالة callback لتحديث المنتجات
  void removeProductUpdateCallback(void Function(QuerySnapshot) callback) {
    _productUpdateCallbacks.remove(callback);
  }

  /// إضافة callback لتحديث المخزون
  void addInventoryUpdateCallback(void Function(QuerySnapshot) callback) {
    _inventoryUpdateCallbacks.add(callback);
  }

  /// إزالة callback لتحديث المخزون
  void removeInventoryUpdateCallback(void Function(QuerySnapshot) callback) {
    _inventoryUpdateCallbacks.remove(callback);
  }

  /// إضافة callback لحالة الاتصال
  void addConnectionStatusCallback(VoidCallback callback) {
    _connectionStatusCallbacks.add(callback);
  }

  /// إزالة callback لحالة الاتصال
  void removeConnectionStatusCallback(VoidCallback callback) {
    _connectionStatusCallbacks.remove(callback);
  }

  // ========== الإشعارات ==========

  /// إظهار إشعار التحديث
  void _showUpdateNotification(String title, String body) {
    // في التطبيق الحقيقي، يمكن استخدام LocalNotificationService
    debugPrint('إشعار: $title - $body');
  }

  // ========== معلومات الحالة ==========

  /// الحصول على حالة التحديثات الفورية
  bool get isListening => _isListening;

  /// الحصول على حالة الاتصال
  bool get isOnline => _isOnline;

  /// الحصول على آخر وقت تحديث
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// الحصول على عدد callbacks المنتجات
  int get productCallbackCount => _productUpdateCallbacks.length;

  /// الحصول على عدد callbacks المخزون
  int get inventoryCallbackCount => _inventoryUpdateCallbacks.length;

  /// الحصول على عدد callbacks الاتصال
  int get connectionCallbackCount => _connectionStatusCallbacks.length;

  // ========== الميزات الجديدة ==========

  /// إضافة سجل تحديث
  void _addUpdateLog(UpdateLog updateLog) {
    _updateLogs.insert(0, updateLog);

    // الحفاظ على الحد الأقصى للسجل
    final int maxLogSize = _settingsService.currentSettings.maxLogSize;
    if (_updateLogs.length > maxLogSize) {
      _updateLogs.removeRange(maxLogSize, _updateLogs.length);
    }

    _updateLogController.add(updateLog);

    // إرسال إشعار
    _notificationService.notifyUpdate(updateLog);

    // تحديث الإحصائيات
    if (updateLog.isSuccessful) {
      _successCount++;
    } else {
      _failureCount++;
    }

    if (updateLog.responseTime != null) {
      _responseTimes.add(updateLog.responseTime!);
      // الحفاظ على آخر 100 وقت استجابة
      if (_responseTimes.length > 100) {
        _responseTimes.removeAt(0);
      }
    }
  }

  /// الحصول على إحصائيات الأداء
  Map<String, dynamic> getPerformanceStats() {
    final int totalUpdates = _successCount + _failureCount;
    final double successRate =
        totalUpdates > 0 ? (_successCount / totalUpdates) * 100 : 0.0;
    final Duration avgResponseTime = _responseTimes.isNotEmpty
        ? Duration(
            milliseconds: _responseTimes
                    .map((Duration d) => d.inMilliseconds)
                    .reduce((int a, int b) => a + b) ~/
                _responseTimes.length,
          )
        : const Duration();

    return <String, dynamic>{
      'totalUpdates': totalUpdates,
      'successCount': _successCount,
      'failureCount': _failureCount,
      'successRate': successRate,
      'avgResponseTime': avgResponseTime.inMilliseconds,
      'uptime': _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds
          : 0,
      'logSize': _updateLogs.length,
    };
  }

  /// الحصول على إحصائيات التحديثات حسب النوع
  Map<String, dynamic> getUpdateStatsByType() {
    final Map<String, int> stats = <String, int>{};
    final Map<String, int> successStats = <String, int>{};
    final Map<String, int> failureStats = <String, int>{};

    for (final UpdateLog log in _updateLogs) {
      stats[log.type] = (stats[log.type] ?? 0) + 1;
      if (log.isSuccessful) {
        successStats[log.type] = (successStats[log.type] ?? 0) + 1;
      } else {
        failureStats[log.type] = (failureStats[log.type] ?? 0) + 1;
      }
    }

    return <String, dynamic>{
      'total': stats,
      'success': successStats,
      'failure': failureStats,
    };
  }

  /// الحصول على إحصائيات التحديثات حسب الإجراء
  Map<String, dynamic> getUpdateStatsByAction() {
    final Map<String, int> stats = <String, int>{};
    final Map<String, int> successStats = <String, int>{};
    final Map<String, int> failureStats = <String, int>{};

    for (final UpdateLog log in _updateLogs) {
      stats[log.action] = (stats[log.action] ?? 0) + 1;
      if (log.isSuccessful) {
        successStats[log.action] = (successStats[log.action] ?? 0) + 1;
      } else {
        failureStats[log.action] = (failureStats[log.action] ?? 0) + 1;
      }
    }

    return <String, dynamic>{
      'total': stats,
      'success': successStats,
      'failure': failureStats,
    };
  }

  /// تصدير سجل التحديثات
  List<Map<String, dynamic>> exportUpdateLogs() =>
      _updateLogs.map((UpdateLog log) => log.toMap()).toList();

  /// مسح سجل التحديثات
  void clearUpdateLogs() {
    _updateLogs.clear();
    _successCount = 0;
    _failureCount = 0;
    _responseTimes.clear();
    debugPrint('🗑️ تم مسح سجل التحديثات');
  }

  /// الحصول على آخر تحديثات
  List<UpdateLog> getRecentUpdates({int limit = 10}) =>
      _updateLogs.take(limit).toList();

  /// البحث في سجل التحديثات
  List<UpdateLog> searchUpdateLogs({
    String? type,
    String? action,
    bool? isSuccessful,
    DateTime? fromDate,
    DateTime? toDate,
  }) =>
      _updateLogs.where((UpdateLog log) {
        if (type != null && log.type != type) return false;
        if (action != null && log.action != action) return false;
        if (isSuccessful != null && log.isSuccessful != isSuccessful) {
          return false;
        }
        if (fromDate != null && log.timestamp.isBefore(fromDate)) return false;
        if (toDate != null && log.timestamp.isAfter(toDate)) return false;
        return true;
      }).toList();

  /// تهيئة الخدمة
  Future<void> initialize() async {
    try {
      await _settingsService.initialize();
      _startTime = DateTime.now();
      debugPrint('✅ تم تهيئة خدمة التحديثات الفورية');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة التحديثات الفورية: $e');
      rethrow;
    }
  }

  // ========== تنظيف الموارد ==========

  /// تنظيف الموارد
  Future<void> dispose() async {
    await stopRealtimeUpdates();

    _productUpdateCallbacks.clear();
    _inventoryUpdateCallbacks.clear();
    _connectionStatusCallbacks.clear();
    _updateLogs.clear();
    await _updateLogController.close();

    debugPrint('تم تنظيف خدمة التحديثات الفورية');
  }
}
