import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../services/app_event_bus.dart';
import '../services/cross_tab_sync_service.dart';
import '../services/error_handler_service.dart';
import '../services/inventory_alert_service.dart';
import '../utils/validators.dart';
import 'riverpod_provider_wrapper.dart';
import 'stream_app_provider.dart';
import 'stream_inventory_provider.dart';

// ========== State Model ==========

/// حالة تبويب المخزون
class InventoryState {
  const InventoryState({
    this.isLoading = false,
    this.isDeleting = false,
    this.showAdvancedOptions = false,
    this.generatedBarcode,
    this.productName = '',
    this.wholesalePrice = '',
    this.retailPrice = '',
    this.quantity = '',
    this.expiryDate = '',
    this.errorMessage,
    this.sortBy = 'name',
    this.sortAscending = true,
    this.filterCriteria = '',
    this.filterDate,
    this.isFormValid = false,
  });

  final bool isLoading;
  final bool isDeleting;
  final bool showAdvancedOptions;
  final String? generatedBarcode;
  final String productName;
  final String wholesalePrice;
  final String retailPrice;
  final String quantity;
  final String expiryDate;
  final String? errorMessage;
  final String sortBy;
  final bool sortAscending;
  final String filterCriteria;
  final DateTime? filterDate;
  final bool isFormValid;

  InventoryState copyWith({
    bool? isLoading,
    bool? isDeleting,
    bool? showAdvancedOptions,
    String? generatedBarcode,
    String? productName,
    String? wholesalePrice,
    String? retailPrice,
    String? quantity,
    String? expiryDate,
    String? errorMessage,
    String? sortBy,
    bool? sortAscending,
    String? filterCriteria,
    DateTime? filterDate,
    bool? isFormValid,
  }) =>
      InventoryState(
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        showAdvancedOptions: showAdvancedOptions ?? this.showAdvancedOptions,
        generatedBarcode: generatedBarcode ?? this.generatedBarcode,
        productName: productName ?? this.productName,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        quantity: quantity ?? this.quantity,
        expiryDate: expiryDate ?? this.expiryDate,
        errorMessage: errorMessage ?? this.errorMessage,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
        filterCriteria: filterCriteria ?? this.filterCriteria,
        filterDate: filterDate ?? this.filterDate,
        isFormValid: isFormValid ?? this.isFormValid,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isDeleting == other.isDeleting &&
          showAdvancedOptions == other.showAdvancedOptions &&
          generatedBarcode == other.generatedBarcode &&
          productName == other.productName &&
          wholesalePrice == other.wholesalePrice &&
          retailPrice == other.retailPrice &&
          quantity == other.quantity &&
          expiryDate == other.expiryDate &&
          errorMessage == other.errorMessage &&
          sortBy == other.sortBy &&
          sortAscending == other.sortAscending &&
          filterCriteria == other.filterCriteria &&
          filterDate == other.filterDate &&
          isFormValid == other.isFormValid;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      isDeleting.hashCode ^
      showAdvancedOptions.hashCode ^
      generatedBarcode.hashCode ^
      productName.hashCode ^
      wholesalePrice.hashCode ^
      retailPrice.hashCode ^
      quantity.hashCode ^
      expiryDate.hashCode ^
      errorMessage.hashCode ^
      sortBy.hashCode ^
      sortAscending.hashCode ^
      filterCriteria.hashCode ^
      filterDate.hashCode ^
      isFormValid.hashCode;
}

// ========== Computed Providers ==========

/// Provider لعناصر المخزون الكاملة
final inventoryItemsProvider = Provider.autoDispose<List<InventoryItem>>(
  (ref) {
    final StreamAppProvider appProvider = ref.watch(streamAppProvider);

    if (!appProvider.isInitialized) {
      return <InventoryItem>[];
    }

    return appProvider.inventoryProvider.inventoryItems;
  },
  dependencies: [streamAppProvider],
);

/// Provider للعناصر المفلترة والمفروزة
final filteredInventoryItemsProvider =
    Provider.autoDispose<List<InventoryItem>>(
  (ref) {
    final List<InventoryItem> items = ref.watch(inventoryItemsProvider);
    final InventoryState state = ref.watch(inventoryStateProvider);

    List<InventoryItem> filtered = List.from(items);

    // تطبيق الفلترة
    if (state.filterCriteria.isNotEmpty) {
      final String searchLower = state.filterCriteria.toLowerCase().trim();
      filtered = filtered.where((InventoryItem item) {
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
      }).toList();
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

    return filtered;
  },
  dependencies: [inventoryItemsProvider, inventoryStateProvider],
);

/// Provider لإحصائيات المخزون
final inventoryStatsProvider = Provider.autoDispose<Map<String, dynamic>>(
  (ref) {
    final List<InventoryItem> items = ref.watch(inventoryItemsProvider);

    final int totalQuantity = items.fold<int>(
        0, (int total, InventoryItem item) => total + item.quantity);
    final int lowStockCount =
        items.where((InventoryItem item) => item.quantity < 10).length;
    final int totalValue = items.fold<int>(
        0,
        (int total, InventoryItem item) =>
            total + (item.wholesalePrice * item.quantity));

    return <String, dynamic>{
      'totalItems': items.length,
      'totalQuantity': totalQuantity,
      'lowStockCount': lowStockCount,
      'totalValue': totalValue,
    };
  },
  dependencies: [inventoryItemsProvider],
);

/// Provider للتحقق من صحة النموذج
final formValidProvider = Provider.autoDispose<bool>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);

    if (state.productName.trim().isEmpty) return false;
    if (state.wholesalePrice.trim().isEmpty) return false;
    if (state.retailPrice.trim().isEmpty) return false;
    if (state.quantity.trim().isEmpty) return false;

    final int? wholesale = int.tryParse(state.wholesalePrice.trim());
    final int? retail = int.tryParse(state.retailPrice.trim());
    final int? qty = int.tryParse(state.quantity.trim());

    if (wholesale == null || retail == null || qty == null) return false;
    if (wholesale <= 0 || retail <= 0 || qty < 0) return false;

    // التحقق من صحة الأسعار
    final String? validationError = Validators.validatePrices(
      state.wholesalePrice.trim(),
      state.retailPrice.trim(),
    );
    return validationError == null;
  },
  dependencies: [inventoryStateProvider],
);

// ========== State Notifier ==========

/// StateNotifier لإدارة حالة تبويب المخزون
class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier(this._ref) : super(const InventoryState()) {
    _initialize();
  }

  final Ref _ref;
  StreamSubscription<AppEvent>? _eventSubscription;
  StreamSubscription<SyncEvent>? _crossTabSubscription;
  Timer? _updateDebounceTimer;

  void _initialize() {
    // تأجيل بدء الاستماع للأحداث حتى بعد انتهاء بناء الـ widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startEventListening();
      _startCrossTabListening();
    });
  }

  void _startEventListening() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      switch (event.runtimeType) {
        case InventoryUpdatedEvent:
          _handleInventoryUpdated(event as InventoryUpdatedEvent);
          break;
        case SaleCompletedEvent:
          _handleSaleCompleted(event as SaleCompletedEvent);
          break;
      }
    });
  }

  void _startCrossTabListening() {
    _crossTabSubscription =
        CrossTabSyncService.events.listen((SyncEvent event) {
      if (event.dataType == 'inventory') {
        debugPrint(
            '🔄 استلام حدث cross-tab للمخزون: ${event.operation}:${event.id}');
        _handleCrossTabEvent(event);
      }
    });
  }

  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    // إعادة تحميل البيانات عند تحديث المخزون
    _refreshInventory();
  }

  void _handleSaleCompleted(SaleCompletedEvent event) {
    // إعادة تحميل البيانات عند إتمام عملية بيع
    _refreshInventory();
  }

  void _handleCrossTabEvent(SyncEvent event) {
    switch (event.operation) {
      case 'add':
      case 'update':
        _refreshInventory();
        break;
      case 'delete':
        // لا حاجة لإعادة تحميل كامل، Stream سيتولى ذلك
        break;
    }
  }

  Future<void> _refreshInventory() async {
    try {
      final StreamAppProvider appProvider = _ref.read(streamAppProvider);
      await appProvider.inventoryProvider.refresh();
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
    }
  }

  /// تهيئة البيانات
  Future<void> initialize() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final StreamAppProvider appProvider = _ref.read(streamAppProvider);

      if (!appProvider.isInitialized) {
        await appProvider.initialize();
      }

      debugPrint('✅ تم تهيئة تبويب المخزون بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة تبويب المخزون: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تهيئة تبويب المخزون: $e',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// تحديث حقل في النموذج
  void updateField(String field, String value) {
    InventoryState newState = state;

    switch (field) {
      case 'productName':
        newState = newState.copyWith(productName: value);
        break;
      case 'wholesalePrice':
        newState = newState.copyWith(wholesalePrice: value);
        break;
      case 'retailPrice':
        newState = newState.copyWith(retailPrice: value);
        break;
      case 'quantity':
        newState = newState.copyWith(quantity: value);
        break;
      case 'expiryDate':
        newState = newState.copyWith(expiryDate: value);
        break;
    }

    // التحقق من صحة النموذج
    final bool isValid = _validateForm(newState);
    state = newState.copyWith(isFormValid: isValid);
  }

  /// التحقق من صحة النموذج
  bool _validateForm(InventoryState state) {
    if (state.productName.trim().isEmpty) return false;
    if (state.wholesalePrice.trim().isEmpty) return false;
    if (state.retailPrice.trim().isEmpty) return false;
    if (state.quantity.trim().isEmpty) return false;

    final int? wholesale = int.tryParse(state.wholesalePrice.trim());
    final int? retail = int.tryParse(state.retailPrice.trim());
    final int? qty = int.tryParse(state.quantity.trim());

    if (wholesale == null || retail == null || qty == null) return false;
    if (wholesale <= 0 || retail <= 0 || qty < 0) return false;

    // التحقق من صحة الأسعار
    final String? validationError = Validators.validatePrices(
      state.wholesalePrice.trim(),
      state.retailPrice.trim(),
    );
    return validationError == null;
  }

  /// تبديل الخيارات المتقدمة
  void toggleAdvancedOptions() {
    state = state.copyWith(showAdvancedOptions: !state.showAdvancedOptions);
  }

  /// توليد باركود
  Future<void> generateBarcode() async {
    final String? barcode = await ErrorHelper.safeExecute(
      () async {
        final String code = await _generateUniqueBarcode();
        return code;
      },
      userAction: 'توليد باركود جديد',
    );

    if (barcode != null) {
      state = state.copyWith(
        generatedBarcode: barcode,
        showAdvancedOptions: true,
      );
    }
  }

  /// توليد باركود فريد
  Future<String> _generateUniqueBarcode() async {
    String candidate() {
      final int micros = DateTime.now().microsecondsSinceEpoch;
      final String base = (micros % 1000000000000).toString().padLeft(12, '0');
      return base;
    }

    String code = candidate();
    int attempts = 0;
    final StreamAppProvider appProvider = _ref.read(streamAppProvider);
    final StreamInventoryProvider inventoryProvider =
        appProvider.inventoryProvider;

    while (await inventoryProvider.checkBarcodeExists(code) && attempts < 5) {
      code = candidate();
      attempts++;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    if (await inventoryProvider.checkBarcodeExists(code)) {
      code =
          '${(int.parse(code.substring(0, 11)) % 100000000000).toString().padLeft(11, '0')}9';
    }

    return code;
  }

  /// مسح باركود
  Future<void> scanBarcode() async {
    final String? barcode = await ErrorHelper.safeExecute(
      () async {
        // سيتم تنفيذ مسح الباركود في UI
        return '';
      },
      userAction: 'مسح باركود',
    );

    if (barcode != null && barcode.isNotEmpty) {
      state = state.copyWith(
        generatedBarcode: barcode,
        showAdvancedOptions: true,
      );
    }
  }

  /// إضافة عنصر مخزون
  Future<bool> addInventoryItem() async {
    if (!state.isFormValid) {
      state = state.copyWith(errorMessage: 'يرجى ملء جميع الحقول المطلوبة');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final String name = Validators.cleanText(state.productName);
      final int wholesalePrice = int.tryParse(state.wholesalePrice.trim()) ?? 0;
      final int retailPrice = int.tryParse(state.retailPrice.trim()) ?? 0;
      final int quantity = int.tryParse(state.quantity.trim()) ?? 0;
      final DateTime? expiryDate = state.expiryDate.trim().isEmpty
          ? null
          : DateTime.tryParse(state.expiryDate.trim());
      final String barcode =
          state.generatedBarcode ?? await _generateUniqueBarcode();

      final InventoryItem item = InventoryItem(
        name: name,
        barcode: barcode,
        wholesalePrice: wholesalePrice,
        retailPrice: retailPrice,
        quantity: quantity,
        originalQuantity: quantity,
        addedDate: DateTime.now(),
        addedTime: DateTime.now(),
        expiryDate: expiryDate,
      );

      if (!item.isValid()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'بيانات العنصر غير صالحة',
        );
        return false;
      }

      final StreamAppProvider appProvider = _ref.read(streamAppProvider);
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;

      // التحقق من وجود الاسم
      final bool nameExists = inventoryProvider.inventoryItems
          .any((InventoryItem i) => i.name == name);
      if (nameExists) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'اسم المنتج موجود بالفعل',
        );
        return false;
      }

      final String? itemId = await inventoryProvider.addInventoryItem(item);
      if (itemId != null) {
        // فحص التنبيهات
        await InventoryAlertService.checkInventoryAlerts(inventoryProvider);

        // إرسال حدث
        AppEventBus.fire(InventoryItemAddedEvent(item, sourceTab: 'Inventory'));

        // إعادة تعيين حالة التحميل ومسح النموذج
        state = state.copyWith(isLoading: false);
        clearForm();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'فشل في إضافة العنصر',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة عنصر المخزون: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في إضافة العنصر: $e',
      );
      return false;
    }
  }

  /// تحديث عنصر مخزون
  Future<bool> updateInventoryItem(InventoryItem item) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final StreamAppProvider appProvider = _ref.read(streamAppProvider);
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;

      final bool success = await inventoryProvider.updateInventoryItem(item);
      if (success) {
        // إرسال حدث
        AppEventBus.fire(InventoryUpdatedEvent(
          'update',
          'Update',
          0,
          item.quantity,
          sourceTab: 'Inventory',
        ));
        // إعادة تعيين حالة التحميل
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'فشل في تحديث العنصر',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث عنصر المخزون: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تحديث العنصر: $e',
      );
      return false;
    }
  }

  /// حذف عنصر مخزون
  Future<bool> deleteInventoryItem(String itemId) async {
    state = state.copyWith(isDeleting: true, errorMessage: null);

    try {
      final StreamAppProvider appProvider = _ref.read(streamAppProvider);
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;

      final bool success = await inventoryProvider.deleteInventoryItem(itemId);
      if (success) {
        // إرسال حدث
        AppEventBus.fire(InventoryUpdatedEvent(
          'delete',
          'Delete',
          0,
          0,
          sourceTab: 'Inventory',
        ));
        // إعادة تعيين حالة الحذف
        state = state.copyWith(isDeleting: false);
        return true;
      } else {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: 'فشل في حذف العنصر',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف عنصر المخزون: $e');
      state = state.copyWith(
        isDeleting: false,
        errorMessage: 'خطأ في حذف العنصر: $e',
      );
      return false;
    }
  }

  /// معالجة العناصر المجمعة
  Future<Map<String, int>> processBulkItems(
      List<Map<String, dynamic>> items) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      int successCount = 0;
      int errorCount = 0;

      for (final Map<String, dynamic> itemData in items) {
        try {
          final String name = itemData['name']?.toString().trim() ?? '';
          final int wholesalePrice =
              int.tryParse(itemData['wholesalePrice']?.toString() ?? '0') ?? 0;
          final int retailPrice =
              int.tryParse(itemData['retailPrice']?.toString() ?? '0') ?? 0;
          final int quantity =
              int.tryParse(itemData['quantity']?.toString() ?? '0') ?? 0;
          final DateTime? expiryDate = itemData['expiryDate'] != null
              ? DateTime.tryParse(itemData['expiryDate'].toString())
              : null;

          if (name.isEmpty ||
              wholesalePrice <= 0 ||
              retailPrice <= 0 ||
              quantity <= 0) {
            errorCount++;
            continue;
          }

          final StreamAppProvider appProvider = _ref.read(streamAppProvider);
          final StreamInventoryProvider inventoryProvider =
              appProvider.inventoryProvider;

          // التحقق من وجود الاسم
          final bool nameExists = inventoryProvider.inventoryItems
              .any((InventoryItem i) => i.name == name);
          if (nameExists) {
            errorCount++;
            continue;
          }

          final String barcode = await _generateUniqueBarcode();
          final InventoryItem item = InventoryItem(
            name: name,
            barcode: barcode,
            wholesalePrice: wholesalePrice,
            retailPrice: retailPrice,
            quantity: quantity,
            originalQuantity: quantity,
            addedDate: DateTime.now(),
            addedTime: DateTime.now(),
            expiryDate: expiryDate,
          );

          if (item.isValid()) {
            final String? itemId =
                await inventoryProvider.addInventoryItem(item);
            if (itemId != null) {
              successCount++;
            } else {
              errorCount++;
            }
          } else {
            errorCount++;
          }
        } catch (e) {
          errorCount++;
        }
      }

      // فحص التنبيهات
      final StreamAppProvider appProvider = _ref.read(streamAppProvider);
      await InventoryAlertService.checkInventoryAlerts(
          appProvider.inventoryProvider);

      return <String, int>{
        'successCount': successCount,
        'errorCount': errorCount,
      };
    } catch (e) {
      debugPrint('❌ خطأ في معالجة العناصر المجمعة: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في معالجة العناصر المجمعة: $e',
      );
      return <String, int>{'successCount': 0, 'errorCount': items.length};
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// مسح النموذج
  void clearForm() {
    state = state.copyWith(
      productName: '',
      wholesalePrice: '',
      retailPrice: '',
      quantity: '',
      expiryDate: '',
      generatedBarcode: null,
      showAdvancedOptions: false,
      isFormValid: false,
      errorMessage: null,
    );
  }

  /// تعيين الفرز
  void setSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, sortAscending: ascending);
  }

  /// تعيين الفلتر
  void setFilter(String criteria) {
    state = state.copyWith(filterCriteria: criteria, filterDate: null);
  }

  /// تعيين فلتر التاريخ
  void setDateFilter(DateTime date) {
    state = state.copyWith(filterDate: date, filterCriteria: '');
  }

  /// إعادة تعيين الفلتر
  void resetFilter() {
    state = state.copyWith(filterCriteria: '', filterDate: null);
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _crossTabSubscription?.cancel();
    _updateDebounceTimer?.cancel();
    super.dispose();
  }
}

// ========== Providers ==========

/// Provider الرئيسي لحالة تبويب المخزون
final inventoryStateProvider =
    StateNotifierProvider.autoDispose<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(ref),
);

/// Provider للتحقق من حالة التحميل
final inventoryLoadingProvider = Provider.autoDispose<bool>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.isLoading;
  },
  dependencies: [inventoryStateProvider],
);

/// Provider للتحقق من حالة الحذف
final inventoryDeletingProvider = Provider.autoDispose<bool>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.isDeleting;
  },
  dependencies: [inventoryStateProvider],
);

/// Provider لرسالة الخطأ
final inventoryErrorProvider = Provider.autoDispose<String?>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.errorMessage;
  },
  dependencies: [inventoryStateProvider],
);

/// Provider للباركود المولد
final generatedBarcodeProvider = Provider.autoDispose<String?>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.generatedBarcode;
  },
  dependencies: [inventoryStateProvider],
);

/// Provider للخيارات المتقدمة
final showAdvancedOptionsProvider = Provider.autoDispose<bool>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return state.showAdvancedOptions;
  },
  dependencies: [inventoryStateProvider],
);

/// Provider لحقول النموذج
final formFieldsProvider = Provider.autoDispose<Map<String, String>>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return <String, String>{
      'productName': state.productName,
      'wholesalePrice': state.wholesalePrice,
      'retailPrice': state.retailPrice,
      'quantity': state.quantity,
      'expiryDate': state.expiryDate,
    };
  },
  dependencies: [inventoryStateProvider],
);

/// Provider لمعايير الفرز
final sortingProvider = Provider.autoDispose<Map<String, dynamic>>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return <String, dynamic>{
      'sortBy': state.sortBy,
      'sortAscending': state.sortAscending,
    };
  },
  dependencies: [inventoryStateProvider],
);

/// Provider لمعايير الفلترة
final filteringProvider = Provider.autoDispose<Map<String, dynamic>>(
  (ref) {
    final InventoryState state = ref.watch(inventoryStateProvider);
    return <String, dynamic>{
      'filterCriteria': state.filterCriteria,
      'filterDate': state.filterDate,
    };
  },
  dependencies: [inventoryStateProvider],
);
