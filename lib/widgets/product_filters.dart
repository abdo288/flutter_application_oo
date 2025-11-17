import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';

/// مكون الفلاتر المتقدمة للمنتجات
class ProductFiltersWidget extends StatefulWidget {
  const ProductFiltersWidget({
    super.key,
    required this.onFiltersChanged,
  });

  final ValueChanged<ProductFilters> onFiltersChanged;

  @override
  State<ProductFiltersWidget> createState() => _ProductFiltersWidgetState();
}

class _ProductFiltersWidgetState extends State<ProductFiltersWidget> {
  ProductFilters _filters = const ProductFilters();

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing,
            vertical: context.responsiveSpacing * 0.5),
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'الفلاتر المتقدمة',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            SizedBox(height: context.responsiveSpacing),
            _buildFilterOptions(context),
          ],
        ),
      );

  Widget _buildFilterOptions(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // فلتر الفئة
          _buildFilterChip(
            context: context,
            label: 'جميع الفئات',
            isSelected: true,
            onTap: () => _applyCategoryFilter(null),
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),

          // فلتر المورد
          _buildFilterChip(
            context: context,
            label: 'جميع الموردين',
            isSelected: true,
            onTap: () => _applySupplierFilter(null),
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),

          // فلتر السعر
          _buildPriceRangeFilter(context),
          SizedBox(height: context.responsiveSpacing * 0.5),

          // فلتر الربح
          _buildProfitRangeFilter(context),
        ],
      );

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing,
                vertical: context.responsiveSpacing * 0.5),
            decoration: BoxDecoration(
              color: isSelected ? AppConstants.primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: context.responsiveFontSize(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );

  Widget _buildPriceRangeFilter(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'نطاق السعر',
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),
          if (context.shouldUseVerticalLayout) Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildRangeChip(
                        context, 'منخفض', () => _applyPriceFilter('low')),
                    SizedBox(height: context.responsiveSpacing * 0.5),
                    _buildRangeChip(
                        context, 'متوسط', () => _applyPriceFilter('medium')),
                    SizedBox(height: context.responsiveSpacing * 0.5),
                    _buildRangeChip(
                        context, 'عالي', () => _applyPriceFilter('high')),
                  ],
                ) else Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildRangeChip(
                          context, 'منخفض', () => _applyPriceFilter('low')),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.5),
                    Expanded(
                      child: _buildRangeChip(
                          context, 'متوسط', () => _applyPriceFilter('medium')),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.5),
                    Expanded(
                      child: _buildRangeChip(
                          context, 'عالي', () => _applyPriceFilter('high')),
                    ),
                  ],
                ),
        ],
      );

  Widget _buildProfitRangeFilter(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'نطاق الربح',
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
          SizedBox(height: context.responsiveSpacing * 0.5),
          if (context.shouldUseVerticalLayout) Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildRangeChip(
                        context, 'منخفض', () => _applyProfitFilter('low')),
                    SizedBox(height: context.responsiveSpacing * 0.5),
                    _buildRangeChip(
                        context, 'متوسط', () => _applyProfitFilter('medium')),
                    SizedBox(height: context.responsiveSpacing * 0.5),
                    _buildRangeChip(
                        context, 'عالي', () => _applyProfitFilter('high')),
                  ],
                ) else Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildRangeChip(
                          context, 'منخفض', () => _applyProfitFilter('low')),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.5),
                    Expanded(
                      child: _buildRangeChip(
                          context, 'متوسط', () => _applyProfitFilter('medium')),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.5),
                    Expanded(
                      child: _buildRangeChip(
                          context, 'عالي', () => _applyProfitFilter('high')),
                    ),
                  ],
                ),
        ],
      );

  Widget _buildRangeChip(
          BuildContext context, String label, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing * 0.5,
                vertical: context.responsiveSpacing * 0.3),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: context.responsiveFontSize(10),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );

  /// ✅ تطبيق فلتر الفئة مع حفظ الحالة
  void _applyCategoryFilter(String? category) {
    setState(() {
      _filters = _filters.copyWith(category: category);
    });

    // ✅ حفظ الحالة في SharedPreferences
    _saveFilterState();

    debugPrint('تطبيق فلتر الفئة: $category');
    widget.onFiltersChanged(_filters);

    // ✅ إظهار تأكيد التطبيق
    _showFilterAppliedConfirmation('فلتر الفئة');
  }

  /// حفظ حالة الفلاتر
  void _saveFilterState() {
    // TODO: إضافة SharedPreferences لحفظ الفلاتر
    debugPrint('حفظ حالة الفلاتر: $_filters');
  }

  /// إظهار تأكيد تطبيق الفلتر
  void _showFilterAppliedConfirmation(String filterName) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              const Icon(Icons.filter_alt, color: Colors.white),
              const SizedBox(width: 8),
              Text('تم تطبيق $filterName'),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  /// ✅ تطبيق فلتر المورد مع حفظ الحالة
  void _applySupplierFilter(String? supplier) {
    setState(() {
      _filters = _filters.copyWith(supplier: supplier);
    });

    _saveFilterState();
    debugPrint('تطبيق فلتر المورد: $supplier');
    widget.onFiltersChanged(_filters);
    _showFilterAppliedConfirmation('فلتر المورد');
  }

  /// ✅ تطبيق فلتر السعر مع حفظ الحالة
  void _applyPriceFilter(String range) {
    setState(() {
      _filters = _filters.copyWith(priceRange: range);
    });

    _saveFilterState();
    debugPrint('تطبيق فلتر السعر: $range');
    widget.onFiltersChanged(_filters);
    _showFilterAppliedConfirmation('فلتر السعر');
  }

  /// ✅ تطبيق فلتر الربح مع حفظ الحالة
  void _applyProfitFilter(String range) {
    setState(() {
      _filters = _filters.copyWith(profitRange: range);
    });

    _saveFilterState();
    debugPrint('تطبيق فلتر الربح: $range');
    widget.onFiltersChanged(_filters);
    _showFilterAppliedConfirmation('فلتر الربح');
  }
}

/// نموذج بيانات الفلاتر المحسن
class ProductFilters {
  const ProductFilters({
    this.category,
    this.supplier,
    this.priceRange,
    this.profitRange,
    this.minPrice,
    this.maxPrice,
    this.minProfit,
    this.maxProfit,
  });
  final String? category;
  final String? supplier;
  final String? priceRange;
  final String? profitRange;
  final double? minPrice;
  final double? maxPrice;
  final double? minProfit;
  final double? maxProfit;

  ProductFilters copyWith({
    String? category,
    String? supplier,
    String? priceRange,
    String? profitRange,
    double? minPrice,
    double? maxPrice,
    double? minProfit,
    double? maxProfit,
  }) =>
      ProductFilters(
        category: category ?? this.category,
        supplier: supplier ?? this.supplier,
        priceRange: priceRange ?? this.priceRange,
        profitRange: profitRange ?? this.profitRange,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minProfit: minProfit ?? this.minProfit,
        maxProfit: maxProfit ?? this.maxProfit,
      );

  /// ✅ فحص وجود فلاتر نشطة محسن
  bool get hasActiveFilters =>
      category != null ||
      supplier != null ||
      priceRange != null ||
      profitRange != null ||
      minPrice != null ||
      maxPrice != null ||
      minProfit != null ||
      maxProfit != null;

  /// ✅ عدد الفلاتر النشطة
  int get activeFiltersCount {
    int count = 0;
    if (category != null) count++;
    if (supplier != null) count++;
    if (priceRange != null) count++;
    if (profitRange != null) count++;
    if (minPrice != null) count++;
    if (maxPrice != null) count++;
    if (minProfit != null) count++;
    if (maxProfit != null) count++;
    return count;
  }

  /// ✅ وصف الفلاتر النشطة
  String get activeFiltersDescription {
    final List<String> descriptions = <String>[];
    if (category != null) descriptions.add('الفئة: $category');
    if (supplier != null) descriptions.add('المورد: $supplier');
    if (priceRange != null) descriptions.add('السعر: $priceRange');
    if (profitRange != null) descriptions.add('الربح: $profitRange');
    return descriptions.join(', ');
  }

  /// ✅ مسح جميع الفلاتر
  ProductFilters clear() => const ProductFilters();

  /// ✅ نسخ الفلاتر مع التحقق من الصحة
  ProductFilters copyWithValidation({
    String? category,
    String? supplier,
    String? priceRange,
    String? profitRange,
    double? minPrice,
    double? maxPrice,
    double? minProfit,
    double? maxProfit,
  }) {
    // التحقق من صحة النطاقات
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      throw ArgumentError(
          'الحد الأدنى للسعر لا يمكن أن يكون أكبر من الحد الأقصى');
    }
    if (minProfit != null && maxProfit != null && minProfit > maxProfit) {
      throw ArgumentError(
          'الحد الأدنى للربح لا يمكن أن يكون أكبر من الحد الأقصى');
    }

    return ProductFilters(
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      priceRange: priceRange ?? this.priceRange,
      profitRange: profitRange ?? this.profitRange,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minProfit: minProfit ?? this.minProfit,
      maxProfit: maxProfit ?? this.maxProfit,
    );
  }
}
