import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../providers/inventory_riverpod_providers.dart';
import '../providers/riverpod_provider_wrapper.dart';
import '../providers/stream_app_provider.dart';
import '../services/error_handler_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/validators.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/styled_section.dart';

/// تبويب المخزون المحسن بـ Riverpod
class InventoryTabRiverpod extends ConsumerStatefulWidget {
  const InventoryTabRiverpod({
    super.key,
    required this.onInventoryUpdated,
  });

  final VoidCallback onInventoryUpdated;

  @override
  ConsumerState<InventoryTabRiverpod> createState() =>
      _InventoryTabRiverpodState();
}

class _InventoryTabRiverpodState extends ConsumerState<InventoryTabRiverpod>
    with AutomaticKeepAliveClientMixin<InventoryTabRiverpod> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _wholesalePriceController =
      TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // تأجيل تهيئة البيانات حتى بعد انتهاء بناء الـ widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _quantityController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// تهيئة البيانات
  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      // تأجيل تهيئة البيانات حتى بعد انتهاء بناء الـ widget tree
      await Future<void>.delayed(Duration.zero);
      await ref.read(inventoryStateProvider.notifier).initialize();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة البيانات: $e');
    }
  }

  /// Pull-to-refresh لإعادة تحميل بيانات المخزون
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 بدء تحديث بيانات المخزون...');

      final StreamAppProvider appProvider = ref.read(streamAppProvider);

      if (!appProvider.isInitialized) {
        debugPrint('⚠️ التطبيق لم يتم تهيئته بعد');
        return;
      }

      await appProvider.refreshAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث بيانات المخزون بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        debugPrint('✅ تم تحديث بيانات المخزون بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث بيانات المخزون: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('خطأ في التحديث: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    debugPrint('🏗️ RIVERPOD: InventoryTabRiverpod build() called');

    // مراقبة حالة التحميل
    // final bool isLoading = ref.watch(inventoryLoadingProvider);

    // مراقبة رسالة الخطأ
    final String? errorMessage = ref.watch(inventoryErrorProvider);

    // التحقق من أن Provider مهيأ
    final StreamAppProvider appProvider = ref.read(streamAppProvider);
    if (!appProvider.isInitialized) {
      return _buildShimmerLoading();
    }

    // التحقق من وجود خطأ
    if (errorMessage != null) {
      return _buildErrorState(errorMessage);
    }

    try {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool isWide = width >= 700;
          final double maxFormWidth = isWide ? 800.0 : width;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppConstants.primaryColor,
            backgroundColor: Colors.white,
            strokeWidth: 3.0,
            displacement: 60,
            child: SingleChildScrollView(
              physics: context.responsiveScrollPhysics,
              padding: context.responsivePadding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // العنوان الرئيسي
                        _buildHeader(),

                        SizedBox(height: context.responsiveSpacing * 2),

                        // معلومات المنتج الأساسية
                        _buildBasicInfoSection(),

                        SizedBox(height: context.responsiveSpacing),

                        // معلومات السعر والكمية
                        _buildPriceQuantitySection(),

                        SizedBox(height: context.responsiveSpacing),

                        // خيارات متقدمة
                        _buildAdvancedOptionsSection(),

                        SizedBox(height: context.responsiveSpacing * 2),

                        // أزرار الإجراءات
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ خطأ في بناء InventoryTabRiverpod: $e');
      return _buildErrorState('خطأ في تحميل تبويب المخزون');
    }
  }

  Widget _buildShimmerLoading() => ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(AppConstants.spacing16),
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(bottom: AppConstants.spacing12),
            child: ShimmerCard(height: 120),
          );
        },
      );

  Widget _buildErrorState(String errorMessage) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل بيانات المخزون',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeData(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );

  Widget _buildHeader() => StyledSection(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppConstants.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).addInventoryHeader,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  Text(
                    AppLocalizations.of(context).addInventorySubtitle,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildBasicInfoSection() => StyledSection(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Text(
                  AppLocalizations.of(context).basicInfo,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // اسم السلعة
            TextFormField(
              controller: _productNameController,
              style: TextStyle(fontSize: context.responsiveFontSize(16)),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).productNameLabel,
                labelStyle: TextStyle(fontSize: context.responsiveFontSize(16)),
                hintText: AppLocalizations.of(context).productNameHint,
                prefixIcon: Icon(Icons.shopping_bag,
                    color: AppConstants.primaryColor,
                    size: context.isSmallScreen ? 20 : 24),
                contentPadding: context.responsivePadding,
                isDense: context.isSmallScreen,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  borderSide: const BorderSide(
                      color: AppConstants.primaryColor, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: Validators.validateProductName,
              textInputAction: TextInputAction.next,
              onChanged: (String value) {
                ref
                    .read(inventoryStateProvider.notifier)
                    .updateField('productName', value);
              },
            ),
          ],
        ),
      );

  Widget _buildPriceQuantitySection() => StyledSection(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.attach_money,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).priceQuantity,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // صف الأسعار والكمية
            Column(
              children: <Widget>[
                // صف الأسعار
                Row(
                  children: <Widget>[
                    // سعر الجملة
                    Expanded(
                      child: TextFormField(
                        controller: _wholesalePriceController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context).wholesalePriceLabel,
                          hintText: '0',
                          prefixIcon: const Icon(Icons.store,
                              color: AppConstants.primaryColor),
                          suffixText:
                              CurrencyFormatter.formatCurrency(0, context)
                                  .split(' ')[1], // "DZ"
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: Validators.validateWholesalePrice,
                        textInputAction: TextInputAction.next,
                        onChanged: (String value) {
                          ref
                              .read(inventoryStateProvider.notifier)
                              .updateField('wholesalePrice', value);
                        },
                      ),
                    ),

                    const SizedBox(width: AppConstants.defaultPadding),

                    // سعر التجزئة
                    Expanded(
                      child: TextFormField(
                        controller: _retailPriceController,
                        decoration: InputDecoration(
                          labelText: 'سعر التجزئة',
                          hintText: '0',
                          prefixIcon: const Icon(Icons.sell,
                              color: AppConstants.primaryColor),
                          suffixText:
                              CurrencyFormatter.formatCurrency(0, context)
                                  .split(' ')[1], // "DZ"
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال سعر التجزئة';
                          }
                          final int? price = int.tryParse(value);
                          if (price == null || price < 0) {
                            return 'السعر غير صحيح';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                        onChanged: (String value) {
                          ref
                              .read(inventoryStateProvider.notifier)
                              .updateField('retailPrice', value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // صف الكمية
                Row(
                  children: <Widget>[
                    // الكمية
                    Expanded(
                      child: TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)
                              .quantityLabel(0)
                              .replaceAll(': 0', ''),
                          hintText: '0',
                          prefixIcon: const Icon(Icons.inventory,
                              color: AppConstants.primaryColor),
                          suffixText: AppLocalizations.of(context).quantityUnit,
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
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: Validators.validateQuantity,
                        textInputAction: TextInputAction.done,
                        onChanged: (String value) {
                          ref
                              .read(inventoryStateProvider.notifier)
                              .updateField('quantity', value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildAdvancedOptionsSection() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final bool showAdvancedOptions =
              ref.watch(showAdvancedOptionsProvider);
          final String? generatedBarcode = ref.watch(generatedBarcodeProvider);

          return StyledSection(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.settings,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).advancedOptions,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        ref
                            .read(inventoryStateProvider.notifier)
                            .toggleAdvancedOptions();
                      },
                      icon: Icon(
                        showAdvancedOptions
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (showAdvancedOptions) ...<Widget>[
                  const SizedBox(height: AppConstants.defaultPadding),

                  // تاريخ الانتهاء
                  TextFormField(
                    controller: _expiryDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).expiryDateLabel,
                      hintText: AppLocalizations.of(context).expiryDateHint,
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: AppConstants.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        borderSide: const BorderSide(
                            color: AppConstants.primaryColor, width: 2.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_month,
                            color: AppConstants.primaryColor),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            _expiryDateController.text =
                                DateFormat(AppConstants.dateFormat)
                                    .format(picked);
                            ref
                                .read(inventoryStateProvider.notifier)
                                .updateField(
                                    'expiryDate', _expiryDateController.text);
                          }
                        },
                      ),
                    ),
                    onChanged: (String value) {
                      ref
                          .read(inventoryStateProvider.notifier)
                          .updateField('expiryDate', value);
                    },
                  ),

                  const SizedBox(height: AppConstants.defaultPadding),

                  // أزرار الباركود
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _scanBarcode,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(
                              AppLocalizations.of(context).scanBarcodeButton),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.secondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.defaultPadding),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generateBarcodePreview,
                          icon: const Icon(Icons.qr_code),
                          label: Text(AppLocalizations.of(context)
                              .generateBarcodeButton),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConstants.primaryColor,
                            side: const BorderSide(
                                color: AppConstants.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // عرض الباركود المولد أو الممسوح
                  if (generatedBarcode != null) ...<Widget>[
                    const SizedBox(height: AppConstants.defaultPadding),
                    Container(
                      padding:
                          const EdgeInsets.all(AppConstants.defaultPadding),
                      decoration: BoxDecoration(
                        color: AppConstants.successColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                        border: Border.all(
                            color: AppConstants.successColor
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.qr_code,
                              color: AppConstants.successColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  AppLocalizations.of(context).barcodeLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.successColor,
                                  ),
                                ),
                                Text(
                                  generatedBarcode,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16,
                                    color: AppConstants.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: generatedBarcode));
                              _showSnackbar(
                                  AppLocalizations.of(context).copyBarcode);
                            },
                            icon: const Icon(Icons.copy,
                                color: AppConstants.successColor),
                            tooltip:
                                AppLocalizations.of(context).copyBarcodeTooltip,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      );

  Widget _buildActionButtons() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final bool isLoading = ref.watch(inventoryLoadingProvider);
          final bool isFormValid = ref.watch(formValidProvider);

          return StyledSection(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(AppConstants.largePadding),
            child: Column(
              children: <Widget>[
                // زر الإضافة الرئيسي
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed:
                        isLoading || !isFormValid ? null : _addInventoryItem,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add_circle, size: 24),
                    label: Text(
                      isLoading
                          ? AppLocalizations.of(context).addingItem
                          : AppLocalizations.of(context).addItemToInventory,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.defaultPadding),

                // أزرار مساعدة
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearFields,
                        icon: const Icon(Icons.clear_all),
                        label:
                            Text(AppLocalizations.of(context).clearFormButton),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.warningColor,
                          side: const BorderSide(
                              color: AppConstants.warningColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showBulkAddDialog,
                        icon: const Icon(Icons.add_box),
                        label: Text(AppLocalizations.of(context).bulkAddButton),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.secondaryColor,
                          side: const BorderSide(
                              color: AppConstants.secondaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Future<void> _generateBarcodePreview() async {
    final String? success = await ErrorHelper.safeExecute(
      () async {
        await ref.read(inventoryStateProvider.notifier).generateBarcode();
        return 'success';
      },
      userAction: 'توليد باركود جديد',
    );

    if (success != null) {
      _showSnackbar(AppLocalizations.of(context).barcodeGeneratedSuccess);
    }
  }

  Future<void> _scanBarcode() async {
    final String? success = await ErrorHelper.safeExecute(
      () async {
        final String? scannedBarcode = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (BuildContext context) => const BarcodeScannerView(),
          ),
        );

        if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
          // التحقق من أن الباركود غير مستخدم
          final StreamAppProvider appProvider = ref.read(streamAppProvider);
          final bool barcodeExists = await appProvider.inventoryProvider
              .checkBarcodeExists(scannedBarcode);
          if (barcodeExists) {
            _showSnackbar(AppLocalizations.of(context).barcodeAlreadyUsed);
            return '';
          }

          ref.read(inventoryStateProvider.notifier).scanBarcode();
          return scannedBarcode;
        }
        return '';
      },
      userAction: 'مسح باركود',
    );

    if (success != null && success.isNotEmpty) {
      _showSnackbar(AppLocalizations.of(context).barcodeScanSuccess);
    }
  }

  void _showBulkAddDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _BulkAddDialog(
        onItemsAdded: _processBulkItems,
      ),
    );
  }

  Future<void> _processBulkItems(List<Map<String, dynamic>> items) async {
    final Map<String, int>? result = await ErrorHelper.safeExecute(
      () async {
        return await ref
            .read(inventoryStateProvider.notifier)
            .processBulkItems(items);
      },
      userAction: 'معالجة العناصر المجمعة',
    );

    if (result != null) {
      _handleInventoryUpdatedSuccess(
          result['successCount']!, result['errorCount']!);
      _showSnackbar(AppLocalizations.of(context)
          .bulkAddResult(result['successCount']!, result['errorCount']!));
    }
  }

  Future<void> _addInventoryItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final bool success =
        await ref.read(inventoryStateProvider.notifier).addInventoryItem();

    if (success) {
      final String? barcode = ref.read(generatedBarcodeProvider);
      _showSnackbar(
          '${AppLocalizations.of(context).successAdd} • ${AppLocalizations.of(context).barcode}: $barcode');
      _clearFields();
      _handleInventoryItemAddedSuccess();
    }
  }

  void _clearFields() {
    _productNameController.clear();
    _wholesalePriceController.clear();
    _retailPriceController.clear();
    _quantityController.clear();
    _expiryDateController.clear();
    ref.read(inventoryStateProvider.notifier).clearForm();
  }

  /// معالجة نجاح تحديث المخزون
  void _handleInventoryUpdatedSuccess(int successCount, int errorCount) {
    try {
      widget.onInventoryUpdated();
      HapticFeedback.mediumImpact();
      debugPrint('✅ تمت معالجة نجاح تحديث المخزون: $successCount عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة نجاح تحديث المخزون: $e');
    }
  }

  /// معالجة نجاح إضافة عنصر مخزون
  void _handleInventoryItemAddedSuccess() {
    try {
      widget.onInventoryUpdated();
      HapticFeedback.mediumImpact();
      debugPrint('✅ تمت معالجة نجاح إضافة عنصر المخزون');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة نجاح إضافة عنصر المخزون: $e');
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
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
    }
  }
}

class _BulkAddDialog extends ConsumerStatefulWidget {
  const _BulkAddDialog({
    required this.onItemsAdded,
  });
  final void Function(List<Map<String, dynamic>>) onItemsAdded;

  @override
  ConsumerState<_BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends ConsumerState<_BulkAddDialog> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  final bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // العنوان
              Row(
                children: <Widget>[
                  const Icon(Icons.add_box, color: AppConstants.primaryColor),
                  const SizedBox(width: AppConstants.smallPadding),
                  Text(
                    AppLocalizations.of(context).bulkAddTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // التعليمات
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppLocalizations.of(context).inputInstructions,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).inputInstructionsText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).inputFormat,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).inputExample,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // حقل النص
              TextField(
                controller: _textController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).productDataLabel,
                  hintText: AppLocalizations.of(context).productDataHint,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: const BorderSide(
                        color: AppConstants.primaryColor, width: 2.0),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // معاينة البيانات
              if (_items.isNotEmpty) ...<Widget>[
                Text(
                  AppLocalizations.of(context).dataPreview,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> item = _items[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            item['name']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'السعر: ${CurrencyFormatter.formatCurrency(((item['wholesalePrice'] as num?) ?? 0).toDouble(), context)} | الكمية: ${item['quantity']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _items.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // أزرار الإجراءات
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _parseData,
                      child: Text(AppLocalizations.of(context).analyzeData),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing || _items.isEmpty ? null : _addItems,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(AppLocalizations.of(context)
                              .addItems(_items.length)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  void _parseData() {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;

    final List<String> lines = text.split('\n');
    final List<Map<String, dynamic>> parsedItems = <Map<String, dynamic>>[];

    for (final String line in lines) {
      final String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final List<String> parts = trimmedLine.split('|');
      if (parts.length < 3) continue;

      try {
        final String name = parts[0].trim();
        final int wholesalePrice = int.tryParse(parts[1].trim()) ?? 0;
        final int quantity = int.tryParse(parts[2].trim()) ?? 0;
        final String? expiryDateStr = parts.length > 3 ? parts[3].trim() : null;

        if (name.isNotEmpty && wholesalePrice > 0 && quantity > 0) {
          parsedItems.add(<String, dynamic>{
            'name': name,
            'wholesalePrice': wholesalePrice,
            'quantity': quantity,
            'expiryDate':
                expiryDateStr?.isNotEmpty == true ? expiryDateStr : null,
          });
        }
      } catch (e) {
        // تجاهل السطور غير الصحيحة
      }
    }

    setState(() {
      _items.clear();
      _items.addAll(parsedItems);
    });
  }

  void _addItems() {
    if (_items.isNotEmpty) {
      widget.onItemsAdded(_items);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }
}
