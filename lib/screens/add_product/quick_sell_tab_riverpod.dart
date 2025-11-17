import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/inventory_item.dart';
import '../../providers/add_product_riverpod_providers.dart';
import '../../utils/constants.dart';
import '../../utils/responsive_breakpoints.dart';
import 'widgets/action_buttons_section.dart';
import 'widgets/barcode_section.dart';
import 'widgets/header_section.dart';
import 'widgets/loading_states.dart';
import 'widgets/price_input_section.dart';
import 'widgets/product_selection_section.dart';

/// تبويب البيع السريع المحسن بـ Riverpod - لإضافة منتج موجود للبيع بسرعة
class QuickSellTabRiverpod extends ConsumerStatefulWidget {
  const QuickSellTabRiverpod({
    super.key,
    required this.onProductAdded,
    this.scannedBarcode,
  });

  final VoidCallback onProductAdded;
  final String? scannedBarcode;

  @override
  ConsumerState<QuickSellTabRiverpod> createState() =>
      _QuickSellTabRiverpodState();
}

class _QuickSellTabRiverpodState extends ConsumerState<QuickSellTabRiverpod> {
  final TextEditingController _wholesalePriceController =
      TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _retailFieldKey =
      GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    // تأجيل تهيئة البيانات حتى يتم بناء الشجرة بالكامل
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  @override
  void didUpdateWidget(QuickSellTabRiverpod oldWidget) {
    super.didUpdateWidget(oldWidget);

    // إعادة تهيئة البيانات إذا تغير الباركود الممسوح
    if (widget.scannedBarcode != oldWidget.scannedBarcode) {
      // تأجيل التعديل لتجنب تعديل provider أثناء بناء widget tree
      Future(_initializeData);
    }
  }

  @override
  void dispose() {
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    super.dispose();
  }

  /// تهيئة البيانات عند فتح التبويب
  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      await ref.read(addProductStateProvider.notifier).initializeData();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة البيانات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة حالة التهيئة
    final bool isInitializing = ref.watch(addProductInitializingProvider);

    if (isInitializing) {
      return LoadingStates.buildLoadingState();
    }

    // مراقبة العناصر المتاحة
    final bool hasAvailableItems = ref.watch(hasAvailableItemsProvider);

    if (!hasAvailableItems) {
      return LoadingStates.buildNoItemsState(context, ref);
    }

    return _buildContent();
  }

  /// بناء المحتوى الرئيسي
  Widget _buildContent() {
    // مراقبة البيانات المطلوبة
    final Map<String, InventoryItem> availableItemsMap =
        ref.watch(availableInventoryItemsMapProvider);
    final Set<String> availableValues =
        ref.watch(availableDropdownValuesProvider);
    final String? selectedProductName = ref.watch(selectedProductProvider);
    final String wholesalePrice = ref.watch(wholesalePriceProvider);
    final String retailPrice = ref.watch(retailPriceProvider);

    // تحديث controllers عند تغيير القيم
    if (_wholesalePriceController.text != wholesalePrice) {
      _wholesalePriceController.text = wholesalePrice;
    }
    if (_retailPriceController.text != retailPrice) {
      _retailPriceController.text = retailPrice;
    }

    // إذا تم تمرير باركود ممسوح، حاول إيجاد العنصر المطابق وتحديده
    if (widget.scannedBarcode != null && selectedProductName == null) {
      // استخدام Future.microtask لتجنب build scheduling errors
      Future.microtask(() {
        if (mounted) {
          ref
              .read(addProductStateProvider.notifier)
              .handleBarcodeScanned(widget.scannedBarcode!);
        }
      });
    }

    final String? currentValue = (selectedProductName != null &&
            availableValues.contains(selectedProductName))
        ? selectedProductName
        : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          SingleChildScrollView(
        physics: context.responsiveScrollPhysics,
        padding: context.responsivePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header Section
              const HeaderSection(),

              // اختيار المنتج (بتنسيق محسن)
              ProductSelectionSection(
                availableItemsMap: availableItemsMap,
                currentValue: currentValue,
                onShowSnackbar: _showSnackbar,
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // إدخال/مسح باركود لبيع سريع
              const BarcodeSection(),

              const SizedBox(height: AppConstants.defaultPadding),

              // سعر التجزئة (بتنسيق محسن)
              PriceInputSection(
                retailPriceController: _retailPriceController,
                retailFieldKey: _retailFieldKey,
                wholesalePrice: wholesalePrice,
              ),

              const SizedBox(height: AppConstants.largePadding),

              // زر الإضافة
              ActionButtonsSection(
                onAddProduct: _addProduct,
              ),

              const SizedBox(height: AppConstants.largePadding),
            ],
          ),
        ),
      ),
    );
  }

  /// إضافة المنتج
  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final bool success =
          await ref.read(addProductStateProvider.notifier).addProduct();

      if (success) {
        widget.onProductAdded();
        _showSnackbar('تم إضافة المنتج بنجاح');
      } else {
        final String errorMessage =
            ref.read(addProductStateProvider).errorMessage ??
                'فشل في إضافة المنتج';
        _showSnackbar(errorMessage);
      }
    } catch (e) {
      _showSnackbar('خطأ في إضافة المنتج: $e');
    }
  }

  /// عرض رسالة تنبيه
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
}
