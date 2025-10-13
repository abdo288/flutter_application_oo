import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../repositories/unified_repository.dart';
import '../services/error_handler_service.dart';
import '../services/local_notification_service.dart';
import '../services/local_sales_service.dart';
import '../services/server_timestamp_service.dart';
import '../services/sync_coordination_service.dart';

/// مدير المزامنة - مسؤول عن معالجة طابور العمليات غير المزامنة
class SyncManager {
  factory SyncManager() => _instance;
  SyncManager._internal();
  static final SyncManager _instance = SyncManager._internal();
  static SyncManager get instance => _instance;

  final AppDatabase _localDb = AppDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== متغيرات المزامنة ==========

  StreamSubscription<List<ConnectivityResult>>? _connectivityListener;
  Timer? _syncTimer;
  bool _isProcessing = false;
  bool _isOnline = false;

  // ========== إعدادات المزامنة ==========

  /// فاصل فحص العمليات غير المزامنة (بالثواني) - تحسين لتقليل استهلاك الذاكرة
  static const Duration syncCheckInterval = Duration(minutes: 2);

  /// الحد الأقصى لعدد المحاولات
  static const int maxRetryCount = 3;

  // ========== بدء وإيقاف المزامنة ==========

  /// بدء المزامنة التلقائية (alias for start)
  Future<void> startAutoSync() async => start();

  /// إيقاف المزامنة التلقائية (alias for stop)
  Future<void> stopAutoSync() async => stop();

  /// بدء مدير المزامنة
  Future<void> start() async {
    try {
      debugPrint('🚀 بدء مدير المزامنة...');

      // التحقق من الاتصال
      await _checkConnectivity();

      // بدء الاستماع لتغييرات الاتصال
      _connectivityListener = Connectivity().onConnectivityChanged.listen(
            _onConnectivityChanged,
            onError: _onConnectivityError,
          );

      // بدء المزامنة الدورية
      _startPeriodicSync();

      debugPrint('✅ تم بدء مدير المزامنة بنجاح');
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'بدء مدير المزامنة',
        context: <String, dynamic>{
          'operation': 'start',
        },
      );
      debugPrint('❌ خطأ في بدء مدير المزامنة: $e');
    }
  }

  /// إيقاف مدير المزامنة
  Future<void> stop() async {
    try {
      debugPrint('🛑 إيقاف مدير المزامنة...');

      _syncTimer?.cancel();
      _syncTimer = null;
      _connectivityListener?.cancel();
      _connectivityListener = null;

      debugPrint('✅ تم إيقاف مدير المزامنة بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إيقاف مدير المزامنة: $e');
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
    } on Exception catch (e) {
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
      debugPrint('🌐 تم استعادة الاتصال - بدء المزامنة التفاضلية أولاً...');
      _performSyncOnReconnect();
    } else if (!_isOnline && wasOnline) {
      debugPrint('🌐 فقدان الاتصال - إيقاف معالجة العمليات...');
    }
  }

  /// تنفيذ المزامنة عند استعادة الاتصال
  Future<void> _performSyncOnReconnect() async {
    try {
      debugPrint('🔄 بدء المزامنة التفاضلية من Firestore...');

      // استخدام SyncCoordinationService لمنع التضارب
      final bool syncStarted =
          await SyncCoordinationService.startDeltaSync(() async {
        // 1. جلب آخر التحديثات من Firestore أولاً
        await UnifiedRepository().syncFromFirestore();
        debugPrint('✅ تم جلب التحديثات من Firestore');

        // 2. بعد ذلك، معالجة العمليات المحلية المعلقة
        debugPrint('🔄 بدء معالجة العمليات المحلية المعلقة...');
        await _processPendingOperations();
        debugPrint('✅ تمت معالجة العمليات المحلية المعلقة');
      });

      if (!syncStarted) {
        debugPrint('⚠️ تم تخطي المزامنة - عملية مزامنة أخرى قيد التشغيل');
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'المزامنة عند استعادة الاتصال',
        context: <String, dynamic>{
          'operation': '_performSyncOnReconnect',
        },
      );
      debugPrint('❌ خطأ في المزامنة عند استعادة الاتصال: $e');
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
    _syncTimer = Timer.periodic(syncCheckInterval, (_) {
      if (_isOnline && !_isProcessing) {
        _processPendingOperations();
      }
    });
  }

  /// معالجة العمليات المعلقة
  Future<void> _processPendingOperations() async {
    if (_isProcessing || !_isOnline) return;

    // استخدام SyncCoordinationService لمنع التضارب
    final bool syncStarted =
        await SyncCoordinationService.startDeltaSync(() async {
      _isProcessing = true;
      try {
        debugPrint('🔄 معالجة العمليات المعلقة...');

        // الحصول على العمليات غير المعالجة
        List<SyncOperationsTableData> operations;
        try {
          operations = await _localDb.getUnprocessedOperations();
        } catch (e) {
          if (e.toString().contains('connection was closed')) {
            debugPrint(
                '⚠️ فشل في جلب العمليات المعلقة (اتصال قاعدة البيانات مغلق)');
            return;
          }
          rethrow;
        }

        if (operations.isEmpty) {
          debugPrint('✅ لا توجد عمليات معلقة');
          return;
        }

        debugPrint('📋 وجدت ${operations.length} عملية معلقة');

        // معالجة كل عملية
        for (final SyncOperationsTableData operation in operations) {
          await _processOperation(operation);
        }

        debugPrint('✅ تم معالجة جميع العمليات المعلقة');
      } on Exception catch (e) {
        debugPrint('❌ خطأ في معالجة العمليات المعلقة: $e');
      } finally {
        _isProcessing = false;
      }
    });

    if (!syncStarted) {
      debugPrint(
          '⚠️ تم تخطي معالجة العمليات المعلقة - عملية مزامنة أخرى قيد التشغيل');
    }
  }

  /// معالجة عملية واحدة
  Future<void> _processOperation(SyncOperationsTableData operation) async {
    try {
      debugPrint(
          '⚙️ معالجة العملية: ${operation.operation} - ${operation.recordId}');

      // التحقق من عدد المحاولات
      if (operation.retryCount >= maxRetryCount) {
        debugPrint(
            '⚠️ تم تجاوز الحد الأقصى للمحاولات للعملية: ${operation.id}');
        return;
      }

      // تحليل البيانات واستعادة FieldValue
      final Map<String, dynamic> rawData =
          Map<String, dynamic>.from(jsonDecode(operation.data) as Map);
      final Map<String, dynamic> data =
          UnifiedRepository().restoreFieldValues(rawData);

      // تنفيذ العملية حسب النوع
      bool success = false;
      switch (operation.operation) {
        case 'addProduct':
          success = await _syncAddProduct(data);
          break;
        case 'updateProduct':
          success = await _syncUpdateProduct(data);
          break;
        case 'deleteProduct':
          success = await _syncDeleteProduct(data);
          break;
        case 'addInventoryItem':
          success = await _syncAddInventoryItem(data);
          break;
        case 'updateInventoryItem':
          success = await _syncUpdateInventoryItem(data);
          break;
        case 'deleteInventoryItem':
          success = await _syncDeleteInventoryItem(data);
          break;
        case 'addSale':
          success = await _syncAddSale(data);
          break;
        default:
          debugPrint('⚠️ نوع عملية غير معروف: ${operation.operation}');
          return;
      }

      if (success) {
        // تمت العملية بنجاح
        try {
          await _localDb.markOperationAsProcessed(operation.id);
          debugPrint('✅ تمت العملية بنجاح: ${operation.operation}');
        } catch (e) {
          if (e.toString().contains('connection was closed')) {
            debugPrint(
                '⚠️ فشل في تحديث حالة العملية (اتصال قاعدة البيانات مغلق)');
          } else {
            rethrow;
          }
        }
      } else {
        // فشلت العملية - زيادة عدد المحاولات
        try {
          await _localDb.incrementRetryCount(operation.id);
          debugPrint(
              '❌ فشلت العملية، سيتم إعادة المحاولة: ${operation.operation}');

          // إرسال إشعار للمستخدم عند فشل العملية
          await _notifySyncFailure(operation);
        } catch (e) {
          if (e.toString().contains('connection was closed')) {
            debugPrint(
                '⚠️ فشل في زيادة عدد المحاولات (اتصال قاعدة البيانات مغلق)');
          } else {
            rethrow;
          }
        }
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة العملية ${operation.id}: $e');
      try {
        await _localDb.incrementRetryCount(operation.id);
      } catch (retryError) {
        if (retryError.toString().contains('connection was closed')) {
          debugPrint(
              '⚠️ فشل في زيادة عدد المحاولات (اتصال قاعدة البيانات مغلق)');
        } else {
          debugPrint('❌ خطأ إضافي في زيادة عدد المحاولات: $retryError');
        }
      }
    }
  }

  // ========== عمليات المزامنة ==========

  /// مزامنة إضافة منتج
  Future<bool> _syncAddProduct(Map<String, dynamic> data) async {
    try {
      // إضافة last_modified مع serverTimestamp ومعرف التطبيق
      final Map<String, dynamic> dataWithTimestamp =
          Map<String, dynamic>.from(data);

      // إزالة lastModified المحلي واستبداله بـ serverTimestamp
      dataWithTimestamp
        ..remove('lastModified')
        ..remove('needsServerTimestamp')
        ..['last_modified'] = FieldValue.serverTimestamp()
        ..['app_id'] = 'local_app'; // معرف التطبيق المحلي

      await _firestore
          .collection('products')
          .doc(data['id']?.toString() ?? '')
          .set(dataWithTimestamp);
      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة إضافة المنتج: $e');
      return false;
    }
  }

  /// مزامنة تحديث منتج
  Future<bool> _syncUpdateProduct(Map<String, dynamic> data) async {
    try {
      // التحقق من التعارضات
      if (!await _checkProductConflict(data)) {
        return false;
      }

      // إضافة last_modified مع serverTimestamp ومعرف التطبيق
      final Map<String, dynamic> dataWithTimestamp =
          Map<String, dynamic>.from(data);

      // إزالة lastModified المحلي واستبداله بـ serverTimestamp
      dataWithTimestamp
        ..remove('lastModified')
        ..remove('needsServerTimestamp')
        ..['last_modified'] = FieldValue.serverTimestamp()
        ..['app_id'] = 'local_app'; // معرف التطبيق المحلي

      await _firestore
          .collection('products')
          .doc(data['id']?.toString() ?? '')
          .update(dataWithTimestamp);
      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة تحديث المنتج: $e');
      return false;
    }
  }

  /// مزامنة حذف منتج
  Future<bool> _syncDeleteProduct(Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('products')
          .doc(data['id']?.toString() ?? '')
          .delete();
      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة حذف المنتج: $e');
      return false;
    }
  }

  /// مزامنة إضافة عنصر مخزون
  Future<bool> _syncAddInventoryItem(Map<String, dynamic> data) async {
    try {
      // إضافة last_modified مع serverTimestamp ومعرف التطبيق
      final Map<String, dynamic> dataWithTimestamp =
          Map<String, dynamic>.from(data);

      // إزالة lastModified المحلي واستبداله بـ serverTimestamp
      dataWithTimestamp
        ..remove('lastModified')
        ..remove('needsServerTimestamp')
        ..['last_modified'] = FieldValue.serverTimestamp()
        ..['app_id'] = 'local_app'; // معرف التطبيق المحلي

      await _firestore
          .collection('quantities')
          .doc(data['id']?.toString() ?? '')
          .set(dataWithTimestamp);
      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة إضافة عنصر المخزون: $e');
      return false;
    }
  }

  /// مزامنة تحديث عنصر مخزون
  Future<bool> _syncUpdateInventoryItem(Map<String, dynamic> data) async {
    try {
      // التحقق من التعارضات
      if (!await _checkInventoryConflict(data)) {
        return false;
      }

      // إضافة last_modified مع serverTimestamp ومعرف التطبيق
      final Map<String, dynamic> dataWithTimestamp =
          Map<String, dynamic>.from(data);

      // إزالة lastModified المحلي واستبداله بـ serverTimestamp
      dataWithTimestamp
        ..remove('lastModified')
        ..remove('needsServerTimestamp')
        ..['last_modified'] = FieldValue.serverTimestamp()
        ..['app_id'] = 'local_app'; // معرف التطبيق المحلي

      await _firestore
          .collection('quantities')
          .doc(data['id']?.toString() ?? '')
          .update(dataWithTimestamp);
      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة تحديث عنصر المخزون: $e');
      return false;
    }
  }

  /// مزامنة حذف عنصر مخزون
  Future<bool> _syncDeleteInventoryItem(Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('quantities')
          .doc(data['id']?.toString() ?? '')
          .delete();
      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة حذف عنصر المخزون: $e');
      return false;
    }
  }

  // ========== حل التعارضات ==========

  /// التحقق من تعارضات المنتج
  Future<bool> _checkProductConflict(Map<String, dynamic> localData) async {
    try {
      final String productId = localData['id']?.toString() ?? '';
      if (productId.isEmpty) return false;

      // قراءة البيانات من Firestore
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        // المنتج غير موجود في Firestore - يمكن المتابعة
        return true;
      }

      final Map<String, dynamic> firestoreData = doc.data()!;
      final Timestamp? firestoreLastModified =
          firestoreData['last_modified'] as Timestamp?;
      final DateTime? localLastModified =
          DateTime.tryParse(localData['lastModified']?.toString() ?? '');

      if (firestoreLastModified == null || localLastModified == null) {
        // لا يمكن التحقق من التعارض - المتابعة
        return true;
      }

      // التحقق من أن البيانات المحلية أحدث
      if (localLastModified.isAfter(firestoreLastModified.toDate())) {
        debugPrint('✅ البيانات المحلية أحدث - يمكن المتابعة');
        return true;
      } else {
        debugPrint('⚠️ البيانات السحابية أحدث - سيتم تجاهل التحديث المحلي');
        // يمكن إضافة منطق لدمج التغييرات هنا
        return false;
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في التحقق من تعارضات المنتج: $e');
      return true; // في حالة الخطأ، المتابعة
    }
  }

  /// التحقق من تعارضات عنصر المخزون
  Future<bool> _checkInventoryConflict(Map<String, dynamic> localData) async {
    try {
      final String itemId = localData['id']?.toString() ?? '';
      if (itemId.isEmpty) return false;

      // قراءة البيانات من Firestore
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('quantities').doc(itemId).get();

      if (!doc.exists) {
        // عنصر المخزون غير موجود في Firestore - يمكن المتابعة
        return true;
      }

      final Map<String, dynamic> firestoreData = doc.data()!;
      final Timestamp? firestoreLastModified =
          firestoreData['last_modified'] as Timestamp?;
      final DateTime? localLastModified =
          DateTime.tryParse(localData['lastModified']?.toString() ?? '');

      if (firestoreLastModified == null || localLastModified == null) {
        // لا يمكن التحقق من التعارض - المتابعة
        return true;
      }

      // التحقق من أن البيانات المحلية أحدث
      if (localLastModified.isAfter(firestoreLastModified.toDate())) {
        debugPrint('✅ البيانات المحلية أحدث - يمكن المتابعة');
        return true;
      } else {
        debugPrint('⚠️ البيانات السحابية أحدث - سيتم تجاهل التحديث المحلي');
        // يمكن إضافة منطق لدمج التغييرات هنا
        return false;
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في التحقق من تعارضات عنصر المخزون: $e');
      return true; // في حالة الخطأ، المتابعة
    }
  }

  /// مزامنة إضافة عملية بيع
  Future<bool> _syncAddSale(Map<String, dynamic> data) async {
    try {
      debugPrint('🔄 مزامنة إضافة عملية بيع: ${data['id']}');

      // إضافة توقيتات الخادم الموثوقة
      final Map<String, dynamic> saleData =
          ServerTimestampService.createDataWithServerTimestamp(data);

      // حفظ في Firestore
      await _firestore
          .collection('sales')
          .doc(data['id'] as String)
          .set(saleData);

      // تمييز العملية كمزامنة محلياً
      await LocalSalesService().markSaleAsSynced(data['id'] as String);

      debugPrint('✅ تمت مزامنة عملية البيع بنجاح: ${data['id']}');
      return true;
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'مزامنة إضافة عملية بيع',
        context: <String, dynamic>{
          'operation': '_syncAddSale',
          'saleId': data['id'],
          'totalAmount': data['totalAmount'],
        },
      );
      debugPrint('❌ فشل في مزامنة عملية البيع: $e');
      return false;
    }
  }

  /// إرسال إشعار عند فشل المزامنة
  Future<void> _notifySyncFailure(SyncOperationsTableData operation) async {
    try {
      // التحقق من عدد المحاولات لتحديد نوع الإشعار
      if (operation.retryCount >= maxRetryCount - 1) {
        // فشل نهائي - إشعار مهم
        await LocalNotificationService.showInstantNotification(
          title: 'فشل في مزامنة البيانات',
          body:
              'فشلت عملية ${_getOperationDisplayName(operation.operation)}. يرجى التحقق من الاتصال وإعادة المحاولة.',
          payload: 'sync_failure:${operation.id}',
          id: operation.id,
        );
      } else {
        // فشل مؤقت - إشعار أقل أهمية
        await LocalNotificationService.showInstantNotification(
          title: 'مشكلة في المزامنة',
          body:
              'فشلت مؤقتاً في مزامنة ${_getOperationDisplayName(operation.operation)}. سيتم إعادة المحاولة تلقائياً.',
          payload: 'sync_retry:${operation.id}',
          id: operation.id,
        );
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار فشل المزامنة: $e');
    }
  }

  /// الحصول على اسم العملية للعرض
  String _getOperationDisplayName(String operation) {
    switch (operation) {
      case 'addProduct':
        return 'إضافة منتج';
      case 'updateProduct':
        return 'تحديث منتج';
      case 'deleteProduct':
        return 'حذف منتج';
      case 'addInventoryItem':
        return 'إضافة عنصر مخزون';
      case 'updateInventoryItem':
        return 'تحديث عنصر مخزون';
      case 'deleteInventoryItem':
        return 'حذف عنصر مخزون';
      case 'addSale':
        return 'عملية بيع';
      default:
        return 'عملية غير معروفة';
    }
  }

  // ========== معلومات الحالة ==========

  /// الحصول على معلومات المزامنة
  Map<String, dynamic> getSyncInfo() => <String, dynamic>{
        'isProcessing': _isProcessing,
        'isOnline': _isOnline,
        'hasTimer': _syncTimer != null,
        'hasConnectivityListener': _connectivityListener != null,
      };

  // ========== تنظيف الموارد ==========

  /// إغلاق جميع الاتصالات
  Future<void> dispose() async {
    await stop();
    await _localDb.close();
  }
}
