import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../services/app_event_bus.dart';
import '../services/error_handler_service.dart';
import '../services/unified_sales_service.dart';
import '../utils/validators.dart';
import 'riverpod_provider_wrapper.dart';
import 'stream_app_provider.dart';

// ========== State Model ==========

/// حالة تبويب إضافة المنتج
class AddProductState {
  const AddProductState({
    this.isLoading = false,
    this.isInitializing = false,
    this.selectedProductName,
    this.scannedBarcode,
    this.wholesalePrice = '',
    this.retailPrice = '',
    this.errorMessage,
    this.isFormValid = false,
  });

  final bool isLoading;
  final bool isInitializing;
  final String? selectedProductName;
  final String? scannedBarcode;
  final String wholesalePrice;
  final String retailPrice;
  final String? errorMessage;
  final bool isFormValid;

  AddProductState copyWith({
    bool? isLoading,
    bool? isInitializing,
    String? selectedProductName,
    String? scannedBarcode,
    String? wholesalePrice,
    String? retailPrice,
    String? errorMessage,
    bool? isFormValid,
  }) =>
      AddProductState(
        isLoading: isLoading ?? this.isLoading,
        isInitializing: isInitializing ?? this.isInitializing,
        selectedProductName: selectedProductName ?? this.selectedProductName,
        scannedBarcode: scannedBarcode ?? this.scannedBarcode,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        errorMessage: errorMessage ?? this.errorMessage,
        isFormValid: isFormValid ?? this.isFormValid,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddProductState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isInitializing == other.isInitializing &&
          selectedProductName == other.selectedProductName &&
          scannedBarcode == other.scannedBarcode &&
          wholesalePrice == other.wholesalePrice &&
          retailPrice == other.retailPrice &&
          errorMessage == other.errorMessage &&
          isFormValid == other.isFormValid;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      isInitializing.hashCode ^
      selectedProductName.hashCode ^
      scannedBarcode.hashCode ^
      wholesalePrice.hashCode ^
      retailPrice.hashCode ^
      errorMessage.hashCode ^
      isFormValid.hashCode;
}

// ========== Computed Providers ==========

/// Provider للعناصر المتاحة في المخزون (غير النافذة)
final availableInventoryItemsProvider =
    Provider.autoDispose<List<InventoryItem>>(
  (ref) {
    final StreamAppProvider appProvider = ref.watch(streamAppProvider);

    if (!appProvider.isInitialized) {
      return <InventoryItem>[];
    }

    return appProvider.inventoryProvider.inventoryItems
        .where((InventoryItem item) => !item.isOutOfStock() && item.id != null)
        .toList();
  },
  dependencies: [streamAppProvider],
);

/// Provider لخريطة العناصر المتاحة (بدون تكرار)
final availableInventoryItemsMapProvider =
    Provider.autoDispose<Map<String, InventoryItem>>(
  (ref) {
    final List<InventoryItem> items =
        ref.watch(availableInventoryItemsProvider);

    return items.fold<Map<String, InventoryItem>>(
      <String, InventoryItem>{},
      (Map<String, InventoryItem> map, InventoryItem item) {
        if (!map.containsKey(item.id!)) {
          map[item.id!] = item;
        }
        return map;
      },
    );
  },
  dependencies: [availableInventoryItemsProvider],
);

/// Provider للقيم المتاحة في القائمة المنسدلة
final availableDropdownValuesProvider = Provider.autoDispose<Set<String>>(
  (ref) {
    final Map<String, InventoryItem> itemsMap =
        ref.watch(availableInventoryItemsMapProvider);

    return itemsMap.values
        .map((InventoryItem item) => '${item.name}_${item.id!}')
        .toSet();
  },
  dependencies: [availableInventoryItemsMapProvider],
);

/// Provider للتحقق من وجود عناصر متاحة
final hasAvailableItemsProvider = Provider.autoDispose<bool>(
  (ref) {
    final Map<String, InventoryItem> itemsMap =
        ref.watch(availableInventoryItemsMapProvider);
    return itemsMap.isNotEmpty;
  },
  dependencies: [availableInventoryItemsMapProvider],
);

// ========== State Notifier ==========

/// StateNotifier لإدارة حالة تبويب إضافة المنتج
class AddProductNotifier extends StateNotifier<AddProductState> {
  AddProductNotifier(this._ref) : super(const AddProductState()) {
    _initialize();
  }

  final Ref _ref;
  StreamSubscription<AppEvent>? _eventSubscription;

  void _initialize() {
    _startEventListening();
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

  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    // إعادة تحميل البيانات عند تحديث المخزون
    initializeData();
  }

  void _handleSaleCompleted(SaleCompletedEvent event) {
    // إعادة تحميل البيانات عند إتمام عملية بيع
    initializeData();
  }

  /// تهيئة البيانات عند فتح التبويب
  Future<void> initializeData() async {
    if (state.isInitializing) return;

    state = state.copyWith(isInitializing: true, errorMessage: null);

    try {
      final StreamAppProvider appProvider = _ref.read(streamAppProvider);

      if (!appProvider.isInitialized) {
        await appProvider.initialize();
      }

      debugPrint(
          '🔄 تم جلب بيانات المخزون في تبويب البيع: ${appProvider.inventoryProvider.inventoryItems.length} عنصر');

      // التحقق من وجود عناصر متاحة
      final List<InventoryItem> availableItems = appProvider
          .inventoryProvider.inventoryItems
          .where(
              (InventoryItem item) => !item.isOutOfStock() && item.id != null)
          .toList();

      debugPrint(
          '📦 عناصر المخزون المتاحة: ${availableItems.length} من أصل ${appProvider.inventoryProvider.inventoryItems.length}');

      state = state.copyWith(isInitializing: false);
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات المخزون: $e');
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'خطأ في تحميل بيانات المخزون: $e',
      );
    }
  }

  /// تحديث المنتج المحدد
  void selectProduct(String? productName) {
    if (productName == null) {
      state = state.copyWith(
        selectedProductName: null,
        wholesalePrice: '',
        retailPrice: '',
        isFormValid: false,
      );
      return;
    }

    final Map<String, InventoryItem> itemsMap =
        _ref.read(availableInventoryItemsMapProvider);
    final List<String> parts = productName.split('_');

    if (parts.length < 2) return;

    final String itemId = parts.sublist(1).join('_');
    final InventoryItem? item = itemsMap[itemId];

    if (item != null) {
      state = state.copyWith(
        selectedProductName: productName,
        wholesalePrice: item.wholesalePrice.toString(),
        retailPrice: item.retailPrice.toString(),
        isFormValid: _validateForm(productName, item.wholesalePrice.toString(),
            item.retailPrice.toString()),
      );
    }
  }

  /// تحديث سعر الجملة
  void updateWholesalePrice(String price) {
    state = state.copyWith(
      wholesalePrice: price,
      isFormValid:
          _validateForm(state.selectedProductName, price, state.retailPrice),
    );
  }

  /// تحديث سعر التجزئة
  void updateRetailPrice(String price) {
    state = state.copyWith(
      retailPrice: price,
      isFormValid:
          _validateForm(state.selectedProductName, state.wholesalePrice, price),
    );
  }

  /// التحقق من صحة النموذج
  bool _validateForm(
      String? productName, String wholesalePrice, String retailPrice) {
    if (productName == null || productName.isEmpty) return false;
    if (wholesalePrice.isEmpty || retailPrice.isEmpty) return false;

    final int? wholesale = int.tryParse(wholesalePrice);
    final int? retail = int.tryParse(retailPrice);

    if (wholesale == null || retail == null) return false;
    if (wholesale <= 0 || retail <= 0) return false;

    // التحقق من صحة الأسعار
    final String? validationError =
        Validators.validatePrices(wholesalePrice, retailPrice);
    return validationError == null;
  }

  /// معالجة الباركود الممسوح
  void handleBarcodeScanned(String barcode) {
    state = state.copyWith(scannedBarcode: barcode);

    final Map<String, InventoryItem> itemsMap =
        _ref.read(availableInventoryItemsMapProvider);
    final InventoryItem? match =
        itemsMap.values.cast<InventoryItem?>().firstWhere(
              (InventoryItem? item) =>
                  item != null && (item.barcode ?? '') == barcode,
              orElse: () => null,
            );

    if (match != null && match.id != null) {
      final String productName = '${match.name}_${match.id!}';
      selectProduct(productName);
    }
  }

  /// إضافة المنتج
  Future<bool> addProduct() async {
    if (!state.isFormValid || state.selectedProductName == null) {
      state = state.copyWith(errorMessage: 'يرجى ملء جميع الحقول المطلوبة');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // استخراج اسم المنتج ومعرف العنصر
      final List<String> parts = state.selectedProductName!.split('_');
      if (parts.length < 2) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'تنسيق بيانات المنتج غير صحيح',
        );
        return false;
      }

      final String productName = parts.first;
      final String itemId = parts.sublist(1).join('_');
      final int wholesalePrice = int.tryParse(state.wholesalePrice) ?? 0;
      final int retailPrice = int.tryParse(state.retailPrice) ?? 0;

      if (wholesalePrice <= 0 || retailPrice <= 0) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'يجب أن تكون الأسعار أكبر من صفر',
        );
        return false;
      }

      final Product product = Product(
        name: productName,
        wholesalePrice: wholesalePrice,
        retailPrice: retailPrice,
        savedAt: DateTime.now(),
      );

      if (!product.isValid()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'بيانات المنتج غير صالحة',
        );
        return false;
      }

      debugPrint(
          '📝 بيانات المنتج: $productName, سعر التجزئة: $retailPrice, سعر الجملة: $wholesalePrice');
      debugPrint('🔍 itemId المستخرج: $itemId');

      final StreamAppProvider appProvider = _ref.read(streamAppProvider);

      // استخدام ErrorHelper.safeExecute لتنفيذ العملية بأمان
      final bool? success = await ErrorHelper.safeExecute(
        () async {
          final InventoryItem? selectedItem = appProvider
              .inventoryProvider.inventoryItems
              .where((InventoryItem item) => item.id == itemId)
              .firstOrNull;

          if (selectedItem == null) {
            debugPrint(
                '❌ العنصر غير موجود في المخزون المحلي - itemId: $itemId');
            throw Exception(
                'العنصر المحدد غير موجود في المخزون المحلي. يرجى إضافة المنتج إلى المخزون أولاً.');
          }

          debugPrint(
              '✅ تم العثور على العنصر في المخزون المحلي: ${selectedItem.name}');

          // إنشاء منتج للبيع
          final Product saleProduct = Product(
            id: selectedItem.id,
            name: selectedItem.name,
            wholesalePrice: wholesalePrice,
            retailPrice: retailPrice,
            savedAt: DateTime.now(),
          );

          // إتمام عملية البيع الفردية (يتضمن تحديث المخزون)
          await UnifiedSalesService.completeSingleProductSale(
            itemId: itemId,
            product: saleProduct,
          );

          // Windows-specific: Add delay before success confirmation
          if (Platform.isWindows) {
            debugPrint('🪟 Windows: إضافة تأخير قبل تأكيد النجاح');
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }

          debugPrint('✅ تم إتمام عملية البيع بنجاح للمنتج: $productName');
          return true;
        },
        userAction: 'إضافة منتج للبيع من شاشة إضافة المنتج',
        showUserMessage: null, // سنعرض الرسالة في UI
      );

      if (success == true) {
        // نجحت العملية
        _handleProductAddedSuccess(product);
        state = state.copyWith(isLoading: false);
        _clearForm();
        return true;
      } else {
        // فشلت العملية
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'عذرًا، نفذت كمية هذا المنتج من المخزون',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// معالجة نجاح إضافة المنتج
  void _handleProductAddedSuccess(Product product) {
    try {
      // إرسال حدث Event Bus
      AppEventBus.fire(ProductAddedEvent(product, sourceTab: 'AddProduct'));

      // تحديث AppStateManager - سيتم تنفيذها لاحقاً
      // final BuildContext? context = _ref.read(providerContextProvider);
      // if (context != null) {
      //   final AppStateManager appStateManager = context.read<AppStateManager>();
      //   appStateManager.setSharedData('lastAddedProduct', product);
      //   appStateManager.updateStats(<String, dynamic>{
      //     'productCount': (appStateManager.getStat<int>('productCount') ?? 0) + 1,
      //     'lastProductAdded': DateTime.now().toIso8601String(),
      //   });
      // }

      debugPrint('✅ تمت معالجة نجاح إضافة المنتج: ${product.name}');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة نجاح إضافة المنتج: $e');
    }
  }

  /// مسح النموذج
  void _clearForm() {
    state = state.copyWith(
      selectedProductName: null,
      wholesalePrice: '',
      retailPrice: '',
      isFormValid: false,
      scannedBarcode: null,
    );
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// ========== Providers ==========

/// Provider الرئيسي لحالة تبويب إضافة المنتج
final addProductStateProvider =
    StateNotifierProvider.autoDispose<AddProductNotifier, AddProductState>(
  (ref) => AddProductNotifier(ref),
);

/// Provider للتحقق من حالة التحميل
final addProductLoadingProvider = Provider.autoDispose<bool>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.isLoading;
  },
  dependencies: [addProductStateProvider],
);

/// Provider للتحقق من حالة التهيئة
final addProductInitializingProvider = Provider.autoDispose<bool>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.isInitializing;
  },
  dependencies: [addProductStateProvider],
);

/// Provider للتحقق من صحة النموذج
final addProductFormValidProvider = Provider.autoDispose<bool>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.isFormValid;
  },
  dependencies: [addProductStateProvider],
);

/// Provider لرسالة الخطأ
final addProductErrorProvider = Provider.autoDispose<String?>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.errorMessage;
  },
  dependencies: [addProductStateProvider],
);

/// Provider للمنتج المحدد
final selectedProductProvider = Provider.autoDispose<String?>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.selectedProductName;
  },
  dependencies: [addProductStateProvider],
);

/// Provider لسعر الجملة
final wholesalePriceProvider = Provider.autoDispose<String>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.wholesalePrice;
  },
  dependencies: [addProductStateProvider],
);

/// Provider لسعر التجزئة
final retailPriceProvider = Provider.autoDispose<String>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.retailPrice;
  },
  dependencies: [addProductStateProvider],
);

/// Provider للباركود الممسوح
final scannedBarcodeProvider = Provider.autoDispose<String?>(
  (ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.scannedBarcode;
  },
  dependencies: [addProductStateProvider],
);
