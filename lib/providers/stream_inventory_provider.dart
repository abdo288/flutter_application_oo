import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:drift/drift.dart';

import '../database/drift_database.dart';
import '../models/inventory_item.dart';
import '../repositories/unified_repository.dart';
import '../services/realtime_update_service.dart';
import '../services/cross_tab_sync_service.dart';

/// مقدم خدمة المخزون المحسن باستخدام Streams
class StreamInventoryProvider with ChangeNotifier {
  static final UnifiedRepository _repository = UnifiedRepository();

  // ========== متغيرات الحالة ==========

  List<InventoryItem> _inventoryItems = <InventoryItem>[];
  List<InventoryItem> _filteredInventoryItems = <InventoryItem>[];
  // قائمة محسّنة ومخزنة مؤقتاً للفرز والفلترة
  List<InventoryItem> _sortedAndFilteredItems = <InventoryItem>[];
  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorMessage;

  // متغيرات الفرز والفلترة
  String _sortBy = 'name'; // name, quantity, price, date
  bool _sortAscending = true;
  String _filterCriteria = '';
  DateTime? _filterDate;

  // ========== Streams ==========

  StreamSubscription<List<InventoryItem>>? _inventorySubscription;

  // ========== Debouncing for UI Updates ==========

  Timer? _updateDebounceTimer;
  StreamSubscription<SyncEvent>? _crossTabSubscription;

  // ========== Stream Optimization ==========

  bool _isBatchingUpdates = false;
  bool _mounted = true;
  int _updateCount = 0;
  DateTime? _lastUpdateTime;

  // ========== Getters ==========

  List<InventoryItem> get inventoryItems => _inventoryItems;
  // إرجاع القائمة المفرزة مسبقاً مباشرةً لتحسين الأداء
  List<InventoryItem> get filteredInventoryItems => _sortedAndFilteredItems;
  bool get isLoading => _isLoading;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  int get inventoryCount => _inventoryItems.length;

  // Getters للفرز
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Stream optimization getters
  bool get isBatchingUpdates => _isBatchingUpdates;
  bool get mounted => _mounted;
  int get updateCount => _updateCount;

  // ========== تهيئة وإغلاق ==========

  /// مزامنة البيانات في الخلفية
  void _syncInBackground() {
    // استخدام scheduleMicrotask للتأكد من تشغيل العملية على platform thread
    scheduleMicrotask(() {
      // تشغيل المزامنة في الخلفية بدون انتظار
      Future<void>.delayed(const Duration(milliseconds: 200), () async {
        try {
          await _repository.syncFromFirestore();
          debugPrint('✅ تمت مزامنة المخزون من Firestore في الخلفية');
        } catch (e) {
          debugPrint('⚠️ فشل في مزامنة المخزون من Firestore: $e');
        }
      });
    });
  }

  /// تسجيل callbacks مع RealtimeUpdateService للتحديثات الفورية
  void _registerRealtimeCallbacks() {
    try {
      final RealtimeUpdateService realtimeService =
          RealtimeUpdateService.instance;

      // Register inventory update callback
      realtimeService
          .addInventoryUpdateCallback((QuerySnapshot<Object?> snapshot) async {
        debugPrint('🔄 استلام تحديث فوري للمخزون من Firestore');
        try {
          // Force immediate sync from Firestore
          await _repository.syncFromFirestore();
          debugPrint('✅ تمت مزامنة المخزون فورياً من Firestore');

          // ✅ FORCE IMMEDIATE UI UPDATE - bypass debounce with mounted check
          _updateDebounceTimer?.cancel();
          if (_mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_mounted) {
                if (_mounted) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (_mounted) {
                      notifyListeners();
                    }
                  });
                }
                debugPrint('🔔 تم تحديث واجهة المستخدم فوراً');
              }
            });
          }
        } catch (e) {
          debugPrint('❌ خطأ في المزامنة الفورية للمخزون: $e');
        }
      });

      debugPrint('✅ تم تسجيل callbacks التحديثات الفورية للمخزون');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل callbacks التحديثات الفورية: $e');
    }
  }

  /// تسجيل الاستماع لأحداث cross-tab
  void _registerCrossTabListeners() {
    try {
      _crossTabSubscription =
          CrossTabSyncService.events.listen((SyncEvent event) {
        // معالجة أحداث المخزون فقط
        if (event.dataType == 'inventory') {
          debugPrint(
              '🔄 استلام حدث cross-tab للمخزون: ${event.operation}:${event.id}');

          switch (event.operation) {
            case 'add':
              _handleCrossTabInventoryAdd(event);
              break;
            case 'update':
              _handleCrossTabInventoryUpdate(event);
              break;
            case 'delete':
              _handleCrossTabInventoryDelete(event);
              break;
          }
        }
      });

      debugPrint('✅ تم تسجيل الاستماع لأحداث cross-tab للمخزون');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الاستماع لأحداث cross-tab: $e');
    }
  }

  /// معالجة إضافة عنصر مخزون من تبويب آخر
  void _handleCrossTabInventoryAdd(SyncEvent event) {
    try {
      // إعادة تحميل البيانات للتأكد من الحصول على أحدث البيانات
      _loadInventoryItems();
      debugPrint('🔄 تم تحديث المخزون بعد إضافة من تبويب آخر');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة إضافة عنصر المخزون من cross-tab: $e');
    }
  }

  /// معالجة تحديث عنصر مخزون من تبويب آخر
  void _handleCrossTabInventoryUpdate(SyncEvent event) {
    try {
      // إعادة تحميل البيانات للتأكد من الحصول على أحدث البيانات
      _loadInventoryItems();
      debugPrint('🔄 تم تحديث المخزون بعد تحديث من تبويب آخر');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة تحديث عنصر المخزون من cross-tab: $e');
    }
  }

  /// معالجة حذف عنصر مخزون من تبويب آخر
  void _handleCrossTabInventoryDelete(SyncEvent event) {
    try {
      // إزالة العنصر محلياً فوراً
      _inventoryItems.removeWhere((InventoryItem item) => item.id == event.id);
      _updateFilteredAndSortedList();

      // تحديث الواجهة فوراً
      _updateDebounceTimer?.cancel();
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
      debugPrint('🔄 تم حذف العنصر محلياً بعد حذف من تبويب آخر');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة حذف عنصر المخزون من cross-tab: $e');
    }
  }

  /// تهيئة Provider والبدء في الاستماع للـ Stream
  Future<void> initialize() async {
    if (_inventorySubscription != null) {
      debugPrint('ℹ️ StreamInventoryProvider مهيأ بالفعل');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      debugPrint('🚀 بدء تهيئة StreamInventoryProvider...');

      // التحقق من أن قاعدة البيانات متاحة مع timeout قصير
      await _repository.localDb.customSelect('SELECT 1').get().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint(
              '⚠️ انتهت مهلة التحقق من قاعدة البيانات - المتابعة بدون فحص');
          // customSelect(...).get() returns Future<List<QueryRow>>; the onTimeout
          // callback must return the same type. Return an empty List<QueryRow>.
          return <QueryRow>[];
        },
      );
      debugPrint('✅ قاعدة البيانات المحلية متاحة');

      // ✅ Optimized stream subscription with batch updates
      _inventorySubscription = _repository.inventoryStream.listen(
        (List<InventoryItem> inventoryItems) {
          // ✅ Batch Updates with mounted check
          if (!_isBatchingUpdates && _mounted) {
            _isBatchingUpdates = true;

            Future.microtask(() {
              if (_mounted) {
                _onInventoryUpdated(inventoryItems);
                _isBatchingUpdates = false;
              }
            });
          }
        },
        onError: (Object error) => _handleStreamError('inventory', error),
        cancelOnError: false,
        onDone: () {
          debugPrint('ℹ️ inventoryStream تم إغلاقه');
        },
      );

      // محاولة الحصول على البيانات الأولى مع timeout قصير
      try {
        final List<InventoryItem> firstBatch =
            await _repository.inventoryStream.first.timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint(
                '⚠️ انتهت مهلة انتظار الدفعة الأولى - المتابعة بدون بيانات');
            return <InventoryItem>[];
          },
        );
        _onInventoryUpdated(firstBatch);
      } catch (e) {
        debugPrint('⚠️ فشل في الحصول على البيانات الأولى: $e');
        // المتابعة بدون بيانات
        _onInventoryUpdated(<InventoryItem>[]);
      }

      // مزامنة البيانات من Firestore في الخلفية (غير متزامنة)
      _syncInBackground();

      // Register callback with RealtimeUpdateService for immediate updates
      _registerRealtimeCallbacks();

      // ✅ تسجيل الاستماع لأحداث cross-tab
      _registerCrossTabListeners();

      debugPrint('✅ تم تهيئة StreamInventoryProvider بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تهيئة StreamInventoryProvider: $e');
      _setError('خطأ في تهيئة مقدم خدمة المخزون: $e');
      // إعادة تعيين البيانات الفارغة في حالة الخطأ
      _onInventoryUpdated(<InventoryItem>[]);
    } finally {
      _setLoading(false);
    }
  }

  /// معالجة تحديثات المخزون من Stream مع تحسينات الأداء
  void _onInventoryUpdated(List<InventoryItem> updatedItems) {
    try {
      // ✅ Performance monitoring
      _updateCount++;
      _lastUpdateTime = DateTime.now();

      debugPrint(
          '🔄 تحديث المخزون من Stream: ${updatedItems.length} عنصر (تحديث #$_updateCount)');

      // Always update the data to ensure real-time updates
      _inventoryItems = updatedItems;

      // ✅ Optimized UI updates with mounted check
      if (_mounted) {
        _updateDebounceTimer?.cancel();
        _updateDebounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (_mounted) {
            // إعادة تطبيق الفرز والفلترة عند وصول بيانات جديدة
            _updateFilteredAndSortedList();
            debugPrint(
                '✅ تم تحديث المخزون بنجاح: ${_inventoryItems.length} عنصر');
          }
        });
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة تحديثات المخزون: $e');
      _setError('خطأ في تحديث المخزون: $e');
    }
  }

  /// ✅ معالجة أخطاء Stream محسنة
  void _handleStreamError(String streamType, Object error) {
    debugPrint('❌ خطأ في Stream $streamType: $error');

    // إعادة تعيين حالة الباتش
    _isBatchingUpdates = false;

    // معالجة الأخطاء فقط إذا كان Provider ما زال نشطاً
    if (_mounted) {
      _setError('خطأ في Stream $streamType: $error');
    }
  }

  /// إعادة تحميل البيانات مع إجبار المزامنة من Firestore
  Future<void> refresh() async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔄 إعادة تحميل بيانات المخزون...');

      // إجبار المزامنة من Firestore
      await _repository.syncFromFirestore();

      debugPrint('✅ تم إعادة تحميل بيانات المخزون بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
      _setError('خطأ في إعادة تحميل المخزون: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ========== عمليات CRUD ==========

  /// إضافة عنصر مخزون جديد
  Future<String?> addInventoryItem(InventoryItem item) async {
    try {
      // Optimistic UI: أضف العنصر محلياً أولاً
      final String itemId =
          item.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final InventoryItem newItem = item.copyWith(id: itemId);
      _inventoryItems.add(newItem);
      _updateFilteredAndSortedList();

      // ✅ تحديث فوري للواجهة بدون debounce مع mounted check
      _updateDebounceTimer?.cancel();
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            if (_mounted) {
              SchedulerBinding.instance.addPostFrameCallback((_) {
                if (_mounted) {
                  notifyListeners();
                }
              });
            }
            debugPrint('🔄 تم تحديث الواجهة فوراً بعد إضافة عنصر المخزون');
          }
        });
      }

      // إشعار التبويبات الأخرى بالتغيير
      CrossTabSyncService.notifyDataChanged(
        'inventory',
        'add',
        itemId,
        data: <String, dynamic>{
          'name': newItem.name,
          'quantity': newItem.quantity,
        },
      );

      // ثم أضف في قاعدة البيانات
      await _repository.addInventoryItem(newItem);
      debugPrint('✅ تم إضافة عنصر المخزون بنجاح: $itemId');

      return itemId;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إضافة عنصر المخزون: $e');
      _setError('خطأ في إضافة عنصر المخزون: $e');

      // في حالة الخطأ، أعد تحميل البيانات لإزالة العنصر المضاف محلياً
      await _loadInventoryItems();
      return null;
    }
  }

  /// تحديث عنصر مخزون موجود
  Future<bool> updateInventoryItem(InventoryItem item) async {
    try {
      // Optimistic UI: حدث العنصر محلياً أولاً
      final int index =
          _inventoryItems.indexWhere((InventoryItem i) => i.id == item.id);
      if (index != -1) {
        _inventoryItems[index] = item;
        _updateFilteredAndSortedList();
      }

      // ✅ تحديث فوري للواجهة بدون debounce
      _updateDebounceTimer?.cancel();
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
      debugPrint('🔄 تم تحديث الواجهة فوراً بعد تحديث عنصر المخزون');

      // إشعار التبويبات الأخرى بالتغيير
      CrossTabSyncService.notifyDataChanged(
        'inventory',
        'update',
        item.id ?? '',
        data: <String, dynamic>{
          'name': item.name,
          'quantity': item.quantity,
        },
      );

      // ثم حدث في قاعدة البيانات
      await _repository.updateInventoryItem(item);
      debugPrint('✅ تم تحديث عنصر المخزون بنجاح: ${item.id}');

      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تحديث عنصر المخزون: $e');
      _setError('خطأ في تحديث عنصر المخزون: $e');

      // في حالة الخطأ، أعد تحميل البيانات لاستعادة الحالة الأصلية
      await _loadInventoryItems();
      return false;
    }
  }

  /// حذف عنصر مخزون
  Future<bool> deleteInventoryItem(String itemId) async {
    InventoryItem? itemToDelete;
    try {
      // تعيين حالة الحذف
      _isDeleting = true;
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }

      debugPrint('🗑️ بدء حذف عنصر المخزون: $itemId');

      // حفظ نسخة احتياطية من العنصر قبل الحذف
      itemToDelete = _inventoryItems.firstWhere(
        (InventoryItem item) => item.id == itemId,
        orElse: () => throw Exception('العنصر غير موجود'),
      );

      // Optimistic UI: احذف العنصر محلياً أولاً
      _inventoryItems.removeWhere((InventoryItem item) => item.id == itemId);
      _updateFilteredAndSortedList();

      // ✅ تحديث فوري للواجهة بدون debounce
      _updateDebounceTimer?.cancel();
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
      debugPrint('🔄 تم تحديث الواجهة فوراً بعد حذف عنصر المخزون');

      // إشعار التبويبات الأخرى بالتغيير
      CrossTabSyncService.notifyDataChanged(
        'inventory',
        'delete',
        itemId,
      );

      // ثم احذف من قاعدة البيانات
      await _repository.deleteInventoryItem(itemId);
      debugPrint('✅ تم حذف عنصر المخزون بنجاح: $itemId');

      // إعادة تعيين حالة الحذف
      _isDeleting = false;
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }

      return true;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في حذف عنصر المخزون: $e');
      _setError('خطأ في حذف عنصر المخزون: $e');

      // إعادة تعيين حالة الحذف في حالة الخطأ
      _isDeleting = false;
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }

      // في حالة الخطأ، أعد تحميل البيانات لاستعادة العنصر
      try {
        await _loadInventoryItems();
        debugPrint('✅ تم استعادة البيانات بنجاح');
      } catch (reloadError) {
        debugPrint('❌ خطأ في إعادة تحميل البيانات بعد فشل الحذف: $reloadError');
        // إذا فشل إعادة التحميل، أضف العنصر مرة أخرى محلياً
        if (itemToDelete != null) {
          _inventoryItems.add(itemToDelete);
          _updateFilteredAndSortedList();
          if (_mounted) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (_mounted) {
                notifyListeners();
              }
            });
          }
          debugPrint('🔄 تم استعادة العنصر محلياً');
        }
      }
      return false;
    }
  }

  /// حذف عنصر مخزون بالمعرف (للتوافق مع الكود القديم)
  Future<bool> deleteInventoryItemById(String itemId) async =>
      deleteInventoryItem(itemId);

  /// تحميل عناصر المخزون (للتوافق مع الكود القديم)
  Future<void> loadInventoryItems() async {
    // StreamInventoryProvider يحمل البيانات تلقائياً من Stream
    // هذا الطريقة موجودة فقط للتتوافق مع الكود القديم
    debugPrint('ℹ️ StreamInventoryProvider يحمل البيانات تلقائياً من Stream');
  }

  /// إعادة تحميل البيانات من قاعدة البيانات المحلية
  Future<void> _loadInventoryItems() async {
    try {
      final List<InventoryTableData> items =
          await _repository.localDb.getAllInventoryItems();
      _inventoryItems = items
          .map((InventoryTableData item) => InventoryItem(
                id: item.id,
                name: item.name,
                barcode: item.barcode,
                wholesalePrice: item.wholesalePrice,
                retailPrice: item.retailPrice,
                quantity: item.quantity,
                originalQuantity: item.originalQuantity,
                addedDate: DateTime.parse(item.addedDate),
                addedTime: DateTime.parse(item.addedTime),
              ))
          .toList();
      _updateFilteredAndSortedList();
      debugPrint(
          '✅ تم إعادة تحميل عناصر المخزون: ${_inventoryItems.length} عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل عناصر المخزون: $e');
    }
  }

  /// التحقق من وجود باركود
  Future<bool> checkBarcodeExists(String barcode) async {
    try {
      // البحث في البيانات المحلية
      final bool existsLocally =
          _inventoryItems.any((InventoryItem item) => item.barcode == barcode);

      return existsLocally;
    } on Exception catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود الباركود: $e');
      return false;
    }
  }

  /// التحقق من وجود عنصر مخزون بالاسم
  Future<bool> checkIfInventoryNameExists(String name) async {
    try {
      return _inventoryItems.any((InventoryItem item) =>
          item.name.toLowerCase() == name.toLowerCase());
    } on Exception catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود عنصر المخزون: $e');
      return false;
    }
  }

  // ========== عمليات البحث والفلترة والفرز المحسّنة ==========

  /// دالة البحث المتقدم للمخزون - تبحث في الاسم والباركود مع تحسينات Windows
  bool _matchesInventorySearch(InventoryItem item, String searchText) {
    try {
      final String searchLower = searchText.toLowerCase().trim();
      if (searchLower.isEmpty) return true;

      // تحسينات خاصة بـ Windows
      if (Platform.isWindows) {
        // البحث في الاسم أولاً (الأسرع)
        if (item.name.toLowerCase().contains(searchLower)) {
          return true;
        }

        // البحث في الباركود فقط إذا كان النص قصير
        if (searchLower.length <= 15 &&
            item.barcode != null &&
            item.barcode!.isNotEmpty &&
            item.barcode!.toLowerCase().contains(searchLower)) {
          return true;
        }

        return false;
      }

      // البحث العادي للمنصات الأخرى
      // البحث في الاسم
      if (item.name.toLowerCase().contains(searchLower)) {
        return true;
      }

      // البحث في الباركود
      if (item.barcode != null &&
          item.barcode!.isNotEmpty &&
          item.barcode!.toLowerCase().contains(searchLower)) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ خطأ في البحث في المخزون: $e');
      return false;
    }
  }

  /// تحديث الفلترة والفرز وإعلام المستمعين
  void _updateFilteredAndSortedList() {
    try {
      // 1. تطبيق الفلترة المحسنة - يبحث في الاسم والباركود
      if (_filterCriteria.isNotEmpty) {
        _filteredInventoryItems = _inventoryItems
            .where((InventoryItem item) =>
                _matchesInventorySearch(item, _filterCriteria))
            .toList();
      } else if (_filterDate != null) {
        _filteredInventoryItems = _inventoryItems
            .where((InventoryItem item) =>
                item.addedTime.year == _filterDate!.year &&
                item.addedTime.month == _filterDate!.month &&
                item.addedTime.day == _filterDate!.day)
            .toList();
      } else {
        _filteredInventoryItems = List.from(_inventoryItems);
      }

      // 2. تطبيق الفرز على القائمة المفلترة
      _filteredInventoryItems.sort((InventoryItem a, InventoryItem b) {
        int comparison;
        switch (_sortBy) {
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'quantity':
            comparison = a.quantity.compareTo(b.quantity);
            break;
          case 'price':
            comparison = a.wholesalePrice.compareTo(b.wholesalePrice);
            break;
          case 'date':
            comparison = a.addedDate.compareTo(b.addedDate);
            break;
          default:
            comparison = 0;
        }
        return _sortAscending ? comparison : -comparison;
      });

      // 3. تحديث القائمة النهائية وإعلام المستمعين
      _sortedAndFilteredItems = _filteredInventoryItems;
      debugPrint(
          '✅ تم تطبيق فلترة المخزون: ${_filteredInventoryItems.length} عنصر من أصل ${_inventoryItems.length}');
      // تحديث فوري للواجهة
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق فلترة المخزون: $e');
      _filteredInventoryItems = List.from(_inventoryItems);
      _sortedAndFilteredItems = _filteredInventoryItems;
      // تحديث فوري للواجهة حتى في حالة الخطأ
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
    }
  }

  /// فلترة عناصر المخزون بالاسم
  void filterInventoryItems(String criteria) {
    _filterCriteria = criteria.trim();
    _filterDate = null; // إلغاء فلتر التاريخ

    // إذا كان البحث فارغاً، إعادة تعيين القائمة الكاملة
    if (_filterCriteria.isEmpty) {
      _filteredInventoryItems = List.from(_inventoryItems);
      _sortedAndFilteredItems = _filteredInventoryItems;
      // تحديث فوري للواجهة
      if (_mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            notifyListeners();
          }
        });
      }
      return;
    }

    _updateFilteredAndSortedList();
  }

  /// فلترة عناصر المخزون بالتاريخ
  void filterInventoryItemsByDate(DateTime date) {
    _filterDate = date;
    _filterCriteria = ''; // إلغاء فلتر الاسم
    _updateFilteredAndSortedList();
  }

  /// إعادة تعيين الفلاتر
  void resetFilter() {
    _filterCriteria = '';
    _filterDate = null;
    _updateFilteredAndSortedList();
  }

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('🔄 إعادة تعيين حالة المزامنة للمخزون...');

      // إعادة تعيين حالة المزامنة في Repository
      await _repository.resetSyncState();

      // إعادة تحميل البيانات
      await _loadInventoryItems();

      debugPrint('✅ تم إعادة تعيين حالة المزامنة للمخزون بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة للمخزون: $e');
      _setError('خطأ في إعادة تعيين حالة المزامنة: $e');
      rethrow;
    }
  }

  /// تغيير معيار الفرز
  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      _updateFilteredAndSortedList();
    }
  }

  /// تغيير اتجاه الفرز
  void setSortAscending(bool ascending) {
    if (_sortAscending != ascending) {
      _sortAscending = ascending;
      _updateFilteredAndSortedList();
    }
  }

  /// البحث عن عنصر مخزون بالاسم
  InventoryItem? findInventoryItemByName(String name) {
    try {
      return _inventoryItems
          .firstWhere((InventoryItem item) => item.name == name);
    } on Exception catch (e) {
      debugPrint('❌ خطأ في البحث عن عنصر المخزون: $e');
      return null;
    }
  }

  /// البحث عن عنصر مخزون بالمعرف
  InventoryItem? findInventoryItemById(String id) {
    try {
      return _inventoryItems.firstWhere((InventoryItem item) => item.id == id);
    } on Exception catch (e) {
      debugPrint('❌ خطأ في البحث عن عنصر المخزون: $e');
      return null;
    }
  }

  /// الحصول على تسمية الفرز الحالي
  String getSortLabel() {
    switch (_sortBy) {
      case 'name':
        return 'الاسم';
      case 'quantity':
        return 'الكمية';
      case 'price':
        return 'السعر';
      case 'date':
        return 'التاريخ';
      default:
        return 'الاسم';
    }
  }

  // ========== حسابات ==========

  /// حساب إجمالي كمية المخزون
  int getTotalQuantity() => _inventoryItems.fold<int>(
      0, (int total, InventoryItem item) => total + item.quantity);

  /// حساب عدد العناصر منخفضة المخزون (أقل من 10)
  int getLowStockCount() =>
      _inventoryItems.where((InventoryItem item) => item.quantity < 10).length;

  // ========== طرق مساعدة ==========

  void _setLoading(bool loading) {
    _isLoading = loading;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String error) {
    _errorMessage = error;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// ✅ الحصول على إحصائيات Stream
  Map<String, dynamic> getStreamStats() => {
        'updateCount': _updateCount,
        'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
        'isBatchingUpdates': _isBatchingUpdates,
        'mounted': _mounted,
        'activeTimers': {
          'updateDebounce': _updateDebounceTimer?.isActive ?? false,
        },
        'subscriptions': {
          'inventory': _inventorySubscription != null,
          'crossTab': _crossTabSubscription != null,
        }
      };

  @override
  void dispose() {
    // ✅ Mark as unmounted first
    _mounted = false;

    // Cancel all timers and subscriptions
    _inventorySubscription?.cancel();
    _crossTabSubscription?.cancel();
    _updateDebounceTimer?.cancel();

    // Reset state
    _isBatchingUpdates = false;

    debugPrint('🧹 تم إغلاق StreamInventoryProvider');
    super.dispose();
  }
}
