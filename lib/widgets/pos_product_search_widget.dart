import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/stream_app_provider.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';

/// مكون البحث عن المنتجات في نقطة البيع
class POSProductSearchWidget extends StatefulWidget {
  const POSProductSearchWidget({
    super.key,
    required this.onProductSelected,
    this.placeholder = 'البحث عن منتج بالاسم...',
  });

  final void Function(Product) onProductSelected;
  final String placeholder;

  @override
  State<POSProductSearchWidget> createState() => _POSProductSearchWidgetState();
}

class _POSProductSearchWidgetState extends State<POSProductSearchWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();

    // تهيئة Animation Controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // إعداد FocusNode
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _showResults = true;
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// البحث عن المنتجات مع debouncing
  void _performSearch(String query) {
    _searchDebounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showResults = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _searchProducts(query.trim());
      }
    });
  }

  /// البحث الفعلي في المخزون فقط
  void _searchProducts(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final List<InventoryItem> inventoryItems =
          appProvider.inventoryProvider.inventoryItems;

      // البحث في المخزون فقط
      final List<Product> inventoryResults = [];
      for (final inventoryItem in inventoryItems) {
        if (inventoryItem.name.toLowerCase().contains(query.toLowerCase()) ||
            (inventoryItem.barcode != null &&
                inventoryItem.barcode!
                    .toLowerCase()
                    .contains(query.toLowerCase()))) {
          // تحويل عنصر المخزون إلى منتج
          final Product product = Product(
            id: inventoryItem.id,
            name: inventoryItem.name,
            wholesalePrice: inventoryItem.wholesalePrice,
            retailPrice: inventoryItem.retailPrice,
            barcode: inventoryItem.barcode,
            savedAt: inventoryItem.addedTime,
          );

          inventoryResults.add(product);
        }
      }

      // ترتيب النتائج (الاسم أولاً، ثم الباركود)
      inventoryResults.sort((a, b) {
        final bool aNameMatch =
            a.name.toLowerCase().contains(query.toLowerCase());
        final bool bNameMatch =
            b.name.toLowerCase().contains(query.toLowerCase());

        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;

        return a.name.compareTo(b.name);
      });

      setState(() {
        _searchResults = inventoryResults;
        _isSearching = false;
        _showResults = true;
      });

      // تشغيل الانيميشن
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      SnackbarUtils.showError(context, 'خطأ في البحث: $e');
    }
  }

  /// اختيار منتج من النتائج
  void _selectProduct(Product product) {
    widget.onProductSelected(product);
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
  }

  /// إخفاء النتائج
  void _hideResults() {
    _searchFocusNode.unfocus();
    setState(() {
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط البحث
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon:
                  const Icon(Icons.search, color: AppConstants.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _hideResults();
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey),
                    )
                  : _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : null,
            ),
            onChanged: _performSearch,
            onSubmitted: (value) {
              if (_searchResults.isNotEmpty) {
                _selectProduct(_searchResults.first);
              }
            },
          ),
        ),

        // قائمة النتائج
        if (_showResults && _searchResults.isNotEmpty)
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان النتائج
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            AppConstants.primaryColor.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 16,
                            color: AppConstants.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'النتائج (${_searchResults.length})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _hideResults,
                            child: const Text('إخفاء'),
                          ),
                        ],
                      ),
                    ),

                    // قائمة المنتجات
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final Product product = _searchResults[index];
                          return _buildProductItem(product);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // رسالة عدم وجود نتائج
        if (_showResults && _searchResults.isEmpty && !_isSearching)
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_off, color: Colors.orange[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'لم يتم العثور على منتجات تطابق البحث',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// بناء عنصر منتج في النتائج
  Widget _buildProductItem(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectProduct(product),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // أيقونة المنتج
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // تفاصيل المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.barcode != null && product.barcode!.isNotEmpty)
                      Text(
                        'باركود: ${product.barcode}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // السعر
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.retailPrice} د.ج',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  Text(
                    'جملة: ${product.wholesalePrice} د.ج',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // أيقونة الإضافة
              Icon(
                Icons.add_circle_outline,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
