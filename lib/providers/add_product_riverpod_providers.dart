import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../services/app_event_bus.dart';
import '../services/error_handler_service.dart';
import '../services/tab_coordination_service.dart';
import '../services/unified_sales_service.dart';
import '../utils/validators.dart';
import 'riverpod/stream_app_riverpod_provider.dart';
import 'riverpod/stream_inventory_riverpod_provider.dart' as stream;

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
/// ✅ إصلاح: استخدام نفس مصدر البيانات مثل InventoryDisplayTab
final AutoDisposeProvider<List<InventoryItem>> availableInventoryItemsProvider =
    Provider.autoDispose<List<InventoryItem>>(
  (AutoDisposeProviderRef<List<InventoryItem>> ref) {
    final AppState appState = ref.watch(appControllerProvider);
    // ✅ استخدام نفس provider مثل InventoryDisplayTab
    final stream.InventoryState inventoryState =
        ref.watch(stream.inventoryControllerProvider);

    if (!appState.isInitialized || !inventoryState.isInitialized) {
      debugPrint('⏳ Add Product: Waiting for initialization...');
      return <InventoryItem>[];
    }

    if (inventoryState.isLoading) {
      debugPrint('⏳ Add Product: Loading inventory...');
      return <InventoryItem>[];
    }

    // تصفية العناصر المتوفرة فقط (الكمية > 0 وليست نافذة)
    final List<InventoryItem> availableItems = inventoryState.inventoryItems
        .where(
            (InventoryItem item) => !item.isOutOfStock() && item.quantity > 0)
        .toList();

    debugPrint(
        '✅ Add Product: Available inventory items: ${availableItems.length}');
    return availableItems;
  },
  dependencies: <ProviderOrFamily>[
    appControllerProvider,
    stream.inventoryControllerProvider
  ],
);

/// Provider لخريطة العناصر المتاحة (بدون تكرار)
final AutoDisposeProvider<Map<String, InventoryItem>>
    availableInventoryItemsMapProvider =
    Provider.autoDispose<Map<String, InventoryItem>>(
  (AutoDisposeProviderRef<Map<String, InventoryItem>> ref) {
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
  dependencies: <ProviderOrFamily>[availableInventoryItemsProvider],
);

/// Provider للقيم المتاحة في القائمة المنسدلة
final AutoDisposeProvider<Set<String>> availableDropdownValuesProvider =
    Provider.autoDispose<Set<String>>(
  (AutoDisposeProviderRef<Set<String>> ref) {
    final Map<String, InventoryItem> itemsMap =
        ref.watch(availableInventoryItemsMapProvider);

    return itemsMap.values
        .map((InventoryItem item) => '${item.name}_${item.id!}')
        .toSet();
  },
  dependencies: <ProviderOrFamily>[availableInventoryItemsMapProvider],
);

/// Provider للتحقق من وجود عناصر متاحة
final AutoDisposeProvider<bool> hasAvailableItemsProvider =
    Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final Map<String, InventoryItem> itemsMap =
        ref.watch(availableInventoryItemsMapProvider);
    return itemsMap.isNotEmpty;
  },
  dependencies: <ProviderOrFamily>[availableInventoryItemsMapProvider],
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

    state = state.copyWith(isInitializing: true);

    try {
      // TODO: Check app state initialization
      debugPrint('⚠️ App state check needed');

      debugPrint('🔄 تم جلب بيانات المخزون في تبويب البيع السريع');

      // TODO: Update to use new Riverpod providers
      final List<InventoryItem> availableItems = <InventoryItem>[];

      debugPrint('📦 عناصر المخزون المتاحة: ${availableItems.length}');

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
  /// ✅ إصلاح: ضمان التناسق مع InventoryDisplayTab
  Future<bool> addProduct() async {
    if (!state.isFormValid || state.selectedProductName == null) {
      state = state.copyWith(errorMessage: 'يرجى ملء جميع الحقول المطلوبة');
      return false;
    }

    state = state.copyWith(isLoading: true);

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

      // استخدام ErrorHelper.safeExecute لتنفيذ العملية بأمان
      final bool? success = await ErrorHelper.safeExecute(
        () async {
          // ✅ إصلاح: استخدام نفس مصدر البيانات مثل InventoryDisplayTab
          final stream.InventoryState inventoryState =
              _ref.read(stream.inventoryControllerProvider);
          final List<InventoryItem> inventoryItems =
              inventoryState.inventoryItems;

          InventoryItem? selectedItem;
          try {
            selectedItem = inventoryItems.firstWhere(
              (InventoryItem item) => item.id == itemId,
              orElse: () => throw StateError('Item not found'),
            );
          } catch (e) {
            debugPrint(
                '❌ العنصر غير موجود في المخزون المحلي - itemId: $itemId');
            debugPrint('🔍 عدد العناصر في المخزون: ${inventoryItems.length}');
            for (final InventoryItem item in inventoryItems) {
              debugPrint('   - ${item.name} (ID: ${item.id})');
            }
            throw Exception(
                'العنصر المحدد غير موجود في المخزون المحلي.\n\nيرجى:\n1. إضافة المنتج إلى المخزون أولاً من تبويب "المخزون"\n2. أو استخدام تبويب "نقطة البيع" للبحث عن المنتجات الموجودة');
          }

          // selectedItem مضمون أن يكون غير null هنا بسبب الفحص السابق

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

          // ✅ إصلاح: إرسال حدث لتحديث InventoryDisplayTab
          AppEventBus.fire(InventoryUpdatedEvent(
            itemId,
            selectedItem.name,
            selectedItem.quantity,
            selectedItem.quantity - 1,
            sourceTab: 'AddProduct',
          ));

          // ✅ إصلاح: تنسيق البيانات بين التبويبين
          TabCoordinationService().coordinateInventoryUpdate(
            itemId: itemId,
            itemName: selectedItem.name,
            oldQuantity: selectedItem.quantity,
            newQuantity: selectedItem.quantity - 1,
            sourceTab: 'AddProduct',
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
      wholesalePrice: '',
      retailPrice: '',
      isFormValid: false,
    );
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// ========== Providers ==========

/// Provider الرئيسي لحالة تبويب إضافة المنتج
final AutoDisposeStateNotifierProvider<AddProductNotifier, AddProductState>
    addProductStateProvider =
    StateNotifierProvider.autoDispose<AddProductNotifier, AddProductState>(
  AddProductNotifier.new,
);

/// Provider للتحقق من حالة التحميل
final AutoDisposeProvider<bool> addProductLoadingProvider =
    Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.isLoading;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider للتحقق من حالة التهيئة
final AutoDisposeProvider<bool> addProductInitializingProvider =
    Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.isInitializing;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider للتحقق من صحة النموذج
final AutoDisposeProvider<bool> addProductFormValidProvider =
    Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.isFormValid;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider لرسالة الخطأ
final AutoDisposeProvider<String?> addProductErrorProvider =
    Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.errorMessage;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider للمنتج المحدد
final AutoDisposeProvider<String?> selectedProductProvider =
    Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.selectedProductName;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider لسعر الجملة
final AutoDisposeProvider<String> wholesalePriceProvider =
    Provider.autoDispose<String>(
  (AutoDisposeProviderRef<String> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.wholesalePrice;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider لسعر التجزئة
final AutoDisposeProvider<String> retailPriceProvider =
    Provider.autoDispose<String>(
  (AutoDisposeProviderRef<String> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.retailPrice;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);

/// Provider للباركود الممسوح
final AutoDisposeProvider<String?> scannedBarcodeProvider =
    Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final AddProductState state = ref.watch(addProductStateProvider);
    return state.scannedBarcode;
  },
  dependencies: <ProviderOrFamily>[addProductStateProvider],
);
