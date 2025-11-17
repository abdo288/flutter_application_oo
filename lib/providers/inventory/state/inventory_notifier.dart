import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import '../../../services/app_event_bus.dart';
import '../../../services/cross_tab_sync_service.dart';
import '../../../services/error_handler_service.dart';
// import '../../../services/inventory_alert_service.dart';
import '../../../utils/validators.dart';
import '../../riverpod/stream_inventory_riverpod_provider.dart' as stream;
import 'inventory_state.dart';

/// StateNotifier لإدارة حالة تبويب نموذج المنتج
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
      Future.microtask(() {
        _startEventListening();
        _startCrossTabListening();
      });
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
      // TODO: Update to use new Riverpod providers
      debugPrint('🔄 Refreshing inventory...');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
    }
  }

  /// تهيئة البيانات
  Future<void> initialize() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      // TODO: Update to use new Riverpod providers
      // if (!appState.isInitialized) {
      //   // TODO: Initialize app state
      //   debugPrint('⚠️ App state not initialized');
      // }

      debugPrint('✅ تم تهيئة تبويب نموذج المنتج بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة تبويب نموذج المنتج: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تهيئة تبويب نموذج المنتج: $e',
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

    final String code = candidate();
    // TODO: Update to use new Riverpod providers
    // final InventoryController inventoryController = _ref.read(inventoryControllerProvider.notifier);

    // TODO: Update to use new Riverpod providers
    // Dead code removed - was unreachable due to false condition

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

    state = state.copyWith(isLoading: true);

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

      // استخدام InventoryController الجديد
      final stream.InventoryController inventoryController =
          _ref.read(stream.inventoryControllerProvider.notifier);

      // إضافة العنصر باستخدام InventoryController
      final String? itemId = await inventoryController.addInventoryItem(item);

      if (itemId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'فشل في إضافة عنصر المخزون',
        );
        return false;
      }

      // إرسال حدث للتبويبات الأخرى
      AppEventBus.fire(InventoryItemAddedEvent(item, sourceTab: 'Inventory'));

      // إعادة تعيين حالة التحميل ومسح النموذج
      state = state.copyWith(isLoading: false);
      clearForm();
      return true;
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
    state = state.copyWith(isLoading: true);

    try {
      // TODO: Update to use new Riverpod providers
      // final InventoryController inventoryController = _ref.read(inventoryControllerProvider.notifier);

      // TODO: Update to use new Riverpod providers - تم تعطيل منطق التحديث مؤقتاً
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
    state = state.copyWith(isDeleting: true);

    try {
      // TODO: Update to use new Riverpod providers
      // final InventoryController inventoryController = _ref.read(inventoryControllerProvider.notifier);

      // TODO: Update to use new Riverpod providers - تم تعطيل منطق الحذف مؤقتاً
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
    state = state.copyWith(isLoading: true);

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

          // TODO: Update to use new Riverpod providers
          // final InventoryController inventoryController = _ref.read(inventoryControllerProvider.notifier);

          // التحقق من وجود الاسم
          // TODO: Update to use new Riverpod providers
          // تم تعطيل فحص الاسم المكرر مؤقتاً

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
            // TODO: Update to use new Riverpod providers
            // Dead code removed - itemId was always null
            successCount++;
          } else {
            errorCount++;
          }
        } catch (e) {
          errorCount++;
        }
      }

      // فحص التنبيهات
      // TODO: Update to use new Riverpod providers
      // await InventoryAlertService.checkInventoryAlertsForControllers(
      //     _ref.read(inventoryControllerProvider.notifier));

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
      showAdvancedOptions: false,
      isFormValid: false,
    );
  }

  /// تعيين الفرز
  void setSorting(String sortBy, bool ascending) {
    state = state.copyWith(sortBy: sortBy, sortAscending: ascending);
  }

  /// تعيين الفلتر
  void setFilter(String criteria) {
    state = state.copyWith(filterCriteria: criteria);
  }

  /// تعيين فلتر التاريخ
  void setDateFilter(DateTime date) {
    state = state.copyWith(filterDate: date, filterCriteria: '');
  }

  /// إعادة تعيين الفلتر
  void resetFilter() {
    state = state.copyWith(filterCriteria: '');
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _crossTabSubscription?.cancel();
    _updateDebounceTimer?.cancel();
    super.dispose();
  }
}
