import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../providers/stream_app_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/snackbar_utils.dart';
import '../utils/validators.dart';

/// حوار تعديل عنصر المخزون المحسن
class ModernEditInventoryDialog extends StatefulWidget {
  const ModernEditInventoryDialog({
    super.key,
    required this.item,
    required this.onItemUpdated,
  });

  final InventoryItem item;
  final VoidCallback onItemUpdated;

  @override
  State<ModernEditInventoryDialog> createState() =>
      _ModernEditInventoryDialogState();
}

class _ModernEditInventoryDialogState extends State<ModernEditInventoryDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _quantityController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _barcode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _wholesalePriceController =
        TextEditingController(text: widget.item.wholesalePrice.toString());
    _retailPriceController =
        TextEditingController(text: widget.item.retailPrice.toString());
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _barcode = widget.item.barcode;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _quantityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
        ),
        elevation: 8,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (BuildContext context, Widget? child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: ConstrainedBox(
              constraints: context.dialogConstraints,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius * 2),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildHeader(context),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: context.responsiveScrollPhysics,
                        child: _buildContent(context),
                      ),
                    ),
                    _buildActions(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// بناء رأس الحوار
  Widget _buildHeader(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blue[600]!,
              Colors.blue[400]!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.borderRadius * 2),
            topRight: Radius.circular(AppConstants.borderRadius * 2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                Icons.inventory,
                color: Colors.white,
                size: context.isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'تعديل عنصر المخزون',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.item.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: context.responsiveFontSize(12),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.close, color: Colors.white),
              padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  /// بناء محتوى الحوار
  Widget _buildContent(BuildContext context) => Padding(
        padding: context.responsivePadding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // معلومات العنصر
              _buildInfoCard(context),
              SizedBox(height: context.responsiveSpacing),

              // حقول التعديل
              _buildEditFields(context),
            ],
          ),
        ),
      );

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.info_outline,
                    color: Colors.green[600],
                    size: context.isSmallScreen ? 18 : 22),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Text(
                  'معلومات العنصر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    fontSize: context.responsiveFontSize(14),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            if (context.shouldUseVerticalLayout) Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildInfoItem(context, 'الباركود',
                          _barcode ?? 'غير محدد', Icons.qr_code),
                      SizedBox(height: context.responsiveSpacing * 0.5),
                      _buildInfoItem(
                          context,
                          'تاريخ الإضافة',
                          widget.item.addedDate.toString().split(' ')[0],
                          Icons.calendar_today),
                    ],
                  ) else Row(
                    children: <Widget>[
                      Expanded(
                        child: _buildInfoItem(context, 'الباركود',
                            _barcode ?? 'غير محدد', Icons.qr_code),
                      ),
                      SizedBox(width: context.responsiveSpacing * 0.5),
                      Expanded(
                        child: _buildInfoItem(
                            context,
                            'تاريخ الإضافة',
                            widget.item.addedDate.toString().split(' ')[0],
                            Icons.calendar_today),
                      ),
                    ],
                  ),
            if (widget.item.expiryDate != null) ...<Widget>[
              SizedBox(height: context.responsiveSpacing * 0.5),
              _buildInfoItem(
                  context,
                  'تاريخ الانتهاء',
                  widget.item.expiryDate!.toString().split(' ')[0],
                  Icons.event),
            ],
          ],
        ),
      );

  /// بناء عنصر معلومات
  Widget _buildInfoItem(
          BuildContext context, String label, String value, IconData icon) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon,
              size: context.isSmallScreen ? 14 : 16, color: Colors.green[600]),
          SizedBox(width: context.responsiveSpacing * 0.25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(11),
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(11),
                    color: Colors.green[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      );

  /// بناء حقول التعديل
  Widget _buildEditFields(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'تعديل البيانات',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),

          // اسم المنتج
          _buildTextField(
            context: context,
            controller: _nameController,
            label: 'اسم المنتج',
            icon: Icons.label,
            color: Colors.blue,
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'اسم المنتج مطلوب';
              }
              return null;
            },
          ),

          SizedBox(height: context.responsiveSpacing),

          // الأسعار - responsive layout
          if (context.shouldUseVerticalLayout) Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildTextField(
                      context: context,
                      controller: _wholesalePriceController,
                      label: 'سعر الجملة',
                      icon: Icons.attach_money,
                      color: Colors.green,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'سعر الجملة مطلوب';
                        }
                        final int? price = int.tryParse(value.trim());
                        if (price == null || price <= 0) {
                          return 'يجب أن يكون السعر أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing),
                    _buildTextField(
                      context: context,
                      controller: _retailPriceController,
                      label: 'سعر التجزئة',
                      icon: Icons.sell,
                      color: Colors.orange,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'سعر التجزئة مطلوب';
                        }
                        final int? price = int.tryParse(value.trim());
                        if (price == null || price <= 0) {
                          return 'يجب أن يكون السعر أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                  ],
                ) else Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildTextField(
                        context: context,
                        controller: _wholesalePriceController,
                        label: 'سعر الجملة',
                        icon: Icons.attach_money,
                        color: Colors.green,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'سعر الجملة مطلوب';
                          }
                          final int? price = int.tryParse(value.trim());
                          if (price == null || price <= 0) {
                            return 'يجب أن يكون السعر أكبر من صفر';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: _buildTextField(
                        context: context,
                        controller: _retailPriceController,
                        label: 'سعر التجزئة',
                        icon: Icons.sell,
                        color: Colors.orange,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'سعر التجزئة مطلوب';
                          }
                          final int? price = int.tryParse(value.trim());
                          if (price == null || price <= 0) {
                            return 'يجب أن يكون السعر أكبر من صفر';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

          SizedBox(height: context.responsiveSpacing),

          // الكمية
          _buildTextField(
            context: context,
            controller: _quantityController,
            label: 'الكمية',
            icon: Icons.inventory_2,
            color: Colors.blue,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'الكمية مطلوبة';
              }
              final int? quantity = int.tryParse(value.trim());
              if (quantity == null || quantity < 0) {
                return 'يجب أن تكون الكمية أكبر من أو تساوي صفر';
              }
              return null;
            },
          ),

          SizedBox(height: context.responsiveSpacing),

          // ملخص التغييرات
          _buildChangesSummary(),
        ],
      );

  /// بناء حقل نص
  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required String? Function(String?) validator,
  }) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(fontSize: context.responsiveFontSize(14)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
            prefixIcon:
                Icon(icon, color: color, size: context.isSmallScreen ? 20 : 24),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: color.withOpacity(0.05),
            contentPadding: context.responsivePadding,
            isDense: context.isSmallScreen,
          ),
          validator: validator,
          onChanged: (_) => setState(() {}), // لإعادة حساب الملخص
        ),
      );

  /// بناء ملخص التغييرات
  Widget _buildChangesSummary() => Container(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.analytics, color: Colors.purple[600]),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'ملخص التغييرات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildSummaryItem(
                    'القيمة الإجمالية',
                    '${_calculateTotalValue()} DZ',
                    Colors.purple[600]!,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'الكمية الحالية',
                    _quantityController.text.isEmpty
                        ? '0'
                        : _quantityController.text,
                    Colors.orange[600]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// بناء عنصر ملخص
  Widget _buildSummaryItem(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  /// بناء أزرار الإجراءات
  Widget _buildActions(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppConstants.borderRadius * 2),
            bottomRight: Radius.circular(AppConstants.borderRadius * 2),
          ),
        ),
        child: context.shouldUseVerticalLayout
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateItem,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isLoading ? 'جاري الحفظ...' : 'حفظ التغييرات',
                      style:
                          TextStyle(fontSize: context.responsiveFontSize(14)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsiveSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: Text('إلغاء',
                        style: TextStyle(
                            fontSize: context.responsiveFontSize(14))),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                          vertical: context.responsiveSpacing),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                      icon: const Icon(Icons.cancel, size: 18),
                      label: Text('إلغاء',
                          style: TextStyle(
                              fontSize: context.responsiveFontSize(14))),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: context.responsiveSpacing),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateItem,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, size: 18),
                      label: Text(
                        _isLoading ? 'جاري الحفظ...' : 'حفظ',
                        style:
                            TextStyle(fontSize: context.responsiveFontSize(14)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            vertical: context.responsiveSpacing),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );

  /// حساب القيمة الإجمالية
  int _calculateTotalValue() {
    final int? price = int.tryParse(_retailPriceController.text);
    final int? quantity = int.tryParse(_quantityController.text);

    if (price != null && quantity != null) {
      return price * quantity;
    }
    return 0;
  }

  /// تحديث العنصر
  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من صحة السعرين معاً
    final String? priceValidationError = Validators.validatePrices(
      _wholesalePriceController.text.trim(),
      _retailPriceController.text.trim(),
    );

    if (priceValidationError != null) {
      SnackbarUtils.showError(context, priceValidationError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String name = Validators.cleanText(_nameController.text);
      final int wholesalePrice =
          int.parse(_wholesalePriceController.text.trim());
      final int retailPrice = int.parse(_retailPriceController.text.trim());
      final int quantity = int.parse(_quantityController.text.trim());

      final InventoryItem updatedItem = widget.item.copyWith(
        name: name,
        wholesalePrice: wholesalePrice,
        retailPrice: retailPrice,
        quantity: quantity,
      );

      if (updatedItem.id != null) {
        final StreamAppProvider appProvider = context.read<StreamAppProvider>();
        await appProvider.inventoryProvider.updateInventoryItem(updatedItem);
      }

      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        SnackbarUtils.showSuccess(context, 'تم تحديث عنصر المخزون بنجاح');
        widget.onItemUpdated();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحديث عنصر المخزون: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
