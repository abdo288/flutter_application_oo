import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/inventory_item.dart';
import '../../../providers/riverpod/stream_inventory_riverpod_provider.dart'
    as stream;
import '../../../services/app_event_bus.dart';
import '../../../utils/validators.dart';

/// حالة تحرير العنصر
@immutable
class EditItemState {
  const EditItemState({
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoading;
  final String? errorMessage;

  EditItemState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) =>
      EditItemState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class EditItemController extends StateNotifier<EditItemState> {
  EditItemController({
    required this.item,
    required this.onItemUpdated,
    required this.ref,
    this.onItemDeleted,
  }) : super(const EditItemState()) {
    _nameController = TextEditingController(text: item.name);
    _wholesalePriceController =
        TextEditingController(text: item.wholesalePrice.toString());
    _retailPriceController =
        TextEditingController(text: item.retailPrice.toString());
    _quantityController = TextEditingController(text: item.quantity.toString());
    _barcode = item.barcode;
    
    // ✅ الاستماع لأحداث الحذف لحل مشكلة Edit/Delete Collision
    _setupDeleteListener();
  }

  final InventoryItem item;
  final VoidCallback onItemUpdated;
  final VoidCallback? onItemDeleted; // Callback عند حذف العنصر
  final WidgetRef ref;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _quantityController;
  String? _barcode;
  StreamSubscription<AppEvent>? _eventSubscription;
  bool _isItemDeleted = false; // علامة لتتبع حالة الحذف

  // Getters
  TextEditingController get nameController => _nameController;
  TextEditingController get wholesalePriceController =>
      _wholesalePriceController;
  TextEditingController get retailPriceController => _retailPriceController;
  TextEditingController get quantityController => _quantityController;
  String? get barcode => _barcode;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;

  /// حساب القيمة الإجمالية
  int calculateTotalValue() {
    final int? price = int.tryParse(_retailPriceController.text);
    final int? quantity = int.tryParse(_quantityController.text);

    if (price != null && quantity != null) {
      return price * quantity;
    }
    return 0;
  }

  /// إعداد مستمع لأحداث الحذف
  void _setupDeleteListener() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      if (event is InventoryItemDeletedEvent) {
        // ✅ التحقق من أن العنصر المحذوف هو نفس العنصر الذي يتم تعديله
        if (event.itemId == item.id || event.itemName == item.name) {
          debugPrint('⚠️ تم حذف العنصر "${item.name}" أثناء التعديل');
          _isItemDeleted = true;
          
          if (mounted) {
            state = state.copyWith(
              errorMessage: 'تم حذف هذا العنصر. لا يمكن حفظ التعديلات.',
            );
          }
          
          // إغلاق النافذة تلقائياً بعد تأخير قصير
          Future<void>.delayed(const Duration(milliseconds: 1500), () {
            if (onItemDeleted != null) {
              onItemDeleted!();
            }
          });
        }
      }
    });
  }

  /// تحديث العنصر
  Future<void> updateItem() async {
    // التحقق من أن الـ controller ما زال mounted قبل المتابعة
    if (!mounted) {
      debugPrint('EditItemController is not mounted, skipping update');
      return;
    }

    // ✅ التحقق من أن العنصر لم يتم حذفه
    if (_isItemDeleted) {
      if (mounted) {
        state = state.copyWith(
          errorMessage: 'لا يمكن حفظ التعديلات: تم حذف هذا العنصر.',
        );
      }
      return;
    }

    if (!formKey.currentState!.validate()) {
      return;
    }

    // التحقق من صحة السعرين معاً
    final String? priceValidationError = Validators.validatePrices(
      _wholesalePriceController.text.trim(),
      _retailPriceController.text.trim(),
    );

    if (priceValidationError != null) {
      if (mounted) {
        state = state.copyWith(
          errorMessage: priceValidationError,
        );
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(isLoading: true);
    }

    try {
      final String name = Validators.cleanText(_nameController.text);
      final int wholesalePrice =
          int.parse(_wholesalePriceController.text.trim());
      final int retailPrice = int.parse(_retailPriceController.text.trim());
      final int quantity = int.parse(_quantityController.text.trim());

      final InventoryItem updatedItem = item.copyWith(
        name: name,
        wholesalePrice: wholesalePrice,
        retailPrice: retailPrice,
        quantity: quantity,
      );

      if (updatedItem.id != null) {
        // ✅ التحقق مرة أخرى من أن العنصر لم يتم حذفه قبل الحفظ
        if (_isItemDeleted) {
          if (mounted) {
            state = state.copyWith(
              errorMessage: 'لا يمكن حفظ التعديلات: تم حذف هذا العنصر.',
            );
          }
          return;
        }

        // استخدام inventory controller للتحديث الفعلي مباشرة
        try {
          // ✅ التحقق من وجود العنصر قبل التحديث
          final stream.InventoryState inventoryState =
              ref.read(stream.inventoryControllerProvider);
          final bool itemExists = inventoryState.inventoryItems.any(
            (InventoryItem invItem) => invItem.id == updatedItem.id,
          );

          if (!itemExists) {
            throw Exception('هذا العنصر لم يعد موجوداً في المخزون.');
          }

          final bool success = await ref
              .read(stream.inventoryControllerProvider.notifier)
              .updateInventoryItem(updatedItem);

          if (success) {
            debugPrint('✅ تم تحديث العنصر بنجاح');
            onItemUpdated();
          } else {
            if (mounted) {
              state = state.copyWith(
                errorMessage: 'فشل في تحديث العنصر',
              );
            }
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحديث العنصر: $e');
          if (mounted) {
            state = state.copyWith(
              errorMessage: 'خطأ في تحديث العنصر: $e',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          errorMessage: 'خطأ في تحديث عنصر المخزون: $e',
        );
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  @override
  void dispose() {
    // ✅ إلغاء الاشتراك في الأحداث
    _eventSubscription?.cancel();
    _eventSubscription = null;
    
    _nameController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

// ========== Riverpod Providers ==========
// تم تعطيل هذه providers لأننا نستخدم controller مباشرة الآن

// /// Provider للـ EditItemController
// final StateNotifierProviderFamily<EditItemController, EditItemState,
//         ({InventoryItem item, VoidCallback onItemUpdated})>
//     editItemControllerProvider = StateNotifierProvider.family<
//             EditItemController,
//             EditItemState,
//             ({InventoryItem item, VoidCallback onItemUpdated})>(
//         (StateNotifierProviderRef<EditItemController, EditItemState> ref,
//                 ({InventoryItem item, VoidCallback onItemUpdated}) params) =>
//             EditItemController(
//               item: params.item,
//               onItemUpdated: params.onItemUpdated,
//               ref: ref,
//             ));

// /// Provider لحالة التحميل
// final ProviderFamily<bool, ({InventoryItem item, VoidCallback onItemUpdated})>
//     editItemLoadingProvider =
//     Provider.family<bool, ({InventoryItem item, VoidCallback onItemUpdated})>(
//         (ProviderRef<bool> ref,
//                 ({InventoryItem item, VoidCallback onItemUpdated}) params) =>
//             ref.watch(editItemControllerProvider(params)
//                 .select((EditItemState state) => state.isLoading)));

// /// Provider لرسالة الخطأ
// final ProviderFamily<String?,
//         ({InventoryItem item, VoidCallback onItemUpdated})>
//     editItemErrorProvider = Provider.family<String?,
//             ({InventoryItem item, VoidCallback onItemUpdated})>(
//         (ProviderRef<String?> ref,
//                 ({InventoryItem item, VoidCallback onItemUpdated}) params) =>
//             ref.watch(editItemControllerProvider(params)
//                 .select((EditItemState state) => state.errorMessage)));
