import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../repositories/unified_repository.dart';
import '../services/sync_coordination_service.dart';
import '../services/sync_state_service.dart';

/// مدير المزامنة الموحد - يحل محل جميع خدمات المزامنة المتضاربة
class UnifiedSyncManager {
  factory UnifiedSyncManager() => _instance;
  UnifiedSyncManager._internal();
  static final UnifiedSyncManager _instance = UnifiedSyncManager._internal();

  final AppDatabase _localDb = AppDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UnifiedRepository _repository = UnifiedRepository();

  // ========== متغيرات المزامنة ==========

  StreamSubscription<List<ConnectivityResult>>? _connectivityListener;
  Timer? _syncTimer;
  bool _isProcessing = false;
  bool _isOnline = false;
  bool _isInitialized = false;
  String? _currentUserId;
  DateTime? _lastSyncTime;

  // ========== إعدادات المزامنة ==========

  static const Duration syncInterval =
      Duration(minutes: 2); // تقليل تكرار المزامنة
  static const Duration connectivityCheckInterval =
      Duration(minutes: 1); // تقليل فحص الاتصال
  static const int maxRetryCount = 3;

  // ========== التهيئة والإيقاف ==========

  /// تهيئة مدير المزامنة الموحد
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('مدير المزامنة الموحد مهيأ بالفعل للمستخدم: $userId');
      return;
    }

    try {
      debugPrint('🚀 تهيئة مدير المزامنة الموحد للمستخدم: $userId');

      _currentUserId = userId;

      // التحقق من الاتصال
      await _checkConnectivity();

      // بدء الاستماع لتغييرات الاتصال
      _connectivityListener = Connectivity().onConnectivityChanged.listen(
            _onConnectivityChanged,
            onError: _onConnectivityError,
          );

      // بدء المزامنة الدورية
      _startPeriodicSync();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة مدير المزامنة الموحد بنجاح');

      // إضافة تأخير قصير قبل المزامنة الأولية لضمان استقرار النظام
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_isInitialized && _isOnline) {
          performInitialSync();
        }
      });
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة مدير المزامنة الموحد: $e');
      rethrow;
    }
  }

  /// إيقاف مدير المزامنة الموحد
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    try {
      debugPrint('🛑 إيقاف مدير المزامنة الموحد...');

      // ✅ NEW: Process any pending operations before shutdown
      if (_isOnline && !_isProcessing) {
        debugPrint('🔄 معالجة العمليات المعلقة قبل الإيقاف...');
        try {
          await _processPendingOperations();
          debugPrint('✅ تمت معالجة العمليات المعلقة قبل الإيقاف');
        } catch (e) {
          debugPrint('⚠️ خطأ في معالجة العمليات المعلقة: $e');
        }
      }

      _syncTimer?.cancel();
      _syncTimer = null;
      _connectivityListener?.cancel();
      _connectivityListener = null;

      _isInitialized = false;
      _currentUserId = null;

      debugPrint('✅ تم إيقاف مدير المزامنة الموحد بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف مدير المزامنة الموحد: $e');
    }
  }

  /// تنفيذ المزامنة الأولية عند التهيئة
  Future<void> performInitialSync() async {
    if (!_isInitialized || !_isOnline) {
      debugPrint('⚠️ تخطي المزامنة الأولية - غير مهيأ أو غير متصل');
      return;
    }

    try {
      debugPrint('🚀 بدء المزامنة الأولية...');

      // استخدام SyncCoordinationService لمنع التضارب
      final bool syncStarted =
          await SyncCoordinationService.startDeltaSync(() async {
        _isProcessing = true;
        try {
          // تأخير قصير لتقليل الضغط على النظام
          await Future<void>.delayed(const Duration(milliseconds: 200));

          // 1. جلب التحديثات من Firestore أولاً
          await _syncFromFirestore();

          // تأخير قصير بين العمليات
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // 2. رفع التغييرات المحلية إلى Firestore
          await _syncToFirestore();

          _lastSyncTime = DateTime.now();
          debugPrint('✅ تمت المزامنة الأولية بنجاح');
        } catch (e) {
          debugPrint('❌ خطأ في المزامنة الأولية: $e');
        } finally {
          _isProcessing = false;
        }
      });

      if (!syncStarted) {
        debugPrint(
            '⚠️ تم تخطي المزامنة الأولية - عملية مزامنة أخرى قيد التشغيل');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تنفيذ المزامنة الأولية: $e');
    }
  }

  /// تنفيذ مزامنة فورية
  Future<void> performImmediateSync() async {
    if (_isProcessing || !_isOnline) {
      debugPrint(
          '⚠️ لا يمكن تنفيذ المزامنة الفورية - عملية أخرى قيد التشغيل أو غير متصل');
      return;
    }

    final bool syncStarted =
        await SyncCoordinationService.startDeltaSync(() async {
      _isProcessing = true;
      try {
        debugPrint('�� بدء المزامنة الفورية...');

        // معالجة العمليات المعلقة فوراً
        await _processPendingOperations();

        debugPrint('✅ تمت المزامنة الفورية بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في المزامنة الفورية: $e');
      } finally {
        _isProcessing = false;
      }
    });

    if (!syncStarted) {
      debugPrint('⚠️ تم تخطي المزامنة الفورية - عملية مزامنة أخرى قيد التشغيل');
    }
  }

  // ========== إدارة الاتصال ==========

  /// التحقق من حالة الاتصال
  Future<void> _checkConnectivity() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      _isOnline = results.any(
          (ConnectivityResult result) => result != ConnectivityResult.none);
      debugPrint('🌐 حالة الاتصال: ${_isOnline ? "متصل" : "غير متصل"}');
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من الاتصال: $e');
      _isOnline = false;
    }
  }

  /// معالجة تغييرات الاتصال
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final bool wasOnline = _isOnline;
    _isOnline = results
        .any((ConnectivityResult result) => result != ConnectivityResult.none);

    if (_isOnline && !wasOnline) {
      debugPrint('🌐 تم استعادة الاتصال - بدء المزامنة التفاضلية...');
      _performSyncOnReconnect();
    } else if (!_isOnline && wasOnline) {
      debugPrint('🌐 فقدان الاتصال - إيقاف المزامنة...');
    }
  }

  /// معالجة أخطاء الاتصال
  void _onConnectivityError(Object error) {
    debugPrint('❌ خطأ في مستمع الاتصال: $error');
    _isOnline = false;
  }

  // ========== المزامنة الدورية ==========

  /// بدء المزامنة الدورية
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(syncInterval, (_) {
      if (_isOnline && !_isProcessing) {
        _performPeriodicSync();
      }
    });
    debugPrint('⏰ تم بدء المزامنة الدورية كل ${syncInterval.inMinutes} دقيقة');
  }

  /// تنفيذ المزامنة الدورية
  Future<void> _performPeriodicSync() async {
    if (_isProcessing || !_isOnline) return;

    final bool syncStarted =
        await SyncCoordinationService.startDeltaSync(() async {
      _isProcessing = true;
      try {
        debugPrint('🔄 بدء المزامنة الدورية...');

        // تأخير قصير لتقليل الضغط على النظام
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 1. جلب التحديثات من Firestore أولاً
        await _syncFromFirestore();

        // تأخير قصير بين العمليات
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 2. رفع التغييرات المحلية إلى Firestore
        await _syncToFirestore();

        _lastSyncTime = DateTime.now();
        debugPrint('✅ تمت المزامنة الدورية بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في المزامنة الدورية: $e');
      } finally {
        _isProcessing = false;
      }
    });

    if (!syncStarted) {
      debugPrint('⚠️ تم تخطي المزامنة الدورية - عملية مزامنة أخرى قيد التشغيل');
    }
  }

  /// تنفيذ المزامنة عند استعادة الاتصال
  Future<void> _performSyncOnReconnect() async {
    final bool syncStarted =
        await SyncCoordinationService.startDeltaSync(() async {
      try {
        debugPrint('🔄 بدء المزامنة التفاضلية عند استعادة الاتصال...');

        // تأخير قصير لتقليل الضغط على النظام
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 1. جلب التحديثات من Firestore أولاً
        await _syncFromFirestore();

        // تأخير قصير بين العمليات
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 2. رفع التغييرات المحلية إلى Firestore
        await _syncToFirestore();

        _lastSyncTime = DateTime.now();
        debugPrint('✅ تمت المزامنة التفاضلية بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في المزامنة التفاضلية: $e');
      }
    });

    if (!syncStarted) {
      debugPrint(
          '⚠️ تم تخطي المزامنة التفاضلية - عملية مزامنة أخرى قيد التشغيل');
    }
  }

  // ========== مزامنة البيانات ==========

  /// مزامنة البيانات من Firestore إلى قاعدة البيانات المحلية
  Future<void> _syncFromFirestore() async {
    try {
      debugPrint('📥 جلب التحديثات من Firestore...');

      // استخدام UnifiedRepository للمزامنة التفاضلية
      await _repository.syncFromFirestore();

      debugPrint('✅ تم مزامنة البيانات من Firestore بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة البيانات من Firestore: $e');
      // إعادة المحاولة مع مزامنة كاملة في حالة الفشل
      try {
        debugPrint('🔄 محاولة مزامنة كاملة من Firestore...');
        // استخدام نفس الطريقة مع إعادة تعيين وقت المزامنة
        await SyncStateService().resetSyncState();
        await _repository.syncFromFirestore();
        debugPrint('✅ تمت المزامنة الكاملة من Firestore بنجاح');
      } catch (retryError) {
        debugPrint('❌ فشل في المزامنة الكاملة من Firestore: $retryError');
      }
    }
  }

  /// مزامنة البيانات من قاعدة البيانات المحلية إلى Firestore
  Future<void> _syncToFirestore() async {
    try {
      debugPrint('📤 رفع التغييرات المحلية إلى Firestore...');

      // معالجة العمليات المعلقة مباشرة
      await _processPendingOperations();

      debugPrint('✅ تم رفع التغييرات المحلية إلى Firestore بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في رفع التغييرات المحلية إلى Firestore: $e');
      // إعادة المحاولة مع معالجة العمليات المعلقة
      try {
        debugPrint('🔄 محاولة معالجة العمليات المعلقة...');
        await _processPendingOperations();
        debugPrint('✅ تمت معالجة العمليات المعلقة بنجاح');
      } catch (retryError) {
        debugPrint('❌ فشل في معالجة العمليات المعلقة: $retryError');
      }
    }
  }

  /// مزامنة العمليات المعلقة فوراً (للاستدعاء الخارجي)
  Future<void> syncPendingOperations() async {
    if (!_isInitialized) {
      debugPrint('⚠️ مدير المزامنة غير مهيأ');
      return;
    }

    if (!_isOnline) {
      debugPrint('⚠️ لا يوجد اتصال بالإنترنت');
      return;
    }

    if (_isProcessing) {
      debugPrint('⚠️ المزامنة قيد التنفيذ بالفعل');
      return;
    }

    debugPrint('📤 بدء مزامنة العمليات المعلقة فوراً...');
    await _processPendingOperations();
  }

  /// معالجة العمليات المعلقة
  Future<void> _processPendingOperations() async {
    if (_isProcessing || !_isOnline) {
      return;
    }

    _isProcessing = true;

    try {
      debugPrint('🔄 معالجة العمليات المعلقة...');

      final List<SyncOperationsTableData> operations =
          await _localDb.getUnprocessedOperations();

      if (operations.isEmpty) {
        debugPrint('✅ لا توجد عمليات معلقة');
        _isProcessing = false;
        return;
      }

      debugPrint('📋 عدد العمليات المعلقة: ${operations.length}');

      int successCount = 0;
      int failCount = 0;

      for (final SyncOperationsTableData operation in operations) {
        try {
          await _processOperation(operation);
          await _localDb.markOperationAsProcessed(operation.id);
          successCount++;
          debugPrint('✅ تمت معالجة العملية: ${operation.operation}');
        } catch (e) {
          debugPrint('❌ خطأ في معالجة العملية: $e');
          await _localDb.incrementRetryCount(operation.id);
          failCount++;

          if (operation.retryCount >= maxRetryCount) {
            debugPrint('❌ تجاوز الحد الأقصى للمحاولات: ${operation.operation}');
            await _localDb.markOperationAsProcessed(operation.id);
          }
        }
      }

      debugPrint('📊 نتيجة المعالجة: $successCount نجح، $failCount فشل');

      // تنظيف العمليات القديمة
      await _localDb.cleanupProcessedOperations(const Duration(days: 7));
    } catch (e) {
      debugPrint('❌ خطأ في معالجة العمليات المعلقة: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// معالجة عملية واحدة
  Future<void> _processOperation(SyncOperationsTableData operation) async {
    try {
      debugPrint(
          '⚙️ معالجة العملية: ${operation.operation} - ${operation.recordId} (ID: ${operation.id})');

      // التحقق من عدد المحاولات
      if (operation.retryCount >= maxRetryCount) {
        debugPrint(
            '⚠️ تم تجاوز الحد الأقصى للمحاولات للعملية: ${operation.id}');
        return;
      }

      // تحليل البيانات مع معالجة أفضل للأخطاء
      Map<String, dynamic> data;
      try {
        final dynamic decoded = jsonDecode(operation.data);
        data = Map<String, dynamic>.from(decoded as Map);
      } catch (e) {
        debugPrint('❌ خطأ في تحليل بيانات العملية ${operation.id}: $e');
        debugPrint('البيانات الخام: ${operation.data}');
        await _localDb.incrementRetryCount(operation.id);
        return;
      }

      // تنفيذ العملية حسب النوع
      bool success = false;
      switch (operation.operation) {
        case 'addProduct':
        case 'updateProduct':
          success = await _syncProductToFirestore(data);
          break;
        case 'deleteProduct':
          success = await _syncDeleteProductToFirestore(data);
          break;
        case 'addInventoryItem':
        case 'updateInventoryItem':
          success = await _syncInventoryToFirestore(data);
          break;
        case 'deleteInventoryItem':
          success = await _syncDeleteInventoryToFirestore(data);
          break;
        default:
          debugPrint('⚠️ نوع عملية غير معروف: ${operation.operation}');
          return;
      }

      if (success) {
        await _localDb.markOperationAsProcessed(operation.id);
        debugPrint(
            '✅ تمت العملية بنجاح: ${operation.operation} (ID: ${operation.id})');
      } else {
        await _localDb.incrementRetryCount(operation.id);
        debugPrint(
            '❌ فشلت العملية، سيتم إعادة المحاولة: ${operation.operation} (ID: ${operation.id})');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في معالجة العملية ${operation.id}: $e');
      debugPrint('Stack trace: $stackTrace');
      try {
        await _localDb.incrementRetryCount(operation.id);
        debugPrint('✅ تم زيادة عدد المحاولات للعملية ${operation.id}');
      } catch (retryError) {
        debugPrint(
            '❌ خطأ في زيادة عدد المحاولات للعملية ${operation.id}: $retryError');
      }
    }
  }

  // ========== عمليات المزامنة التفصيلية ==========

  /// مزامنة منتج إلى Firestore
  Future<bool> _syncProductToFirestore(Map<String, dynamic> data) async {
    try {
      final Map<String, dynamic> dataWithTimestamp =
          Map<String, dynamic>.from(data);
      dataWithTimestamp
        ..remove('lastModified')
        ..remove('needsServerTimestamp')
        ..['last_modified'] = FieldValue.serverTimestamp()
        ..['app_id'] = 'local_app';

      await _firestore
          .collection('products')
          .doc(data['id']?.toString() ?? '')
          .set(dataWithTimestamp);
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة المنتج إلى Firestore: $e');
      return false;
    }
  }

  /// حذف منتج من Firestore
  Future<bool> _syncDeleteProductToFirestore(Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('products')
          .doc(data['id']?.toString() ?? '')
          .delete();
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتج من Firestore: $e');
      return false;
    }
  }

  /// مزامنة عنصر مخزون إلى Firestore
  Future<bool> _syncInventoryToFirestore(Map<String, dynamic> data) async {
    try {
      // التحقق من وجود المعرف
      final String? id = data['id']?.toString();
      if (id == null || id.isEmpty) {
        debugPrint('❌ خطأ: معرف عنصر المخزون مفقود أو فارغ');
        return false;
      }

      final Map<String, dynamic> dataWithTimestamp =
          Map<String, dynamic>.from(data);
      dataWithTimestamp
        ..remove('lastModified')
        ..remove('needsServerTimestamp')
        ..['last_modified'] = FieldValue.serverTimestamp()
        ..['app_id'] = 'local_app';

      await _firestore.collection('quantities').doc(id).set(dataWithTimestamp);
      debugPrint('✅ تم مزامنة عنصر المخزون إلى Firestore: $id');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة عنصر المخزون إلى Firestore: $e');
      debugPrint('البيانات: $data');
      return false;
    }
  }

  /// حذف عنصر مخزون من Firestore
  Future<bool> _syncDeleteInventoryToFirestore(
      Map<String, dynamic> data) async {
    try {
      // التحقق من وجود المعرف
      final String? id = data['id']?.toString();
      if (id == null || id.isEmpty) {
        debugPrint('❌ خطأ: معرف عنصر المخزون مفقود أو فارغ للحذف');
        return false;
      }

      await _firestore.collection('quantities').doc(id).delete();
      debugPrint('✅ تم حذف عنصر المخزون من Firestore: $id');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف عنصر المخزون من Firestore: $e');
      debugPrint('البيانات: $data');
      return false;
    }
  }

  // ========== معلومات الحالة ==========

  /// الحصول على معلومات المزامنة
  Map<String, dynamic> getSyncInfo() => <String, dynamic>{
        'isInitialized': _isInitialized,
        'isProcessing': _isProcessing,
        'isOnline': _isOnline,
        'lastSyncTime': _lastSyncTime,
        'currentUserId': _currentUserId,
      };

  // ========== تنظيف الموارد ==========

  /// إغلاق جميع الاتصالات
  Future<void> dispose() async {
    await shutdown();
  }
}
