import 'package:flutter/material.dart';
import '../utils/responsive_breakpoints.dart';

/// فلاتر متقدمة للمنتجات
class AdvancedProductFilters extends StatefulWidget {
  const AdvancedProductFilters({
    super.key,
    this.onFiltersChanged,
    this.initialFilters,
  });

  final void Function(ProductFilters)? onFiltersChanged;
  final ProductFilters? initialFilters;

  @override
  State<AdvancedProductFilters> createState() => _AdvancedProductFiltersState();
}

class _AdvancedProductFiltersState extends State<AdvancedProductFilters> {
  late ProductFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters ?? ProductFilters();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: SingleChildScrollView(
          physics: context.responsiveScrollPhysics,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list,
                      color: Colors.blue,
                      size: context.isSmallScreen ? 20 : 24),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  Expanded(
                    child: Text(
                      'فلاتر متقدمة',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: Text(
                      'مسح الكل',
                      style:
                          TextStyle(fontSize: context.responsiveFontSize(14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // فلاتر الفئة والمورد
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'الفئة',
                      value: _filters.category,
                      items: _filters.availableCategories,
                      onChanged: (String? value) {
                        setState(() {
                          _filters = _filters.copyWith(category: value);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownFilter(
                      label: 'المورد',
                      value: _filters.supplier,
                      items: _filters.availableSuppliers,
                      onChanged: (String? value) {
                        setState(() {
                          _filters = _filters.copyWith(supplier: value);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // فلتر نطاق السعر
              const Text(
                'نطاق السعر',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceRangeField(
                      label: 'من',
                      value: _filters.minPrice,
                      onChanged: (double? value) {
                        setState(() {
                          _filters = _filters.copyWith(minPrice: value);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceRangeField(
                      label: 'إلى',
                      value: _filters.maxPrice,
                      onChanged: (double? value) {
                        setState(() {
                          _filters = _filters.copyWith(maxPrice: value);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // فلتر الربح
              const Text(
                'نطاق الربح',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPriceRangeField(
                      label: 'أقل ربح',
                      value: _filters.minProfit,
                      onChanged: (double? value) {
                        setState(() {
                          _filters = _filters.copyWith(minProfit: value);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceRangeField(
                      label: 'أعلى ربح',
                      value: _filters.maxProfit,
                      onChanged: (double? value) {
                        setState(() {
                          _filters = _filters.copyWith(maxProfit: value);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // خيارات إضافية
              Wrap(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: CheckboxListTile(
                      title: const Text(
                        'المنتجات النشطة فقط',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _filters.activeOnly,
                      onChanged: (value) {
                        setState(() {
                          _filters =
                              _filters.copyWith(activeOnly: value ?? false);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    child: CheckboxListTile(
                      title: const Text(
                        'المنتجات ذات الربح العالي',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _filters.highProfitOnly,
                      onChanged: (value) {
                        setState(() {
                          _filters =
                              _filters.copyWith(highProfitOnly: value ?? false);
                        });
                        widget.onFiltersChanged?.call(_filters);
                      },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('الكل'),
              ),
              ...items.map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  )),
            ],
            onChanged: onChanged,
          ),
        ],
      );

  Widget _buildPriceRangeField({
    required String label,
    required double? value,
    required void Function(double?) onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: value?.toString(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              suffixText: 'دج',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final double? parsed = double.tryParse(value);
              onChanged(parsed);
            },
          ),
        ],
      );

  void _clearFilters() {
    setState(() {
      _filters = ProductFilters();
    });
    widget.onFiltersChanged?.call(_filters);
  }
}

/// فئة فلاتر المنتجات المحسنة
class ProductFilters {
  ProductFilters({
    this.category,
    this.supplier,
    this.minPrice,
    this.maxPrice,
    this.minProfit,
    this.maxProfit,
    this.activeOnly = false,
    this.highProfitOnly = false,
    this.availableCategories = const [],
    this.availableSuppliers = const [],
  });
  final String? category;
  final String? supplier;
  final double? minPrice;
  final double? maxPrice;
  final double? minProfit;
  final double? maxProfit;
  final bool activeOnly;
  final bool highProfitOnly;
  final List<String> availableCategories;
  final List<String> availableSuppliers;

  ProductFilters copyWith({
    String? category,
    String? supplier,
    double? minPrice,
    double? maxPrice,
    double? minProfit,
    double? maxProfit,
    bool? activeOnly,
    bool? highProfitOnly,
    List<String>? availableCategories,
    List<String>? availableSuppliers,
  }) =>
      ProductFilters(
        category: category ?? this.category,
        supplier: supplier ?? this.supplier,
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        minProfit: minProfit ?? this.minProfit,
        maxProfit: maxProfit ?? this.maxProfit,
        activeOnly: activeOnly ?? this.activeOnly,
        highProfitOnly: highProfitOnly ?? this.highProfitOnly,
        availableCategories: availableCategories ?? this.availableCategories,
        availableSuppliers: availableSuppliers ?? this.availableSuppliers,
      );

  bool get hasActiveFilters =>
      category != null ||
      supplier != null ||
      minPrice != null ||
      maxPrice != null ||
      minProfit != null ||
      maxProfit != null ||
      activeOnly ||
      highProfitOnly;
}
