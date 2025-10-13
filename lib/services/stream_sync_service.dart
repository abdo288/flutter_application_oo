import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../repositories/unified_repository.dart';
import 'error_handler_service.dart';
import 'sync_coordination_service.dart';

/// خدمة المزامنة المحسنة باستخدام Firestore Listeners
class StreamSyncService {
  factory StreamSyncService() => _instance;
  StreamSyncService._internal();
  static final StreamSyncService _instance = StreamSyncService._internal();

  final UnifiedRepository _repository = UnifiedRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== متغيرات المزامنة ==========

  StreamSubscription<QuerySnapshot>? _productsListener;
  StreamSubscription<QuerySnapshot>? _inventoryListener;
  StreamSubscription<List<ConnectivityResult>>? _connectivityListener;
  Timer? _windowsSyncTimer;

  bool _isListening = false;
  bool _isOnline = false;
  DateTime? _lastSyncTime;

  // ========== إعدادات المزامنة ==========

  /// فاصل فحص الاتصال (بالثواني) - تحسين لتقليل استهلاك الذاكرة
  static const Duration connectivityCheckInterval = Duration(minutes: 1);

  // ========== بدء وإيقاف المزامنة ==========

  /// بدء المزامنة الفورية
  Future<void> startRealtimeSync() async {
    if (_isListening) return;

    try {
      debugPrint('🚀 بدء المزامنة الفورية...');

      // التحقق من الاتصال
      await _checkConnectivity();

      // بدء الاستماع لتغييرات الاتصال
      _connectivityListener = Connectivity().onConnectivityChanged.listen(
            _onConnectivityChanged,
            onError: _onConnectivityError,
          );

      // بدء الاستماع لتغييرات Firestore إذا كان متصلاً
      if (_isOnline) {
        await _startFirestoreListeners();

        // تنفيذ مزامنة أولية عند بدء التشغيل
        await _performInitialSyncOnStartup();
      }

      _isListening = true;
      debugPrint('✅ تم بدء المزامنة الفورية بنجاح');
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'بدء المزامنة الفورية في StreamSyncService',
        context: <String, dynamic>{
          'operation': 'startRealtimeSync',
        },
      );
      debugPrint('❌ خطأ في بدء المزامنة الفورية: $e');
    }
  }

  /// تنفيذ مزامنة أولية عند بدء التشغيل
  Future<void> _performInitialSyncOnStartup() async {
    try {
      // التحقق من وجود بيانات محلية
      final bool hasLocalData = await _hasLocalData();

      if (!hasLocalData) {
        debugPrint('🔄 لا توجد بيانات محلية - تنفيذ مزامنة أولية شاملة...');
        await _performInitialSync();
      } else {
        debugPrint('🔄 توجد بيانات محلية - تنفيذ مزامنة تفاضلية...');
        await _syncMissedChanges();
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في المزامنة الأولية عند بدء التشغيل: $e');
      await ErrorHandlerService.handleError(
        e,
        type: ErrorType.sync,
        userAction: 'المزامنة الأولية عند بدء التشغيل',
        context: <String, dynamic>{
          'operation': '_performInitialSyncOnStartup',
        },
      );
    }
  }

  /// التحقق من وجود بيانات محلية
  Future<bool> _hasLocalData() async {
    try {
      // التحقق من وجود منتجات أو عناصر مخزون محلية
      final int productCount = await _repository.localDb.getProductCount();
      final int inventoryCount = await _repository.localDb.getInventoryCount();

      return productCount > 0 || inventoryCount > 0;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في التحقق من البيانات المحلية: $e');
      return false;
    }
  }

  /// إيقاف المزامنة الفورية
  Future<void> stopRealtimeSync() async {
    if (!_isListening) return;

    try {
      debugPrint('🛑 إيقاف المزامنة الفورية...');

      await _stopFirestoreListeners();
      await _connectivityListener?.cancel();
      _connectivityListener = null;

      _isListening = false;
      debugPrint('✅ تم إيقاف المزامنة الفورية بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إيقاف المزامنة الفورية: $e');
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
      debugPrint('🌐 تم استعادة الاتصال - بدء المزامنة التفاضلية...');
      _performDeltaSyncOnReconnect();
    } else if (!_isOnline && wasOnline) {
      debugPrint('🌐 فقدان الاتصال - إيقاف المزامنة...');
      _stopFirestoreListeners();
    }
  }

  /// تنفيذ مزامنة تفاضلية عند استعادة الاتصال
  Future<void> _performDeltaSyncOnReconnect() async {
    // استخدام SyncCoordinationService لمنع حالات السباق
    final bool canStart =
        await SyncCoordinationService.startDeltaSync(() async {
      try {
        // بدء المستمعين أولاً
        await _startFirestoreListeners();

        // تنفيذ مزامنة تفاضلية لجلب التغييرات الفائتة
        if (_lastSyncTime != null) {
          debugPrint('🔄 تنفيذ مزامنة تفاضلية منذ آخر مزامنة: $_lastSyncTime');
          await _syncMissedChanges();
        } else {
          debugPrint('🔄 تنفيذ مزامنة أولية شاملة...');
          await _performInitialSync();
        }

        debugPrint('✅ تمت المزامنة التفاضلية بنجاح');
      } on Exception catch (e) {
        debugPrint('❌ خطأ في المزامنة التفاضلية: $e');
        await ErrorHandlerService.handleError(
          e,
          type: ErrorType.sync,
          severity: ErrorSeverity.high,
          userAction: 'المزامنة التفاضلية عند استعادة الاتصال',
          context: <String, dynamic>{
            'lastSyncTime': _lastSyncTime?.toIso8601String(),
            'operation': '_performDeltaSyncOnReconnect',
          },
        );
        rethrow;
      }
    });

    if (!canStart) {
      debugPrint('⚠️ تم تجاهل المزامنة التفاضلية - مزامنة أخرى قيد التشغيل');
    }
  }

  /// مزامنة التغييرات الفائتة منذ آخر مزامنة
  Future<void> _syncMissedChanges() async {
    try {
      if (_lastSyncTime == null) return;

      debugPrint('🔍 جلب التغييرات منذ: $_lastSyncTime');

      // جلب المنتجات المحدثة منذ آخر مزامنة
      final QuerySnapshot<Map<String, dynamic>> productsSnapshot =
          await _firestore
              .collection('products')
              .where('last_modified',
                  isGreaterThan: Timestamp.fromDate(_lastSyncTime!))
              .get();

      // جلب عناصر المخزون المحدثة منذ آخر مزامنة
      final QuerySnapshot<Map<String, dynamic>> inventorySnapshot =
          await _firestore
              .collection('quantities')
              .where('last_modified',
                  isGreaterThan: Timestamp.fromDate(_lastSyncTime!))
              .get();

      int syncedCount = 0;

      // معالجة المنتجات المحدثة
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in productsSnapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;

          // تجاهل التغييرات المحلية
          if (!_isLocalChange(data)) {
            await _syncProductToLocal(data);
            syncedCount++;
          }
        } catch (e) {
          debugPrint('❌ خطأ في مزامنة منتج ${doc.id}: $e');
        }
      }

      // معالجة عناصر المخزون المحدثة
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in inventorySnapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;

          // تجاهل التغييرات المحلية
          if (!_isLocalChange(data)) {
            await _syncInventoryToLocal(data);
            syncedCount++;
          }
        } catch (e) {
          debugPrint('❌ خطأ في مزامنة عنصر مخزون ${doc.id}: $e');
        }
      }

      debugPrint('✅ تم مزامنة $syncedCount عنصر من التغييرات الفائتة');
      _lastSyncTime = DateTime.now();
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة التغييرات الفائتة: $e');
    }
  }

  /// تنفيذ مزامنة أولية شاملة
  Future<void> _performInitialSync() async {
    try {
      debugPrint('🔄 تنفيذ مزامنة أولية شاملة...');

      // جلب جميع المنتجات
      final QuerySnapshot<Map<String, dynamic>> productsSnapshot =
          await _firestore
              .collection('products')
              .limit(100) // تحديد الحد الأقصى لتجنب الحمل الزائد
              .get();

      // جلب جميع عناصر المخزون
      final QuerySnapshot<Map<String, dynamic>> inventorySnapshot =
          await _firestore
              .collection('quantities')
              .limit(100) // تحديد الحد الأقصى لتجنب الحمل الزائد
              .get();

      int syncedCount = 0;

      // معالجة المنتجات
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in productsSnapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          await _syncProductToLocal(data);
          syncedCount++;
        } catch (e) {
          debugPrint('❌ خطأ في مزامنة منتج ${doc.id}: $e');
        }
      }

      // معالجة عناصر المخزون
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in inventorySnapshot.docs) {
        try {
          final Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          await _syncInventoryToLocal(data);
          syncedCount++;
        } catch (e) {
          debugPrint('❌ خطأ في مزامنة عنصر مخزون ${doc.id}: $e');
        }
      }

      debugPrint('✅ تمت المزامنة الأولية: $syncedCount عنصر');
      _lastSyncTime = DateTime.now();
    } on Exception catch (e) {
      debugPrint('❌ خطأ في المزامنة الأولية: $e');
    }
  }

  /// معالجة أخطاء الاتصال
  void _onConnectivityError(Object error) {
    debugPrint('❌ خطأ في مستمع الاتصال: $error');
    _isOnline = false;
  }

  // ========== Firestore Listeners ==========

  /// بدء الاستماع لتغييرات Firestore
  Future<void> _startFirestoreListeners() async {
    if (!_isOnline) return;

    // حارس Windows - استخدام مزامنة دورية بدلاً من snapshots
    if (Platform.isWindows) {
      debugPrint(
          '🪟 Windows detected - using periodic sync instead of snapshots');
      _startWindowsPeriodicSync();
      return;
    }

    try {
      debugPrint('📡 بدء الاستماع لتغييرات Firestore...');

      // استخدام scheduleMicrotask للتأكد من تشغيل العمليات على platform thread
      await Future.microtask(() {
        // الاستماع لتغييرات المنتجات
        _productsListener =
            _firestore.collection('products').snapshots().listen(
                  _onProductsChanged,
                  onError: _onFirestoreError,
                );

        // الاستماع لتغييرات المخزون
        _inventoryListener =
            _firestore.collection('quantities').snapshots().listen(
                  _onInventoryChanged,
                  onError: _onFirestoreError,
                );
      });

      debugPrint('✅ تم بدء الاستماع لتغييرات Firestore بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في بدء الاستماع لتغييرات Firestore: $e');
    }
  }

  /// إيقاف الاستماع لتغييرات Firestore
  Future<void> _stopFirestoreListeners() async {
    try {
      _productsListener?.cancel();
      _productsListener = null;
      _inventoryListener?.cancel();
      _inventoryListener = null;
      _windowsSyncTimer?.cancel();
      _windowsSyncTimer = null;
      debugPrint('✅ تم إيقاف الاستماع لتغييرات Firestore');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إيقاف الاستماع لتغييرات Firestore: $e');
    }
  }

  /// بدء المزامنة الدورية لـ Windows
  void _startWindowsPeriodicSync() {
    _windowsSyncTimer?.cancel();
    _windowsSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!_isOnline) return;
      try {
        debugPrint('🪟 Windows periodic sync running...');
        await _repository.syncFromFirestore();
        _lastSyncTime = DateTime.now();
        debugPrint('✅ Windows periodic sync completed');
      } catch (e) {
        debugPrint('❌ Windows periodic sync error: $e');
      }
    });
    debugPrint('🪟 Windows periodic sync started (every 3 seconds)');
  }

  // ========== معالجة التغييرات ==========

  /// معالجة تغييرات المنتجات
  void _onProductsChanged(QuerySnapshot snapshot) {
    try {
      debugPrint('📦 تحديث المنتجات: ${snapshot.docs.length} منتج');
      debugPrint('📦 التغييرات: ${snapshot.docChanges.length} تغيير');

      // استخدام scheduleMicrotask لمعالجة التغييرات على platform thread
      scheduleMicrotask(() {
        try {
          // معالجة التغييرات الفردية
          for (final DocumentChange<Object?> change in snapshot.docChanges) {
            if (change.doc.data() is Map<String, dynamic>) {
              _handleProductChange(
                  change as DocumentChange<Map<String, dynamic>>);
            }
          }

          _lastSyncTime = DateTime.now();
        } catch (e) {
          debugPrint(
              '❌ خطأ في معالجة تغييرات المنتجات على platform thread: $e');
        }
      });
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة تغييرات المنتجات: $e');
    }
  }

  /// معالجة تغييرات المخزون
  void _onInventoryChanged(QuerySnapshot snapshot) {
    try {
      debugPrint('📦 تحديث المخزون: ${snapshot.docs.length} عنصر');
      debugPrint('📦 التغييرات: ${snapshot.docChanges.length} تغيير');

      // استخدام scheduleMicrotask لمعالجة التغييرات على platform thread
      scheduleMicrotask(() {
        try {
          // معالجة التغييرات الفردية
          for (final DocumentChange<Object?> change in snapshot.docChanges) {
            if (change.doc.data() is Map<String, dynamic>) {
              _handleInventoryChange(
                  change as DocumentChange<Map<String, dynamic>>);
            }
          }

          _lastSyncTime = DateTime.now();
        } catch (e) {
          debugPrint('❌ خطأ في معالجة تغييرات المخزون على platform thread: $e');
        }
      });
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة تغييرات المخزون: $e');
    }
  }

  /// معالجة تغيير منتج واحد
  void _handleProductChange(DocumentChange<Map<String, dynamic>> change) {
    try {
      // للحذف: لا نحتاج لقراءة البيانات
      if (change.type == DocumentChangeType.removed) {
        debugPrint('🗑️ منتج محذوف: ${change.doc.id}');
        _removeProductFromLocal(change.doc.id);
        return;
      }

      // للإضافة والتعديل: نقرأ البيانات كالمعتاد
      final Map<String, dynamic> data =
          change.doc.data() as Map<String, dynamic>;
      data['id'] = change.doc.id;

      // التحقق من أن التغيير لم يأت من التطبيق نفسه
      if (_isLocalChange(data)) {
        debugPrint('🔄 تغيير محلي - تجاهل التحديث من Firestore');
        return;
      }

      switch (change.type) {
        case DocumentChangeType.added:
          debugPrint('➕ منتج جديد: ${data['name']}');
          _syncProductToLocal(data);
          break;
        case DocumentChangeType.modified:
          debugPrint('✏️ منتج محدث: ${data['name']}');
          _syncProductToLocal(data);
          break;
        case DocumentChangeType.removed:
          // تم معالجته أعلاه
          break;
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة تغيير المنتج: $e');
    }
  }

  /// معالجة تغيير عنصر مخزون واحد
  void _handleInventoryChange(DocumentChange<Map<String, dynamic>> change) {
    try {
      // للحذف: لا نحتاج لقراءة البيانات
      if (change.type == DocumentChangeType.removed) {
        debugPrint('🗑️ عنصر مخزون محذوف: ${change.doc.id}');
        _removeInventoryFromLocal(change.doc.id);
        return;
      }

      // للإضافة والتعديل: نقرأ البيانات كالمعتاد
      final Map<String, dynamic> data =
          change.doc.data() as Map<String, dynamic>;
      data['id'] = change.doc.id;

      // التحقق من أن التغيير لم يأت من التطبيق نفسه
      if (_isLocalChange(data)) {
        debugPrint('🔄 تغيير محلي - تجاهل التحديث من Firestore');
        return;
      }

      switch (change.type) {
        case DocumentChangeType.added:
          debugPrint('➕ عنصر مخزون جديد: ${data['name']}');
          _syncInventoryToLocal(data);
          break;
        case DocumentChangeType.modified:
          debugPrint('✏️ عنصر مخزون محدث: ${data['name']}');
          _syncInventoryToLocal(data);
          break;
        case DocumentChangeType.removed:
          // تم معالجته أعلاه
          break;
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة تغيير عنصر المخزون: $e');
    }
  }

  // ========== مزامنة البيانات المحلية ==========

  /// التحقق من أن التغيير جاء من التطبيق نفسه
  bool _isLocalChange(Map<String, dynamic> data) {
    try {
      // التحقق من وجود معرف التطبيق في البيانات
      final String? appId = data['app_id']?.toString();
      if (appId != null && appId.isNotEmpty) {
        // إذا كان هناك معرف تطبيق، فهذا يعني أن التغيير جاء من تطبيق آخر
        return false;
      }

      // التحقق من وقت آخر تعديل
      final String? lastModified = data['last_modified']?.toString();
      if (lastModified != null) {
        final DateTime? modifiedTime = DateTime.tryParse(lastModified);
        if (modifiedTime != null) {
          // إذا كان التغيير حدث خلال آخر 5 ثوانٍ، فمن المحتمل أن يكون محلياً
          final Duration timeDiff = DateTime.now().difference(modifiedTime);
          if (timeDiff.inSeconds < 5) {
            return true;
          }
        }
      }

      return false;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في التحقق من التغيير المحلي: $e');
      return false;
    }
  }

  /// مزامنة منتج إلى قاعدة البيانات المحلية
  Future<void> _syncProductToLocal(Map<String, dynamic> data) async {
    try {
      // تحديث مباشر في قاعدة البيانات المحلية بدون إضافة إلى طابور المزامنة
      await _repository.localDb.upsertProduct(ProductsTableCompanion(
        id: Value(data['id']?.toString() ?? ''),
        name: Value(data['name']?.toString() ?? ''),
        wholesalePrice: Value(_repository.safeParseInt(data['wholesalePrice'])),
        retailPrice: Value(_repository.safeParseInt(data['retailPrice'])),
        savedAt: Value(
            _repository.safeParseDateTime(data['savedAt']).toIso8601String()),
        isSynced: const Value(true), // تم مزامنته بالفعل
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة المنتج محلياً: $e');
    }
  }

  /// مزامنة عنصر مخزون إلى قاعدة البيانات المحلية
  Future<void> _syncInventoryToLocal(Map<String, dynamic> data) async {
    try {
      // تحديث مباشر في قاعدة البيانات المحلية بدون إضافة إلى طابور المزامنة
      await _repository.localDb.upsertInventoryItem(InventoryTableCompanion(
        id: Value(data['id']?.toString() ?? ''),
        name: Value(data['name']?.toString() ?? ''),
        barcode: Value(data['barcode']?.toString()),
        wholesalePrice: Value(_repository.safeParseInt(data['wholesalePrice'])),
        quantity: Value(_repository.safeParseInt(data['quantity'])),
        originalQuantity:
            Value(_repository.safeParseInt(data['originalQuantity'])),
        addedDate: Value(
            _repository.safeParseDateTime(data['addedDate']).toIso8601String()),
        addedTime: Value(
            _repository.safeParseDateTime(data['addedTime']).toIso8601String()),
        isSynced: const Value(true), // تم مزامنته بالفعل
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } on Exception catch (e) {
      debugPrint('❌ خطأ في مزامنة عنصر المخزون محلياً: $e');
    }
  }

  /// حذف منتج من قاعدة البيانات المحلية
  Future<void> _removeProductFromLocal(String productId) async {
    try {
      final bool exists = await _repository.localDb.productExists(productId);
      if (!exists) {
        debugPrint('⚠️ المنتج غير موجود محلياً: $productId');
        return;
      }

      // حذف مباشر من القاعدة المحلية فقط (بدون مزامنة)
      await (_repository.localDb.delete(_repository.localDb.productsTable)
            ..where(($ProductsTableTable t) => t.id.equals(productId)))
          .go();
      debugPrint('✅ تم حذف المنتج محلياً من Firestore sync: $productId');

      // تسجيل العملية للمتابعة فقط
      await _logDeletion('product', productId);
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتج محلياً: $e');
      await ErrorHandlerService.handleError(
        e,
        type: ErrorType.sync,
        userAction: 'حذف منتج من قاعدة البيانات المحلية',
        context: <String, dynamic>{
          'productId': productId,
          'operation': '_removeProductFromLocal',
        },
      );
    }
  }

  /// حذف عنصر مخزون من قاعدة البيانات المحلية
  Future<void> _removeInventoryFromLocal(String itemId) async {
    try {
      final bool exists = await _repository.localDb.inventoryItemExists(itemId);
      if (!exists) {
        debugPrint('⚠️ عنصر المخزون غير موجود محلياً: $itemId');
        return;
      }

      // حذف مباشر من القاعدة المحلية فقط (بدون مزامنة)
      await _repository.localDb.deleteInventoryItemById(itemId);
      debugPrint('✅ تم حذف عنصر المخزون محلياً من Firestore sync: $itemId');

      // تسجيل العملية للمتابعة فقط
      await _logDeletion('inventory', itemId);
    } catch (e) {
      debugPrint('❌ خطأ في حذف عنصر المخزون محلياً: $e');
      await ErrorHandlerService.handleError(
        e,
        type: ErrorType.sync,
        userAction: 'حذف عنصر مخزون من قاعدة البيانات المحلية',
        context: <String, dynamic>{
          'itemId': itemId,
          'operation': '_removeInventoryFromLocal',
        },
      );
    }
  }

  /// تسجيل عملية الحذف للمتابعة
  Future<void> _logDeletion(String type, String id) async {
    try {
      await _repository.localDb.insertSyncOperation(
        SyncOperationsTableCompanion(
          operation: Value('delete_$type'),
          recordId: Value(id),
          data: Value(
              '{"id": "$id", "type": "$type", "deleted_at": "${DateTime.now().toIso8601String()}"}'),
          retryCount: const Value(0),
          isProcessed: const Value(true), // تمت معالجته بالفعل
          createdAt: Value(DateTime.now().toIso8601String()),
          timestamp: Value(DateTime.now().toIso8601String()),
        ),
      );
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تسجيل عملية الحذف: $e');
    }
  }

  // ========== معالجة الأخطاء ==========

  /// معالجة أخطاء Firestore مع إعادة المحاولة المتزايدة
  void _onFirestoreError(Object error) {
    debugPrint('❌ خطأ في Firestore: $error');

    // تسجيل الخطأ في ErrorHandlerService
    ErrorHandlerService.handleError(
      error,
      type: ErrorType.sync,
      severity: ErrorSeverity.high,
      userAction: 'خطأ في مستمعي Firestore',
      context: <String, dynamic>{
        'isListening': _isListening,
        'isOnline': _isOnline,
        'operation': '_onFirestoreError',
      },
    );

    // إعادة تشغيل المستمعين مع إعادة محاولة متزايدة
    _scheduleFirestoreRestart();
  }

  // متغيرات إعادة المحاولة المتزايدة
  int _firestoreRetryCount = 0;
  static const int _maxFirestoreRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 5);

  /// جدولة إعادة تشغيل مستمعي Firestore مع إعادة محاولة متزايدة
  void _scheduleFirestoreRestart() {
    if (_firestoreRetryCount >= _maxFirestoreRetries) {
      debugPrint('❌ تم تجاوز الحد الأقصى لإعادة المحاولة لمستمعي Firestore');
      _firestoreRetryCount = 0;
      return;
    }

    _firestoreRetryCount++;
    final Duration delay = Duration(
      seconds: _baseRetryDelay.inSeconds * _firestoreRetryCount,
    );

    debugPrint(
        '🔄 إعادة تشغيل مستمعي Firestore بعد $delay (المحاولة $_firestoreRetryCount)');

    // استخدام scheduleMicrotask للتأكد من تشغيل العملية على platform thread
    scheduleMicrotask(() {
      Timer(delay, () {
        if (_isListening && _isOnline) {
          debugPrint('🔄 إعادة تشغيل مستمعي Firestore...');
          _startFirestoreListeners().then((_) {
            // إعادة تعيين عداد المحاولات عند النجاح
            _firestoreRetryCount = 0;
          }).catchError((Object error) {
            debugPrint('❌ فشل في إعادة تشغيل مستمعي Firestore: $error');
            _scheduleFirestoreRestart();
          });
        }
      });
    });
  }

  // ========== معلومات الحالة ==========

  /// الحصول على معلومات المزامنة
  Map<String, dynamic> getSyncInfo() => <String, dynamic>{
        'isListening': _isListening,
        'isOnline': _isOnline,
        'lastSyncTime': _lastSyncTime,
        'hasProductsListener': _productsListener != null,
        'hasInventoryListener': _inventoryListener != null,
      };

  // ========== تنظيف الموارد ==========

  /// إغلاق جميع الاتصالات
  Future<void> dispose() async {
    await stopRealtimeSync();
    await _repository.dispose();
  }
}
