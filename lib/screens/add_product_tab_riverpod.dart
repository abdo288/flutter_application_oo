import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../providers/add_product_riverpod_providers.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/validators.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/styled_section.dart';

/// تبويب إضافة المنتج المحسن بـ Riverpod
class AddProductTabRiverpod extends ConsumerStatefulWidget {
  const AddProductTabRiverpod({
    super.key,
    required this.inventoryItems,
    required this.onProductAdded,
    this.scannedBarcode,
  });

  final List<InventoryItem> inventoryItems;
  final VoidCallback onProductAdded;
  final String? scannedBarcode;

  @override
  ConsumerState<AddProductTabRiverpod> createState() =>
      _AddProductTabRiverpodState();
}

class _AddProductTabRiverpodState extends ConsumerState<AddProductTabRiverpod> {
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
  void didUpdateWidget(AddProductTabRiverpod oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تهيئة البيانات إذا تغيرت قائمة المخزون
    if (widget.inventoryItems.length != oldWidget.inventoryItems.length) {
      // تأجيل التعديل لتجنب تعديل provider أثناء بناء widget tree
      Future(() => _initializeData());
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
      return _buildLoadingState();
    }

    // مراقبة العناصر المتاحة
    final bool hasAvailableItems = ref.watch(hasAvailableItemsProvider);

    if (!hasAvailableItems) {
      return _buildNoItemsState();
    }

    return _buildContent();
  }

  /// بناء حالة التحميل
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          SizedBox(height: AppConstants.defaultPadding),
          Text(
            'جاري تحميل بيانات المخزون...',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء حالة عدم وجود عناصر
  Widget _buildNoItemsState() {
    return Center(
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppConstants.lightTextColor,
            ),
            SizedBox(height: context.responsiveSpacing),
            Text(
              AppLocalizations.of(context).noInventoryAvailableTitle,
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: AppConstants.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Text(
              AppLocalizations.of(context).noInventoryAvailableSubtitle,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: AppConstants.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing),
            ElevatedButton.icon(
              onPressed: () async {
                await _initializeData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة تحميل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final bool isLoading = ref.watch(addProductLoadingProvider);
    final String? errorMessage = ref.watch(addProductErrorProvider);

    // تحديث controllers عند تغيير القيم
    if (_wholesalePriceController.text != wholesalePrice) {
      _wholesalePriceController.text = wholesalePrice;
    }
    if (_retailPriceController.text != retailPrice) {
      _retailPriceController.text = retailPrice;
    }

    // إذا تم تمرير باركود ممسوح، حاول إيجاد العنصر المطابق وتحديده
    if (widget.scannedBarcode != null && selectedProductName == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(addProductStateProvider.notifier)
            .handleBarcodeScanned(widget.scannedBarcode!);
      });
    }

    final String? currentValue = (selectedProductName != null &&
            availableValues.contains(selectedProductName))
        ? selectedProductName
        : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight,
          maxHeight: constraints.maxHeight,
        ),
        child: SingleChildScrollView(
          physics: context.responsiveScrollPhysics,
          padding: context.responsivePadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppConstants.defaultPadding),

                // عرض رسالة الخطأ إذا وجدت
                if (errorMessage != null) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    margin: const EdgeInsets.only(
                        bottom: AppConstants.defaultPadding),
                    decoration: BoxDecoration(
                      color: AppConstants.errorColor.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      border: Border.all(
                          color: AppConstants.errorColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.error_outline,
                            color: AppConstants.errorColor),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: AppConstants.errorColor),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            ref
                                .read(addProductStateProvider.notifier)
                                .clearError();
                          },
                          icon: const Icon(Icons.close),
                          color: AppConstants.errorColor,
                        ),
                      ],
                    ),
                  ),
                ],

                // اختيار المنتج (بتنسيق محسن)
                StyledSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.inventory_2,
                              size: 20,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).selectProduct,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField2<String>(
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context).chooseFromInventory,
                          hintText:
                              AppLocalizations.of(context).chooseProductHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: const BorderSide(
                                color: AppConstants.primaryColor, width: 2.0),
                          ),
                          filled: true,
                          fillColor: AppConstants.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        items:
                            (availableItemsMap.values.map((InventoryItem item) {
                          final int sameNameCount = availableItemsMap.values
                              .where((InventoryItem i) =>
                                  i.name == item.name && !i.isOutOfStock())
                              .length;
                          return DropdownMenuItem<String>(
                            value: '${item.name}_${item.id!}',
                            child: sameNameCount > 1
                                ? Text('${item.name} (${item.quantity} قطعة)')
                                : Text(item.name),
                          );
                        }).toList()
                              ..sort((DropdownMenuItem<String> a,
                                      DropdownMenuItem<String> b) =>
                                  a.child
                                      .toString()
                                      .compareTo(b.child.toString()))),
                        value: currentValue,
                        onChanged: (String? value) {
                          ref
                              .read(addProductStateProvider.notifier)
                              .selectProduct(value);
                          if (value != null) {
                            final List<String> parts = value.split('_');
                            final String itemId = parts.sublist(1).join('_');
                            final InventoryItem? item =
                                availableItemsMap[itemId];
                            if (item != null) {
                              _showSnackbar(
                                  '${AppLocalizations.of(context).remainingQuantityLabel}: ${item.quantity}');
                            }
                          }
                        },
                        validator: (String? value) => value == null
                            ? AppLocalizations.of(context).pleaseSelectProduct
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // إدخال/مسح باركود لبيع سريع
                StyledSection(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context).fastBarcodeHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                              borderSide: const BorderSide(
                                  color: AppConstants.primaryColor, width: 2.0),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onSubmitted: (String code) {
                            if (code.trim().isEmpty) return;
                            ref
                                .read(addProductStateProvider.notifier)
                                .handleBarcodeScanned(code.trim());
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final String? code =
                                await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    const BarcodeScannerView(),
                              ),
                            );
                            if (code == null || code.trim().isEmpty) return;
                            ref
                                .read(addProductStateProvider.notifier)
                                .handleBarcodeScanned(code.trim());
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          label: Text(
                            AppLocalizations.of(context).scanBarcode,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                            elevation: 2,
                            shadowColor: AppConstants.shadowColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // سعر التجزئة (بتنسيق محسن)
                StyledSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppConstants.warningColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              size: 20,
                              color: AppConstants.warningColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).retailPrice,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: _retailFieldKey,
                        controller: _retailPriceController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).retailPrice,
                          hintText: 'مثال: 1500',
                          prefixIcon: const Icon(Icons.attach_money,
                              color: AppConstants.warningColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: const BorderSide(
                                color: AppConstants.warningColor, width: 2.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                            borderSide: const BorderSide(
                                color: AppConstants.errorColor),
                          ),
                          filled: true,
                          fillColor: AppConstants.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (String value) {
                          ref
                              .read(addProductStateProvider.notifier)
                              .updateRetailPrice(value);
                        },
                        validator: (String? value) => Validators.validatePrices(
                          wholesalePrice,
                          value,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.largePadding),

                // زر الإضافة
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      elevation: 2,
                      shadowColor: AppConstants.shadowColor,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context).addProduct,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
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

    final bool success =
        await ref.read(addProductStateProvider.notifier).addProduct();

    if (success) {
      // Windows-specific success message
      if (Platform.isWindows) {
        _showSnackbar(
            'تم إتمام عملية البيع بنجاح - سيتم تحديث المخزون خلال ثوانٍ');
      } else {
        _showSnackbar('تم إتمام عملية البيع بنجاح');
      }

      // استدعاء callback
      widget.onProductAdded();

      // إرسال أحداث التواصل
      _sendSuccessEvents();
    }
  }

  /// إرسال أحداث النجاح
  void _sendSuccessEvents() {
    try {
      // StreamProviders تقوم بتحديث الواجهات تلقائياً عند تغيير البيانات
      debugPrint(
          '✅ تم إتمام عملية البيع بنجاح - StreamProviders ستقوم بتحديث الواجهات تلقائياً');
      debugPrint('📡 تم إرسال أحداث النجاح للتبويبات الأخرى');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال أحداث النجاح: $e');
    }
  }

  /// عرض رسالة
  void _showSnackbar(String message) {
    if (!mounted) {
      debugPrint('⚠️ تم محاولة عرض Snackbar بعد dispose الـ widget');
      return;
    }

    try {
      final SnackBar snackBar = SnackBar(
        content: Text(message),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      debugPrint('❌ خطأ في عرض Snackbar: $e');
    }
  }
}
