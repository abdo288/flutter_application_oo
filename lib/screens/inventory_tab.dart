import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../database/drift_database.dart';
import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../providers/stream_app_provider.dart';
import '../providers/stream_inventory_provider.dart';
import '../services/error_handler_service.dart';
import '../services/inventory_alert_service.dart';
import '../services/unified_sync_manager.dart';
// ✅ إضافة الخدمات الجديدة
import '../services/app_event_bus.dart';
import '../services/app_state_manager.dart';
import '../services/navigation_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/validators.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/styled_section.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({
    super.key,
    required this.onInventoryUpdated,
  });
  final VoidCallback onInventoryUpdated;

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab>
    with AutomaticKeepAliveClientMixin<InventoryTab> {
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _wholesalePriceController =
      TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showAdvancedOptions = false;
  String? _generatedBarcode;

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

  /// Pull-to-refresh لإعادة تحميل بيانات المخزون
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 بدء تحديث بيانات المخزون...');

      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // التأكد من أن التطبيق مهيأ
      if (!appProvider.isInitialized) {
        debugPrint('⚠️ التطبيق لم يتم تهيئته بعد');
        return;
      }

      await appProvider.refreshAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
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
              children: [
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
    return Consumer<StreamAppProvider>(
      builder:
          (BuildContext context, StreamAppProvider appProvider, Widget? child) {
        // التحقق من أن Provider مهيأ
        if (!appProvider.isInitialized) {
          return _buildShimmerLoading();
        }

        final StreamInventoryProvider inventoryProvider =
            appProvider.inventoryProvider;

        // التحقق من حالة التحميل
        if (inventoryProvider.isLoading &&
            inventoryProvider.inventoryItems.isEmpty) {
          return _buildShimmerLoading();
        }

        // التحقق من وجود خطأ
        if (inventoryProvider.errorMessage != null) {
          return Center(
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
                  inventoryProvider.errorMessage!,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    inventoryProvider.initialize();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
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
                edgeOffset: 0.0,
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
          debugPrint('❌ خطأ في بناء InventoryTab: $e');
          return Center(
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
                  'خطأ في تحميل تبويب المخزون',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                SizedBox(height: context.responsiveSpacing * 0.5),
                Text(
                  'يرجى إعادة تشغيل التطبيق',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildAdvancedOptionsSection() => StyledSection(
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
                    setState(() {
                      _showAdvancedOptions = !_showAdvancedOptions;
                    });
                  },
                  icon: Icon(
                    _showAdvancedOptions
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            if (_showAdvancedOptions) ...<Widget>[
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
                            DateFormat(AppConstants.dateFormat).format(picked);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.defaultPadding),

              // أزرار الباركود
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.qr_code_scanner),
                      label:
                          Text(AppLocalizations.of(context).scanBarcodeButton),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateBarcodePreview,
                      icon: const Icon(Icons.qr_code),
                      label: Text(
                          AppLocalizations.of(context).generateBarcodeButton),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                        side:
                            const BorderSide(color: AppConstants.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // عرض الباركود المولد أو الممسوح
              if (_generatedBarcode != null) ...<Widget>[
                const SizedBox(height: AppConstants.defaultPadding),
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    border: Border.all(
                        color:
                            AppConstants.successColor.withValues(alpha: 0.3)),
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
                              _generatedBarcode!,
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
                              ClipboardData(text: _generatedBarcode!));
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

  Widget _buildActionButtons() => StyledSection(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: <Widget>[
            // زر الإضافة الرئيسي
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addInventoryItem,
                icon: _isLoading
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
                  _isLoading
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
                    label: Text(AppLocalizations.of(context).clearFormButton),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.warningColor,
                      side: const BorderSide(color: AppConstants.warningColor),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
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
                      side:
                          const BorderSide(color: AppConstants.secondaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Future<void> _generateBarcodePreview() async {
    final String? success = await ErrorHelper.safeExecute(
      () async {
        final String barcode = await _generateUniqueBarcode();
        if (mounted) {
          setState(() {
            _generatedBarcode = barcode;
            _showAdvancedOptions = true;
          });
        }
        return barcode;
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
          // التحقق من أن الباركود غير مستخدم عبر المزود
          final StreamAppProvider appProvider =
              context.read<StreamAppProvider>();
          final StreamInventoryProvider inventoryProvider =
              appProvider.inventoryProvider;
          final bool barcodeExists =
              await inventoryProvider.checkBarcodeExists(scannedBarcode);
          if (barcodeExists) {
            _showSnackbar(AppLocalizations.of(context).barcodeAlreadyUsed);
            return '';
          }

          if (mounted) {
            setState(() {
              _generatedBarcode = scannedBarcode;
              _showAdvancedOptions = true;
            });
          }
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
    setState(() {
      _isLoading = true;
    });

    final Map<String, int>? result = await ErrorHelper.safeExecute(
      () async {
        int successCount = 0;
        int errorCount = 0;

        for (final Map<String, dynamic> itemData in items) {
          try {
            final String name = itemData['name']?.toString().trim() ?? '';
            final int wholesalePrice =
                int.tryParse(itemData['wholesalePrice']?.toString() ?? '0') ??
                    0;
            final int retailPrice =
                int.tryParse(itemData['retailPrice']?.toString() ?? '0') ?? 0;
            final int quantity =
                int.tryParse(itemData['quantity']?.toString() ?? '0') ?? 0;
            final DateTime? expiryDate = itemData['expiryDate'] != null
                ? DateFormat(AppConstants.dateFormat)
                    .parse(itemData['expiryDate'].toString())
                : null;

            if (name.isEmpty ||
                wholesalePrice <= 0 ||
                retailPrice <= 0 ||
                quantity <= 0) {
              errorCount++;
              continue;
            }

            // التحقق من وجود الاسم عبر المزود لسرعة وتحديث متفائل
            final StreamAppProvider appProvider =
                context.read<StreamAppProvider>();
            final StreamInventoryProvider inventoryProvider =
                appProvider.inventoryProvider;
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
              await inventoryProvider.addInventoryItem(item);
              successCount++;
            } else {
              errorCount++;
            }
          } catch (e) {
            errorCount++;
          }
        }

        return <String, int>{
          'successCount': successCount,
          'errorCount': errorCount,
        };
      },
      userAction: 'معالجة العناصر المجمعة',
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result != null) {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;
      await InventoryAlertService.checkInventoryAlerts(inventoryProvider);
      // ✅ تحسين Callback مع إرسال البيانات
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

    setState(() {
      _isLoading = true;
    });

    final String name = Validators.cleanText(_productNameController.text);
    final int wholesalePrice =
        int.tryParse(_wholesalePriceController.text) ?? 0;
    final int retailPrice = int.tryParse(_retailPriceController.text) ?? 0;
    final int quantity = int.tryParse(_quantityController.text) ?? 0;
    final DateTime? expiryDate = (_expiryDateController.text.trim().isEmpty)
        ? null
        : DateFormat(AppConstants.dateFormat)
            .parse(_expiryDateController.text.trim());
    // استخدام الباركود المولد مسبقاً أو توليد واحد جديد
    final String barcode = _generatedBarcode ?? await _generateUniqueBarcode();

    // التحقق من وجود الاسم في المخزون عبر المزود
    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;

      // التحقق من أن Provider مهيأ
      if (!appProvider.isInitialized) {
        _showSnackbar('التطبيق لا يزال في مرحلة التهيئة، يرجى المحاولة لاحقاً');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final bool nameExists = inventoryProvider.inventoryItems
          .any((InventoryItem i) => i.name == name);
      if (nameExists) {
        _showSnackbar(AppLocalizations.of(context).productNameExists);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود الاسم: $e');
      _showSnackbar('خطأ في التحقق من البيانات، يرجى المحاولة مرة أخرى');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

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
      _showSnackbar(AppConstants.errorValidation);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    // استخدم ErrorHelper.safeExecute لتنفيذ العملية بأمان
    final bool? success = await ErrorHelper.safeExecute(
      () async {
        final StreamAppProvider appProvider = context.read<StreamAppProvider>();
        final StreamInventoryProvider inventoryProvider =
            appProvider.inventoryProvider;
        await inventoryProvider.addInventoryItem(item);

        // ✅ فحص حالة المزامنة بعد الإضافة
        await _checkSyncStatus();

        // فحص التنبيهات بعد إضافة العنصر
        await InventoryAlertService.checkInventoryAlerts(inventoryProvider);
        return true;
      },
      userAction: 'إضافة عنصر جديد للمخزون من شاشة المخزون',
    );

    if (success != null) {
      _showSnackbar(
          '${AppLocalizations.of(context).successAdd} • ${AppLocalizations.of(context).barcode}: $barcode');
      _clearFields();

      // ✅ تحسين Callback مع إرسال البيانات
      _handleInventoryItemAddedSuccess(item);

      // إرسال أحداث التواصل
      _sendSuccessEvents(item);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFields() {
    setState(() {
      _productNameController.clear();
      _wholesalePriceController.clear();
      _retailPriceController.clear();
      _quantityController.clear();
      _expiryDateController.clear();
      _generatedBarcode = null;
      _showAdvancedOptions = false;
    });
  }

  Future<String> _generateUniqueBarcode() async {
    return await ErrorHelper.safeExecute(
          () async {
            // توليد رقم مكون من 12 خانة بناءً على الوقت + عشوائية بسيطة
            String candidate() {
              final int micros = DateTime.now().microsecondsSinceEpoch;
              final String base =
                  (micros % 1000000000000).toString().padLeft(12, '0');
              return base;
            }

            String code = candidate();
            int attempts = 0;
            final StreamAppProvider appProvider =
                context.read<StreamAppProvider>();
            final StreamInventoryProvider inventoryProvider =
                appProvider.inventoryProvider;
            while (await inventoryProvider.checkBarcodeExists(code) &&
                attempts < 5) {
              code = candidate();
              attempts++;
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            // في حال نادر جداً، أضف لاحقة بسيطة
            if (await inventoryProvider.checkBarcodeExists(code)) {
              code =
                  // ignore: lines_longer_than_80_chars
                  '${(int.parse(code.substring(0, 11)) % 100000000000).toString().padLeft(11, '0')}9';
            }
            return code;
          },
          userAction: 'توليد باركود فريد',
        ) ??
        '000000000000'; // باركود افتراضي في حالة الفشل
  }

  /// ✅ معالجة نجاح تحديث المخزون مع تحسينات
  void _handleInventoryUpdatedSuccess(int successCount, int errorCount) {
    try {
      // 1. استدعاء Callback الأصلي
      widget.onInventoryUpdated();

      // 2. إرسال حدث Event Bus
      AppEventBus.fire(InventoryUpdatedEvent(
        'bulk_update',
        'Bulk Update',
        0, // oldQuantity
        successCount, // newQuantity
        sourceTab: 'Inventory',
      ));

      // 3. تحديث AppStateManager
      final appStateManager = context.read<AppStateManager>();
      appStateManager.updateStats({
        'inventoryCount':
            (appStateManager.getStat<int>('inventoryCount') ?? 0) +
                successCount,
        'lastInventoryUpdate': DateTime.now().toIso8601String(),
        'bulkUpdateSuccess': successCount,
        'bulkUpdateErrors': errorCount,
      });

      // 4. إظهار إشعار محلي
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تم تحديث $successCount عنصر مخزون'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'عرض',
            textColor: Colors.white,
            onPressed: () {
              // الانتقال إلى Inventory مع فلتر العناصر المحدثة
              NavigationService.navigateWithFilter(
                2, // Inventory tab index
                'recentlyUpdated',
                true,
                sourceTab: 'Inventory',
              );
            },
          ),
        ),
      );

      // 5. Haptic Feedback
      HapticFeedback.mediumImpact();

      debugPrint('✅ تمت معالجة نجاح تحديث المخزون: $successCount عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة نجاح تحديث المخزون: $e');
    }
  }

  /// ✅ معالجة نجاح إضافة عنصر مخزون مع تحسينات
  void _handleInventoryItemAddedSuccess(InventoryItem item) {
    try {
      // 1. استدعاء Callback الأصلي
      widget.onInventoryUpdated();

      // 2. إرسال حدث Event Bus
      AppEventBus.fire(InventoryItemAddedEvent(item, sourceTab: 'Inventory'));

      // 3. تحديث AppStateManager
      final appStateManager = context.read<AppStateManager>();
      appStateManager.setSharedData('lastAddedInventoryItem', item);
      appStateManager.updateStats({
        'inventoryCount':
            (appStateManager.getStat<int>('inventoryCount') ?? 0) + 1,
        'lastInventoryAdded': DateTime.now().toIso8601String(),
      });

      // 4. إظهار إشعار محلي
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ تمت إضافة "${item.name}" بنجاح'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'عرض',
            textColor: Colors.white,
            onPressed: () {
              // الانتقال إلى Inventory مع تمييز العنصر الجديد
              NavigationService.navigateWithHighlight(
                2, // Inventory tab index
                item.id ?? '',
                sourceTab: 'Inventory',
              );
            },
          ),
        ),
      );

      // 5. Haptic Feedback
      HapticFeedback.mediumImpact();

      debugPrint('✅ تمت معالجة نجاح إضافة عنصر المخزون: ${item.name}');
    } catch (e) {
      debugPrint('❌ خطأ في معالجة نجاح إضافة عنصر المخزون: $e');
    }
  }

  void _sendSuccessEvents(InventoryItem item) {
    try {
      // StreamProviders تقوم بتحديث الواجهات تلقائياً عند تغير البيانات
      // لا نحتاج إلى إرسال أحداث معقدة
      debugPrint(
          '✅ تم إضافة عنصر المخزون بنجاح - StreamProviders ستقوم بتحديث الواجهات تلقائياً');

      debugPrint('📡 تم إرسال أحداث النجاح للتبويبات الأخرى');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال أحداث النجاح: $e');
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

  /// فحص حالة المزامنة
  Future<void> _checkSyncStatus() async {
    try {
      final UnifiedSyncManager syncManager = UnifiedSyncManager();

      // التحقق من وجود عمليات معلقة
      final AppDatabase db = AppDatabase.instance;
      final int pendingCount = await db.getUnprocessedOperationsCount();

      if (pendingCount > 0) {
        debugPrint(
            '�� يوجد $pendingCount عملية معلقة - تشغيل المزامنة الفورية');
        await syncManager.performImmediateSync();
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص حالة المزامنة: $e');
    }
  }
}

class _BulkAddDialog extends StatefulWidget {
  const _BulkAddDialog({
    required this.onItemsAdded,
  });
  final void Function(List<Map<String, dynamic>>) onItemsAdded;

  @override
  State<_BulkAddDialog> createState() => _BulkAddDialogState();
}

class _BulkAddDialogState extends State<_BulkAddDialog> {
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

// إضافة دالة Shimmer Loading للمخزون
extension on _InventoryTabState {
  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(AppConstants.spacing16),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: AppConstants.spacing12),
          child: ShimmerCard(height: 120),
        );
      },
    );
  }
}
