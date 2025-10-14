import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/stream_app_provider.dart';
import '../services/error_handler_service.dart';
import '../services/unified_sales_service.dart';
// ✅ إضافة الخدمات الجديدة
import '../services/app_event_bus.dart';
import '../services/app_state_manager.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/validators.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/styled_section.dart';

class AddProductTab extends StatefulWidget {
  const AddProductTab({
    super.key,
    required this.inventoryItems,
    required this.onProductAdded,
    this.scannedBarcode,
  });
  final List<InventoryItem> inventoryItems;
  final VoidCallback onProductAdded;
  final String? scannedBarcode;

  @override
  State<AddProductTab> createState() => _AddProductTabState();
}

class _AddProductTabState extends State<AddProductTab> {
  final TextEditingController _wholesalePriceController =
      TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _retailFieldKey =
      GlobalKey<FormFieldState<String>>();

  String? selectedProductName;
  bool _isLoading = false;
  bool _isInitializing = true;

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
  void didUpdateWidget(AddProductTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تهيئة البيانات إذا تغيرت قائمة المخزون
    // نستخدم StreamAppProvider للحصول على البيانات المحدثة
    if (!mounted) return;

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      if (appProvider.inventoryProvider.inventoryItems.length !=
          widget.inventoryItems.length) {
        _initializeData();
      }
    } catch (e) {
      debugPrint('❌ خطأ في didUpdateWidget: $e');
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

    setState(() {
      _isInitializing = true;
    });

    try {
      // التحقق من صحة السياق قبل الوصول إلى المزود
      if (!mounted) return;
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // لا حاجة لاستدعاء appProvider.refreshAll() هنا
      // البيانات ستكون متاحة من خلال الـ StreamProvider

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
    } catch (e) {
      debugPrint('❌ خطأ في تحميل بيانات المخزون: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Builder(
        builder: (BuildContext context) => Consumer<StreamAppProvider>(
          builder: (BuildContext context, StreamAppProvider appProvider,
              Widget? child) {
            try {
              if (!appProvider.isInitialized) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري تهيئة التطبيق...'),
                    ],
                  ),
                );
              }
              return _buildContent(context);
            } catch (e) {
              debugPrint('خطأ في Consumer في AddProductTab: $e');
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.error, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text('خطأ في تحميل التطبيق'),
                  ],
                ),
              );
            }
          },
        ),
      );

  Widget _buildContent(BuildContext context) {
    // عرض مؤشر التحميل أثناء التهيئة
    if (_isInitializing) {
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

    // الحصول على البيانات المحدثة من StreamAppProvider
    if (!mounted) return const SizedBox.shrink();

    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    final List<InventoryItem> currentInventoryItems =
        appProvider.inventoryProvider.inventoryItems;

    // إنشاء خريطة عناصر متاحة بدون تكرار حسب المعرف
    final Map<String, InventoryItem> availableItemsMap = currentInventoryItems
        .where((InventoryItem item) => !item.isOutOfStock() && item.id != null)
        .fold<Map<String, InventoryItem>>(<String, InventoryItem>{},
            (Map<String, InventoryItem> map, InventoryItem item) {
      if (!map.containsKey(item.id!)) {
        map[item.id!] = item;
      }
      return map;
    });
    final Set<String> availableValues = availableItemsMap.values
        .map((InventoryItem item) => '${item.name}_${item.id!}')
        .toSet();
    final bool hasAnyAvailable = availableItemsMap.isNotEmpty;
    // إذا تم تمرير باركود ممسوح، حاول إيجاد العنصر المطابق وتحديده
    if (widget.scannedBarcode != null && selectedProductName == null) {
      final InventoryItem match = availableItemsMap.values.firstWhere(
        (InventoryItem i) => (i.barcode ?? '') == widget.scannedBarcode,
        orElse: () => InventoryItem(
          name: '',
          wholesalePrice: 0,
          retailPrice: 0,
          quantity: 0,
          originalQuantity: 0,
          addedDate: DateTime.now(),
          addedTime: DateTime.now(),
        ),
      );
      if (match.id != null) {
        selectedProductName = '${match.name}_${match.id!}';
        _wholesalePriceController.text = match.wholesalePrice.toString();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSnackbar(
              '${AppLocalizations.of(context).selectedPrefix}: ${match.name}');
        });
      }
    }
    final String? currentValue = (selectedProductName != null &&
            availableValues.contains(selectedProductName))
        ? selectedProductName
        : null;

    if (!hasAnyAvailable) {
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
                  setState(() {
                    _isInitializing = true;
                  });
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
                          final int sameNameCount = currentInventoryItems
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
                          setState(() {
                            selectedProductName = value;
                            if (value != null) {
                              final List<String> parts = value.split('_');
                              final String itemId = parts.sublist(1).join('_');
                              final InventoryItem? item = currentInventoryItems
                                  .where((InventoryItem item) =>
                                      !item.isOutOfStock() && item.id == itemId)
                                  .firstOrNull;
                              if (item != null) {
                                _wholesalePriceController.text =
                                    item.wholesalePrice.toString();
                                _showSnackbar(
                                    '${AppLocalizations.of(context).remainingQuantityLabel}: ${item.quantity}');
                              } else {
                                _wholesalePriceController.clear();
                              }
                            }
                          });
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
                            final InventoryItem match =
                                availableItemsMap.values.firstWhere(
                              (InventoryItem i) =>
                                  (i.barcode ?? '') == code.trim(),
                              orElse: () => InventoryItem(
                                name: '',
                                wholesalePrice: 0,
                                retailPrice: 0,
                                quantity: 0,
                                originalQuantity: 0,
                                addedDate: DateTime.now(),
                                addedTime: DateTime.now(),
                              ),
                            );
                            if (match.id != null) {
                              setState(() {
                                selectedProductName =
                                    '${match.name}_${match.id!}';
                                _wholesalePriceController.text =
                                    match.wholesalePrice.toString();
                              });
                              _showSnackbar(
                                  '${AppLocalizations.of(context).selectedPrefix}: ${match.name}');
                            } else {
                              _showSnackbar(AppLocalizations.of(context)
                                  .noItemWithBarcode);
                            }
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
                            final InventoryItem match =
                                availableItemsMap.values.firstWhere(
                              (InventoryItem i) =>
                                  (i.barcode ?? '') == code.trim(),
                              orElse: () => InventoryItem(
                                name: '',
                                wholesalePrice: 0,
                                retailPrice: 0,
                                quantity: 0,
                                originalQuantity: 0,
                                addedDate: DateTime.now(),
                                addedTime: DateTime.now(),
                              ),
                            );
                            if (match.id != null) {
                              setState(() {
                                selectedProductName =
                                    '${match.name}_${match.id!}';
                                _wholesalePriceController.text =
                                    match.wholesalePrice.toString();
                              });
                              _showSnackbar(
                                  '${AppLocalizations.of(context).selectedPrefix}: ${match.name}');
                            } else {
                              _showSnackbar(AppLocalizations.of(context)
                                  .noItemWithBarcode);
                            }
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
                        validator: (String? value) => Validators.validatePrices(
                          _wholesalePriceController.text,
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
                    onPressed: _isLoading ? null : _addProduct,
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
                    child: _isLoading
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

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedProductName == null) {
      _showSnackbar(AppConstants.warningEmptyFields);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('🔄 بدء عملية إضافة المنتج...');

    // استخراج اسم المنتج ومعرف العنصر من القيمة المحددة
    final List<String> parts = selectedProductName!.split('_');
    if (parts.length < 2) {
      _showSnackbar('تنسيق بيانات المنتج غير صحيح');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final String productName = parts.first;
    final String itemId = parts.sublist(1).join('_'); // كل شيء بعد الاسم الأول

    final int wholesalePrice =
        int.tryParse(_wholesalePriceController.text) ?? 0;
    final int retailPrice = int.tryParse(_retailPriceController.text) ?? 0;

    if (wholesalePrice <= 0 || retailPrice <= 0) {
      _showSnackbar('يجب أن تكون الأسعار أكبر من صفر');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    final Product product = Product(
      name: productName,
      wholesalePrice: wholesalePrice,
      retailPrice: retailPrice,
      savedAt: DateTime.now(),
    );

    if (!product.isValid()) {
      _showSnackbar(AppConstants.errorValidation);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    debugPrint(
        '📝 بيانات المنتج: $productName, سعر التجزئة: $retailPrice, سعر الجملة: $wholesalePrice');
    debugPrint('🔍 itemId المستخرج: $itemId');

    // استخراج appProvider قبل أي عملية async لمنع مشاكل BuildContext
    if (!mounted) return;
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();

    // استخدم ErrorHelper.safeExecute لتنفيذ العملية بأمان
    final bool? success = await ErrorHelper.safeExecute(
      () async {
        // استخدام appProvider المستخرج مسبقاً بدلاً من context
        debugPrint(
            '🔍 عدد عناصر المخزون المتاحة: ${appProvider.inventoryProvider.inventoryItems.length}');

        final InventoryItem? selectedItem = appProvider
            .inventoryProvider.inventoryItems
            .where((InventoryItem item) => item.id == itemId)
            .firstOrNull;

        if (selectedItem == null) {
          debugPrint('❌ العنصر غير موجود في المخزون المحلي - itemId: $itemId');
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
      showUserMessage: mounted ? _showSnackbar : null,
    );

    // التحقق من mounted بعد العملية async
    if (!mounted) return;

    if (success != null) {
      // إذا نجحت العملية، قم بتحديث الواجهة
      setState(() {
        selectedProductName = null;
        _retailPriceController.clear();
        _wholesalePriceController.clear();
      });

      // Windows-specific success message
      if (Platform.isWindows) {
        _showSnackbar(
            'تم إتمام عملية البيع بنجاح - سيتم تحديث المخزون خلال ثوانٍ');
      } else {
        _showSnackbar('تم إتمام عملية البيع بنجاح');
      }

      // ✅ تحسين Callback مع إرسال البيانات
      _handleProductAddedSuccess(product);

      // إرسال أحداث التواصل
      _sendSuccessEvents(product);
    } else {
      // في حالة الفشل: لا حاجة لاسترجاع أي شيء لأن العملية لم تكتمل
      debugPrint('❌ فشل في إتمام عملية البيع');
      _showSnackbar('عذرًا، نفذت كمية هذا المنتج من المخزون');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// ✅ معالجة نجاح إضافة المنتج مع تحسينات
  void _handleProductAddedSuccess(Product product) {
    try {
      // 1. استدعاء Callback الأصلي
      widget.onProductAdded();

      // 2. إرسال حدث Event Bus
      AppEventBus.fire(ProductAddedEvent(product, sourceTab: 'AddProduct'));

      // 3. تحديث AppStateManager
      final AppStateManager appStateManager = context.read<AppStateManager>();
      appStateManager.setSharedData('lastAddedProduct', product);

      // 4. تحديث الإحصائيات
      appStateManager.updateStats(<String, dynamic>{
        'productCount': (appStateManager.getStat<int>('productCount') ?? 0) + 1,
        'lastProductAdded': DateTime.now().toIso8601String(),
      });

      // 5. إظهار إشعار محلي
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تمت إضافة "${product.name}" بنجاح'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'عرض',
            textColor: Colors.white,
            onPressed: () {
              // الانتقال إلى ProductList مع تمييز المنتج الجديد
              NavigationService.navigateWithHighlight(
                3, // ProductList tab index
                product.id ?? '',
                sourceTab: 'AddProduct',
              );
            },
          ),
        ),
      );

      // 6. Haptic Feedback
      HapticFeedback.mediumImpact();

      debugPrint('✅ تمت معالجة نجاح إضافة المنتج: ${product.name}');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة نجاح إضافة المنتج: $e');
    }
  }

  void _sendSuccessEvents(Product product) {
    try {
      // StreamProviders تقوم بتحديث الواجهات تلقائياً عند تغير البيانات
      // لا نحتاج إلى إرسال أحداث معقدة
      debugPrint(
          '✅ تم إتمام عملية البيع بنجاح - StreamProviders ستقوم بتحديث الواجهات تلقائياً');

      debugPrint('📡 تم إرسال أحداث النجاح للتبويبات الأخرى');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال أحداث النجاح: $e');
    }
  }

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
