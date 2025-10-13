import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../repositories/unified_repository.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/snackbar_utils.dart';
import '../utils/validators.dart';

/// حوار تعديل المنتج المحسن
class ModernEditProductDialog extends StatefulWidget {
  const ModernEditProductDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  final Product product;
  final VoidCallback onProductUpdated;

  @override
  State<ModernEditProductDialog> createState() =>
      _ModernEditProductDialogState();
}

class _ModernEditProductDialogState extends State<ModernEditProductDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _wholesaleController;
  late TextEditingController _retailController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _wholesaleController =
        TextEditingController(text: widget.product.wholesalePrice.toString());
    _retailController =
        TextEditingController(text: widget.product.retailPrice.toString());

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
    _wholesaleController.dispose();
    _retailController.dispose();
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
              Colors.purple[600]!,
              Colors.purple[400]!,
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
                Icons.edit,
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
                    'تعديل المنتج',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.product.name,
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
              onPressed: () => Navigator.of(context).pop(),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // معلومات المنتج
              _buildInfoCard(context),
              SizedBox(height: context.responsiveSpacing),

              // حقول التعديل
              _buildPriceFields(context),
            ],
          ),
        ),
      );

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.info_outline,
                color: Colors.blue[600], size: context.isSmallScreen ? 18 : 22),
            SizedBox(width: context.responsiveSpacing * 0.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'معلومات المنتج',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                  Text(
                    'الاسم: ${widget.product.name}',
                    style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: context.responsiveFontSize(12)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'تاريخ الإضافة: ${widget.product.savedAt.toString().split(' ')[0]}',
                    style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: context.responsiveFontSize(12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء حقول الأسعار
  Widget _buildPriceFields(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'تعديل الأسعار',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),

          // سعر الجملة
          _buildPriceField(
            context: context,
            controller: _wholesaleController,
            label: 'سعر الجملة',
            icon: Icons.store,
            color: Colors.green,
            validator: (String? value) {
              return Validators.validateWholesalePrice(value);
            },
          ),

          SizedBox(height: context.responsiveSpacing),

          // سعر التجزئة
          _buildPriceField(
            context: context,
            controller: _retailController,
            label: 'سعر التجزئة',
            icon: Icons.shopping_cart,
            color: Colors.orange,
            validator: (String? value) {
              return Validators.validateRetailPrice(value);
            },
          ),

          SizedBox(height: context.responsiveSpacing),

          // حساب الربح
          _buildProfitCalculation(context),
        ],
      );

  /// بناء حقل السعر
  Widget _buildPriceField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required String? Function(String?) validator,
  }) =>
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
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
          onChanged: (_) => setState(() {}), // لإعادة حساب الربح
        ),
      );

  /// بناء حساب الربح
  Widget _buildProfitCalculation(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.trending_up,
                color: Colors.purple[600],
                size: context.isSmallScreen ? 18 : 22),
            SizedBox(width: context.responsiveSpacing * 0.5),
            Flexible(
              child: Text(
                'الربح المتوقع: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                  fontSize: context.responsiveFontSize(14),
                ),
              ),
            ),
            Text(
              '${_calculateProfit()} DZ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.purple[600],
                fontSize: context.responsiveFontSize(16),
              ),
            ),
          ],
        ),
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
                    onPressed: _isLoading ? null : _updateProduct,
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
                      backgroundColor: Colors.purple,
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
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
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
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
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
                      onPressed: _isLoading ? null : _updateProduct,
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
                        backgroundColor: Colors.purple,
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

  /// حساب الربح
  int _calculateProfit() {
    final int? wholesale = int.tryParse(_wholesaleController.text);
    final int? retail = int.tryParse(_retailController.text);

    if (wholesale != null && retail != null && retail > wholesale) {
      return retail - wholesale;
    }
    return 0;
  }

  /// تحديث المنتج
  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // التحقق من صحة السعرين معاً
    final String? priceValidationError = Validators.validatePrices(
      _wholesaleController.text.trim(),
      _retailController.text.trim(),
    );

    if (priceValidationError != null) {
      SnackbarUtils.showError(context, priceValidationError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int wholesalePrice = int.parse(_wholesaleController.text.trim());
      final int retailPrice = int.parse(_retailController.text.trim());

      final Product updatedProduct = widget.product.copyWith(
        wholesalePrice: wholesalePrice,
        retailPrice: retailPrice,
      );

      final UnifiedRepository repository = UnifiedRepository();
      await repository.updateProduct(updatedProduct);

      if (mounted) {
        Navigator.of(context).pop();
        SnackbarUtils.showSuccess(context, 'تم تحديث المنتج بنجاح');
        widget.onProductUpdated();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحديث المنتج: $e');
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
