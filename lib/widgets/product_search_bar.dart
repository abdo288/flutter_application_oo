import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// مكون شريط البحث المحسن للمنتجات
class ProductSearchBar extends StatefulWidget {
  const ProductSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onSortPressed,
    required this.onFilterPressed,
    required this.onResetPressed,
  });

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSortPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onResetPressed;

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: <Widget>[
            // حقل البحث
            TextField(
              controller: _searchController,
              onChanged: _handleSearchChanged,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'البحث في المنتجات...',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        onPressed: _clearSearch,
                        tooltip: 'مسح البحث',
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[50],
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: AppConstants.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                isDense: true,
              ),
            ),

            const SizedBox(height: 12),

            // أزرار الفلترة والترتيب
            _buildFilterButtons(),
          ],
        ),
      );

  /// ✅ البحث مع debouncing محسن ومؤشرات الأداء
  void _handleSearchChanged(String value) {
    _debounce?.cancel();

    // ✅ تحسين Debouncing - تقليل المدة لتحسين الاستجابة
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        widget.onSearchChanged(value);

        // ✅ إظهار مؤشر البحث للاستعلامات الطويلة
        if (value.length > 3) {
          _showSearchIndicator();
        }
      }
    });
  }

  /// إظهار مؤشر البحث
  void _showSearchIndicator() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 8),
              Text('جاري البحث...'),
            ],
          ),
          duration: Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    widget.onSearchChanged('');
  }

  Widget _buildFilterButtons() => Row(
        children: <Widget>[
          Flexible(
            child: _buildFilterButton(
              icon: Icons.sort,
              label: 'ترتيب',
              onTap: widget.onSortPressed,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: _buildFilterButton(
              icon: Icons.filter_list,
              label: 'فلترة',
              onTap: widget.onFilterPressed,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: _buildFilterButton(
              icon: Icons.refresh,
              label: 'إعادة تعيين',
              onTap: widget.onResetPressed,
            ),
          ),
        ],
      );

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  icon,
                  size: 16,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
