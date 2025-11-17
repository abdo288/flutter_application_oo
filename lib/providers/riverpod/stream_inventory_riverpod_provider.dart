import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:profit_calculator/database/drift_database.dart';
import 'package:profit_calculator/repositories/unified_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/inventory_item.dart';
import '../../providers/auth_riverpod_providers.dart';
import '../../services/app_event_bus.dart';

part 'stream_inventory_riverpod_provider.g.dart';

/// UnifiedRepository Provider
@riverpod
UnifiedRepository unifiedRepository(UnifiedRepositoryRef ref) =>
    UnifiedRepository();

/// State class للمخزون
class InventoryState {
  const InventoryState({
    required this.inventoryItems,
    required this.filteredInventoryItems,
    this.isLoading = false,
    this.isDeleting = false,
    this.errorMessage,
    this.sortBy = 'name',
    this.sortAscending = true,
    this.filterCriteria = '',
    this.filterDate,
    this.isInitialized = false,
  });

  factory InventoryState.initial() => const InventoryState(
        inventoryItems: <InventoryItem>[],
        filteredInventoryItems: <InventoryItem>[],
      );
  final List<InventoryItem> inventoryItems;
  final List<InventoryItem> filteredInventoryItems;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;
  final String sortBy;
  final bool sortAscending;
  final String filterCriteria;
  final DateTime? filterDate;
  final bool isInitialized;

  InventoryState copyWith({
    List<InventoryItem>? inventoryItems,
    List<InventoryItem>? filteredInventoryItems,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    String? sortBy,
    bool? sortAscending,
    String? filterCriteria,
    DateTime? filterDate,
    bool? isInitialized,
  }) =>
      InventoryState(
        inventoryItems: inventoryItems ?? this.inventoryItems,
        filteredInventoryItems:
            filteredInventoryItems ?? this.filteredInventoryItems,
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        errorMessage: errorMessage,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
        filterCriteria: filterCriteria ?? this.filterCriteria,
        filterDate: filterDate ?? this.filterDate,
        isInitialized: isInitialized ?? this.isInitialized,
      );

  int get inventoryCount => inventoryItems.length;

  int getTotalQuantity() => inventoryItems.fold<int>(
      0, (int total, InventoryItem item) => total + item.quantity);

  int getLowStockCount() =>
      inventoryItems.where((InventoryItem item) => item.quantity < 10).length;
}

/// Inventory Stream Provider
@riverpod
Stream<List<InventoryItem>> inventoryStream(InventoryStreamRef ref) {
  final UnifiedRepository repository = ref.watch(unifiedRepositoryProvider);
  return repository.inventoryStream;
}

/// Inventory Controller الرئيسي
@riverpod
class InventoryController extends _$InventoryController {
  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  Timer? _updateDebounceTimer;
  bool _isBatchingUpdates = false;
  int _updateCount = 0;
  DateTime? _lastUpdateTime;

  @override
  InventoryState build() {
    // ✅ التحقق من مفتاح الأمان
    final bool streamsEnabled = ref.watch(userStreamsEnabledProvider);

    // ✅ الاستماع لتغييرات المصادقة
    ref.listen<AuthState>(authStateProvider, (AuthState? previous, AuthState next) {
      if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // تسجيل الخروج تم - إلغاء جميع الاشتراكات
        debugPrint('🚪 تسجيل الخروج تم - إلغاء اشتراكات المخزون');
        _inventorySubscription?.cancel();
        _inventorySubscription = null;
      }
    });

    // ✅ إذا كان المفتاح متوقفاً، لا تقم بإعداد الـ listeners
    if (streamsEnabled) {
      _setupListeners();
    } else {
      debugPrint('🔒 Streams معطلة - تخطي إعداد listeners للمخزون');
    }

    ref.onDispose(() {
      _inventorySubscription?.cancel();
      _updateDebounceTimer?.cancel();
      debugPrint(
          '🗑️ تم تنظيف InventoryController (Firestore subscription مغلق)');
    });

    return InventoryState.initial();
  }

  /// إعداد المستمعين
  /// ✅ تحديث: إضافة الاستماع للأحداث للتحديثات الفورية
  void _setupListeners() {
    final UnifiedRepository repository = ref.read(unifiedRepositoryProvider);

    // ✅ الاستماع لـ stream الموحد مع platform thread safety
    _inventorySubscription = repository.inventoryStream.listen(
      (List<InventoryItem> items) {
        if (!_isBatchingUpdates) {
          _isBatchingUpdates = true;
          // ✅ استخدام Future.microtask لضمان التنفيذ على platform thread
          Future.microtask(() {
            _updateInventory(items);
            _isBatchingUpdates = false;
          });
        }
      },
      onError: (Object error) {
        debugPrint('❌ خطأ في stream المخزون: $error');
        state = state.copyWith(
          errorMessage: error.toString(),
          isLoading: false,
        );
        _isBatchingUpdates = false;

        // ✅ إضافة fallback لتحميل البيانات من قاعدة البيانات المحلية
        _loadInventoryItemsFromLocal();
      },
      cancelOnError: false,
    );

    // ✅ إضافة الاستماع للأحداث للتحديثات الفورية
    _setupEventListeners();

    // ✅ تحميل البيانات من قاعدة البيانات المحلية كـ fallback
    _loadInventoryItemsFromLocal();

    debugPrint('✅ تم إعداد listener للمخزون (Firestore → Local DB → UI)');
  }

  /// إعداد الاستماع للأحداث
  void _setupEventListeners() {
    // الاستماع لأحداث المخزون
    AppEventBus.stream.listen((AppEvent event) {
      switch (event.runtimeType) {
        case InventoryUpdatedEvent:
        case InventoryItemAddedEvent:
        case InventoryItemDeletedEvent:
          debugPrint('🔄 InventoryController: استلام حدث ${event.runtimeType}');
          // إعادة تحميل البيانات من Firestore
          _refreshFromFirestore();
          break;
        case SaleCompletedEvent:
          // تحديث المخزون عند اكتمال عملية البيع
          debugPrint('🔄 InventoryController: حدث اكتمال البيع');
          _refreshFromFirestore();
          break;
      }
    });
  }

  /// إعادة تحميل البيانات من Firestore
  Future<void> _refreshFromFirestore() async {
    try {
      debugPrint(
          '🔄 InventoryController: إعادة تحميل البيانات من Firestore...');
      await ref.read(unifiedRepositoryProvider).syncFromFirestore();
      debugPrint('✅ InventoryController: تم إعادة تحميل البيانات بنجاح');
    } catch (e) {
      debugPrint('❌ InventoryController: خطأ في إعادة تحميل البيانات: $e');
    }
  }

  /// معالجة تحديث المخزون
  void _updateInventory(List<InventoryItem> items) {
    _updateCount++;
    _lastUpdateTime = DateTime.now();

    debugPrint('🔄 تحديث المخزون: ${items.length} عنصر (تحديث #$_updateCount)');

    state = state.copyWith(
      inventoryItems: items,
      isInitialized: true,
      isLoading: false,
    );

    _updateFilteredAndSortedList();
  }

  // ❌ تم إزالة: _handleCrossTabEvent - لم نعد نحتاجه، Firestore يتولى كل شيء

  /// تحديث المخزون يدوياً
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    try {
      debugPrint('🔄 إعادة تحميل بيانات المخزون...');
      await ref.read(unifiedRepositoryProvider).syncFromFirestore();
      debugPrint('✅ تم إعادة تحميل بيانات المخزون بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// إعادة تحميل البيانات من قاعدة البيانات المحلية
  Future<void> _loadInventoryItems() async {
    try {
      final UnifiedRepository repository = ref.read(unifiedRepositoryProvider);
      final List<InventoryTableData> items =
          await repository.localDb.getAllInventoryItems();
      final List<InventoryItem> inventoryItems = items
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
      state = state.copyWith(inventoryItems: inventoryItems);
      _updateFilteredAndSortedList();
      debugPrint('✅ تم إعادة تحميل المخزون: ${inventoryItems.length} عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
    }
  }

  /// تحميل البيانات من قاعدة البيانات المحلية كـ fallback
  Future<void> _loadInventoryItemsFromLocal() async {
    try {
      debugPrint('🔄 تحميل البيانات من قاعدة البيانات المحلية كـ fallback...');
      final UnifiedRepository repository = ref.read(unifiedRepositoryProvider);
      final List<InventoryTableData> items =
          await repository.localDb.getAllInventoryItems();

      if (items.isNotEmpty) {
        final List<InventoryItem> inventoryItems = items
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

        state = state.copyWith(
          inventoryItems: inventoryItems,
          isInitialized: true,
          isLoading: false,
        );
        _updateFilteredAndSortedList();
        debugPrint(
            '✅ تم تحميل المخزون من قاعدة البيانات المحلية: ${inventoryItems.length} عنصر');
      } else {
        debugPrint('⚠️ لا توجد عناصر في قاعدة البيانات المحلية');
        state = state.copyWith(
          inventoryItems: <InventoryItem>[],
          isInitialized: true,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المخزون من قاعدة البيانات المحلية: $e');
      state = state.copyWith(
        inventoryItems: <InventoryItem>[],
        isInitialized: true,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// إضافة عنصر مخزون جديد
  Future<String?> addInventoryItem(InventoryItem item) async {
    try {
      final String itemId =
          item.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final InventoryItem newItem = item.copyWith(id: itemId);

      // Optimistic UI (اختياري - Firestore listener سيحدث UI تلقائياً)
      final List<InventoryItem> updatedItems = <InventoryItem>[
        ...state.inventoryItems,
        newItem
      ];
      state = state.copyWith(inventoryItems: updatedItems);
      _updateFilteredAndSortedList();

      // ✅ حفظ في Firestore مباشرة (Repository يتولى المزامنة)
      await ref.read(unifiedRepositoryProvider).addInventoryItem(newItem);

      // ❌ إزالة: CrossTabSyncService.notifyDataChanged - Firestore يتولى الإشعارات

      debugPrint('✅ تم إضافة عنصر المخزون بنجاح: $itemId');
      return itemId;
    } catch (e) {
      debugPrint('❌ خطأ في إضافة عنصر المخزون: $e');
      state = state.copyWith(errorMessage: e.toString());
      await _loadInventoryItems();
      return null;
    }
  }

  /// تحديث عنصر مخزون موجود
  Future<bool> updateInventoryItem(InventoryItem item) async {
    try {
      final int index =
          state.inventoryItems.indexWhere((InventoryItem i) => i.id == item.id);
      if (index != -1) {
        // Optimistic UI (اختياري - Firestore listener سيحدث UI تلقائياً)
        final List<InventoryItem> updatedItems = <InventoryItem>[
          ...state.inventoryItems
        ];
        updatedItems[index] = item;
        state = state.copyWith(inventoryItems: updatedItems);
        _updateFilteredAndSortedList();
      }

      // ✅ حفظ في Firestore مباشرة (Repository يتولى المزامنة)
      await ref.read(unifiedRepositoryProvider).updateInventoryItem(item);

      // ❌ إزالة: CrossTabSyncService.notifyDataChanged - Firestore يتولى الإشعارات

      debugPrint('✅ تم تحديث عنصر المخزون بنجاح: ${item.id}');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث عنصر المخزون: $e');
      state = state.copyWith(errorMessage: e.toString());
      await _loadInventoryItems();
      return false;
    }
  }

  /// حذف عنصر مخزون
  Future<bool> deleteInventoryItem(String itemId) async {
    try {
      state = state.copyWith(isDeleting: true);

      debugPrint('🗑️ بدء حذف العنصر: $itemId');

      // ✅ حذف من Firestore مباشرة أولاً (Repository يتولى الحذف من Local DB أيضاً)
      await ref.read(unifiedRepositoryProvider).deleteInventoryItem(itemId);

      // بعد الحذف الناجح من Firestore و Local DB، نحدث الـ UI
      final List<InventoryItem> updatedItems = state.inventoryItems
          .where((InventoryItem item) => item.id != itemId)
          .toList();
      state = state.copyWith(inventoryItems: updatedItems, isDeleting: false);
      _updateFilteredAndSortedList();

      debugPrint('✅ تم حذف عنصر المخزون بنجاح: $itemId');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف عنصر المخزون: $e');
      state = state.copyWith(errorMessage: e.toString(), isDeleting: false);

      return false;
    }
  }

  /// حذف عنصر مخزون بالمعرف (للتوافق مع الكود القديم)
  Future<bool> deleteInventoryItemById(String itemId) async =>
      deleteInventoryItem(itemId);

  /// تحميل عناصر المخزون (للتوافق مع الكود القديم)
  Future<void> loadInventoryItems() async {
    debugPrint('ℹ️ InventoryController يحمل البيانات تلقائياً من Stream');
  }

  /// التحقق من وجود باركود
  Future<bool> checkBarcodeExists(String barcode) async =>
      state.inventoryItems.any((InventoryItem item) => item.barcode == barcode);

  /// التحقق من وجود عنصر مخزون بالاسم
  Future<bool> checkIfInventoryNameExists(String name) async =>
      state.inventoryItems.any((InventoryItem item) =>
          item.name.toLowerCase() == name.toLowerCase());

  /// البحث عن عنصر مخزون بالاسم
  InventoryItem? findInventoryItemByName(String name) {
    try {
      return state.inventoryItems
          .firstWhere((InventoryItem item) => item.name == name);
    } catch (e) {
      return null;
    }
  }

  /// البحث عن عنصر مخزون بالمعرف
  InventoryItem? findInventoryItemById(String id) {
    try {
      return state.inventoryItems
          .firstWhere((InventoryItem item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// فلترة عناصر المخزون
  void filterInventoryItems(String criteria) {
    state = state.copyWith(
      filterCriteria: criteria.trim(),
    );

    if (criteria.trim().isEmpty) {
      state = state.copyWith(
          filteredInventoryItems: <InventoryItem>[...state.inventoryItems]);
      return;
    }

    _updateFilteredAndSortedList();
  }

  /// فلترة عناصر المخزون بالتاريخ
  void filterInventoryItemsByDate(DateTime date) {
    state = state.copyWith(
      filterDate: date,
      filterCriteria: '',
    );
    _updateFilteredAndSortedList();
  }

  /// إعادة تعيين الفلاتر
  void resetFilter() {
    state = state.copyWith(
      filterCriteria: '',
    );
    _updateFilteredAndSortedList();
  }

  /// تغيير معيار الفرز
  void setSortBy(String sortBy) {
    if (state.sortBy != sortBy) {
      state = state.copyWith(sortBy: sortBy);
      _updateFilteredAndSortedList();
    }
  }

  /// تغيير اتجاه الفرز
  void setSortAscending(bool ascending) {
    if (state.sortAscending != ascending) {
      state = state.copyWith(sortAscending: ascending);
      _updateFilteredAndSortedList();
    }
  }

  /// الحصول على تسمية الفرز الحالي
  String getSortLabel() {
    switch (state.sortBy) {
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

  /// تحديث الفلترة والفرز
  void _updateFilteredAndSortedList() {
    try {
      List<InventoryItem> filtered = <InventoryItem>[...state.inventoryItems];

      // تطبيق الفلترة
      if (state.filterCriteria.isNotEmpty) {
        filtered = filtered
            .where((InventoryItem item) =>
                _matchesInventorySearch(item, state.filterCriteria))
            .toList();
      } else if (state.filterDate != null) {
        filtered = filtered
            .where((InventoryItem item) =>
                item.addedTime.year == state.filterDate!.year &&
                item.addedTime.month == state.filterDate!.month &&
                item.addedTime.day == state.filterDate!.day)
            .toList();
      }

      // تطبيق الفرز
      filtered.sort((InventoryItem a, InventoryItem b) {
        int comparison;
        switch (state.sortBy) {
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
        return state.sortAscending ? comparison : -comparison;
      });

      state = state.copyWith(filteredInventoryItems: filtered);
      debugPrint(
          '✅ تم تطبيق فلترة المخزون: ${filtered.length} عنصر من أصل ${state.inventoryItems.length}');
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق فلترة المخزون: $e');
      state = state.copyWith(
          filteredInventoryItems: <InventoryItem>[...state.inventoryItems]);
    }
  }

  /// دالة البحث المتقدم
  bool _matchesInventorySearch(InventoryItem item, String searchText) {
    try {
      final String searchLower = searchText.toLowerCase().trim();
      if (searchLower.isEmpty) return true;

      // تحسينات خاصة بـ Windows
      if (Platform.isWindows) {
        if (item.name.toLowerCase().contains(searchLower)) {
          return true;
        }
        if (searchLower.length <= 15 &&
            item.barcode != null &&
            item.barcode!.isNotEmpty &&
            item.barcode!.toLowerCase().contains(searchLower)) {
          return true;
        }
        return false;
      }

      // البحث العادي
      if (item.name.toLowerCase().contains(searchLower)) {
        return true;
      }
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

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('🔄 إعادة تعيين حالة المزامنة للمخزون...');
      await ref.read(unifiedRepositoryProvider).resetSyncState();
      await _loadInventoryItems();
      debugPrint('✅ تم إعادة تعيين حالة المزامنة للمخزون بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// الحصول على إحصائيات Stream
  Map<String, dynamic> getStreamStats() => <String, dynamic>{
        'updateCount': _updateCount,
        'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
        'isBatchingUpdates': _isBatchingUpdates,
        'subscriptions': <String, bool>{
          'inventory': _inventorySubscription != null,
          // ❌ تم إزالة: crossTab subscription
        },
      };
}

/// Helper Providers
@riverpod
List<InventoryItem> filteredInventoryItems(FilteredInventoryItemsRef ref) =>
    ref.watch(inventoryControllerProvider).filteredInventoryItems;

@riverpod
bool inventoryLoadingProvider(InventoryLoadingProviderRef ref) =>
    ref.watch(inventoryControllerProvider).isLoading;

@riverpod
bool inventoryDeletingProvider(InventoryDeletingProviderRef ref) =>
    ref.watch(inventoryControllerProvider).isDeleting;

@riverpod
int inventoryCount(InventoryCountRef ref) =>
    ref.watch(inventoryControllerProvider).inventoryCount;
