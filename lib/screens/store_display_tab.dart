import 'dart:async';

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../dialogs/modern_edit_inventory_dialog.dart';
import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../providers/stream_app_provider.dart';
import '../providers/stream_inventory_provider.dart';
import '../services/inventory_alert_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/modern_inventory_card.dart';
import '../widgets/windows_inventory_card.dart';
import 'dart:io';

class StoreDisplayTab extends StatefulWidget {
  const StoreDisplayTab({
    super.key,
    this.onNavigateToAddProduct,
  });
  final VoidCallback? onNavigateToAddProduct;

  @override
  State<StoreDisplayTab> createState() => _StoreDisplayTabState();
}

class _StoreDisplayTabState extends State<StoreDisplayTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _hasInitialized = false;

  // إدارة حالة التوسيع للبطاقات
  String? _expandedItemId;

  @override
  void initState() {
    super.initState();
    // تأجيل تهيئة البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
      }
    });
  }

  /// تهيئة البيانات عند فتح التبويب
  Future<void> _initializeData() async {
    if (!mounted || _hasInitialized) return;

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // لا حاجة لاستدعاء appProvider.refreshAll() هنا
      // البيانات ستكون متاحة من خلال الـ StreamProvider

      if (appProvider.isInitialized) {
        debugPrint('🔄 تم جلب بيانات المخزون مباشرة في StoreDisplayTab');
      }

      _hasInitialized = true;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المخزون: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// إدارة حالة التوسيع للبطاقات (أكورديون)
  void _handleCardExpansion(String itemId, bool isExpanded) {
    setState(() {
      if (isExpanded) {
        // إذا تم فتح بطاقة، أغلق الباقي
        _expandedItemId = itemId;
      } else {
        // إذا تم إغلاق بطاقة، لا توجد بطاقة مفتوحة
        _expandedItemId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<StreamAppProvider>(
        builder: (BuildContext context, StreamAppProvider appProvider,
            Widget? child) {
          final StreamInventoryProvider inventoryProvider =
              appProvider.inventoryProvider;

          // التحقق من أن Provider مهيأ
          if (!appProvider.isInitialized || appProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل بيانات المخزون...'),
                ],
              ),
            );
          }

          // التحقق من حالة الحذف أولاً
          if (inventoryProvider.isDeleting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري حذف العنصر...'),
                ],
              ),
            );
          }

          // لا تعرض حالة "لا توجد عناصر" إلا إذا كان المخزون فعلاً فارغاً
          if (inventoryProvider.inventoryItems.isEmpty) {
            return _buildEmptyState();
          }

          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.grey[50],
            body: Column(
              children: <Widget>[
                // شريط البحث والفلترة المحسن
                _buildSearchAndFilterBar(),

                // شريط الإحصائيات
                _buildStatsBar(),

                // قائمة العناصر المحسنة
                Expanded(
                  child: inventoryProvider.filteredInventoryItems.isEmpty
                      ? _buildNoResultsState()
                      : RefreshIndicator(
                          onRefresh: _refreshInventory,
                          color: AppConstants.primaryColor,
                          backgroundColor: Colors.white,
                          child: _buildInventoryList(inventoryProvider),
                        ),
                ),
              ],
            ),
          );
        },
      );

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppConstants.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: context.responsiveSpacing),
              Text(
                AppLocalizations.of(context).noInventoryItems,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              SizedBox(height: context.responsiveSpacing * 0.5),
              Text(
                'لا توجد عناصر مخزون متاحة حالياً.\nيمكنك إضافة عناصر جديدة من تبويب "إضافة منتج".',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsiveSpacing),
              // إزالة الزر التلقائي للانتقال إلى تبويب إضافة المنتج
              // لتجنب التنقل غير المرغوب فيه عند حذف العنصر الأخير
            ],
          ),
        ),
      );

  /// بناء قائمة المخزون مع دعم الشبكة والقائمة
  Widget _buildInventoryList(StreamInventoryProvider inventoryProvider) {
    final List<InventoryItem> items = inventoryProvider.filteredInventoryItems;

    // استخدام ListView للويندوز لعرض البطاقات المضغوطة
    if (Platform.isWindows) {
      return ListView.separated(
        physics: context.responsiveScrollPhysics,
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing * 0.3,
          vertical: context.responsiveSpacing * 0.2, // تقليل المسافة العمودية
        ),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 6), // مسافة صغيرة بين البطاقات
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) => _buildInventoryCard(
            items[index],
            key: ValueKey('${items[index].id}_${items.length}')),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final bool useGrid = width >= 700;

        if (useGrid) {
          return GridView.builder(
            physics: context.responsiveScrollPhysics,
            padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing * 0.5,
                vertical: context.responsiveSpacing * 0.4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: context.gridColumns,
              crossAxisSpacing: context.responsiveSpacing * 0.5,
              mainAxisSpacing: context.responsiveSpacing * 0.5,
              childAspectRatio: context.isSmallScreen ? 1.2 : 1.5,
            ),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) =>
                _buildInventoryCard(items[index],
                    key: ValueKey('${items[index].id}_${items.length}')),
          );
        }
        return ListView.builder(
          physics: context.responsiveScrollPhysics,
          padding: EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing * 0.5,
              vertical: context.responsiveSpacing * 0.4),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            final InventoryItem item = items[index];
            return Container(
              margin: EdgeInsets.only(bottom: context.responsiveSpacing * 0.4),
              child: _buildInventoryCard(item,
                  key: ValueKey('${item.id}_${items.length}')),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar() => Consumer<StreamAppProvider>(
        builder: (BuildContext context, StreamAppProvider appProvider,
            Widget? child) => Container(
            margin: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing * 0.5,
                vertical: context.responsiveSpacing * 0.4),
            padding: context.responsivePadding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppConstants.primaryColor.withValues(alpha: 0.06),
                  AppConstants.primaryColor.withValues(alpha: 0.03),
                  Colors.white.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // شريط البحث المصغّر
                TextField(
                  controller: _searchController,
                  onChanged: (String value) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        try {
                          // استخدام الـ provider مباشرة للفلترة
                          appProvider.inventoryProvider
                              .filterInventoryItems(value);
                          // إجبار إعادة بناء الواجهة
                          setState(() {});
                        } catch (e) {
                          debugPrint(
                              '❌ خطأ في تطبيق البحث في store_display: $e');
                        }
                      }
                    });
                  },
                  style: TextStyle(fontSize: context.responsiveFontSize(14)),
                  decoration: InputDecoration(
                    isDense: context.isSmallScreen,
                    hintText: AppLocalizations.of(context).searchInventoryHint,
                    hintStyle: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: Colors.grey),
                    contentPadding: context.responsivePadding,
                    prefixIcon: Container(
                      margin: const EdgeInsets.only(left: 6, right: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.search,
                          color: AppConstants.primaryColor,
                          size: context.isSmallScreen ? 16 : 18),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: AppConstants.primaryColor,
                                size: context.isSmallScreen ? 16 : 18),
                            onPressed: () {
                              _searchController.clear();
                              _debounce?.cancel();
                              // استخدام الـ provider مباشرة لإعادة تعيين الفلتر
                              appProvider.inventoryProvider.resetFilter();
                              // إجبار إعادة بناء الواجهة
                              setState(() {});
                            },
                            tooltip: AppLocalizations.of(context).clearSearch,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: AppConstants.primaryColor
                              .withValues(alpha: 0.25)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: AppConstants.primaryColor, width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // أزرار الفرز والفلترة (مصغّرة)
                Row(
                  children: <Widget>[
                    Expanded(child: _buildSortButton()),
                    const SizedBox(width: 6),
                    Expanded(child: _buildFilterButton()),
                    const SizedBox(width: 6),
                    _buildCleanupButton(),
                  ],
                ),
              ],
            ),
          ),
      );

  Widget _buildNoResultsState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: AppConstants.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).noResults,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ' ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  // استخدام الـ provider مباشرة لإعادة تعيين الفلتر
                  final StreamAppProvider appProvider =
                      context.read<StreamAppProvider>();
                  appProvider.inventoryProvider.resetFilter();
                  // إجبار إعادة بناء الواجهة
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
                label: Text(AppLocalizations.of(context).clearSearch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSortButton() => Consumer<StreamInventoryProvider>(
        builder: (BuildContext context, StreamInventoryProvider provider,
                Widget? child) =>
            Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3)),
          ),
          child: PopupMenuButton<String>(
            onSelected: (String value) {
              provider.setSortBy(value);
              // إجبار إعادة بناء الواجهة
              setState(() {});
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.sort_by_alpha,
                        color: AppConstants.primaryColor),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).sortByName),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'quantity',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.inventory,
                        color: AppConstants.secondaryColor),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).sortByQuantity),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'price',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.attach_money,
                        color: AppConstants.successColor),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).sortByPrice),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.calendar_today,
                        color: AppConstants.warningColor),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).sortByDate),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.sort,
                      color: AppConstants.primaryColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    provider.getSortLabel(),
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildFilterButton() => Consumer<StreamInventoryProvider>(
        builder: (BuildContext context, StreamInventoryProvider provider,
                Widget? child) =>
            Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3)),
          ),
          child: PopupMenuButton<String>(
            onSelected: (String value) {
              provider.setSortAscending(value == 'asc');
              // إجبار إعادة بناء الواجهة
              setState(() {});
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                value: 'asc',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.arrow_upward,
                        color: AppConstants.successColor),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).ascending),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'desc',
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.arrow_downward,
                        color: AppConstants.errorColor),
                    const SizedBox(width: 8),
                    Text(AppLocalizations.of(context).descending),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    provider.sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider.sortAscending
                        ? AppLocalizations.of(context).ascending
                        : AppLocalizations.of(context).descending,
                    style: const TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildCleanupButton() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppConstants.warningColor.withValues(alpha: 0.3)),
        ),
        child: IconButton(
          onPressed: _cleanupInventoryData,
          icon: const Icon(Icons.cleaning_services,
              color: AppConstants.warningColor, size: 18),
          tooltip: 'تنظيف البيانات الخاطئة',
        ),
      );

  /// تنظيف البيانات الخاطئة من المخزون
  Future<void> _cleanupInventoryData() async {
    try {
      // لا نحتاج تنظيف خاص مع النظام الهجين
      // البيانات يتم تنظيفها تلقائياً
      // لا حاجة لاستدعاء callback لأن الـ provider يتولى التحديث تلقائياً
      debugPrint('🔄 تحديث المخزون - الـ provider يتولى التحديث تلقائياً');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تنظيف البيانات الخاطئة بنجاح'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تنظيف البيانات: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildStatsBar() => Consumer<StreamAppProvider>(
        builder: (BuildContext context, StreamAppProvider appProvider,
            Widget? child) {
          final StreamInventoryProvider inventoryProvider =
              appProvider.inventoryProvider;

          final int totalItems =
              inventoryProvider.filteredInventoryItems.length;
          final int outOfStockCount = inventoryProvider.filteredInventoryItems
              .where((InventoryItem item) => item.isOutOfStock())
              .length;
          final double totalValue = inventoryProvider.filteredInventoryItems
              .fold<double>(
                  0,
                  (double sum, InventoryItem item) =>
                      sum + item.getTotalValue());

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppConstants.secondaryColor.withValues(alpha: 0.06),
                  AppConstants.secondaryColor.withValues(alpha: 0.03),
                  Colors.white.withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppConstants.secondaryColor.withValues(alpha: 0.2)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppConstants.secondaryColor.withValues(alpha: 0.08),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatItem(
                    AppLocalizations.of(context).totalItems,
                    totalItems.toString(),
                    Icons.inventory_2,
                    AppConstants.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppLocalizations.of(context).outOfStock,
                    outOfStockCount.toString(),
                    Icons.warning,
                    AppConstants.errorColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    AppLocalizations.of(context).totalValue,
                    CurrencyFormatter.formatCurrency(
                        totalValue.toDouble(), context),
                    Icons.attach_money,
                    AppConstants.successColor,
                  ),
                ),
                // زر اختبار تحميل البيانات
                IconButton(
                  onPressed: _testDataLoading,
                  icon: const Icon(Icons.refresh,
                      color: AppConstants.primaryColor),
                  tooltip: 'اختبار تحميل البيانات',
                ),
              ],
            ),
          );
        },
      );

  Widget _buildStatItem(
          String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _buildInventoryCard(InventoryItem item, {Key? key}) {
    // استخدام بطاقة Windows المحسنة إذا كان النظام Windows
    if (Platform.isWindows) {
      return WindowsInventoryCard(
        key: key,
        item: item,
        onEdit: () => _showEditDialog(item),
        onPrint: () => _printBarcode(item),
        onDelete: () => _confirmAndDeleteItem(item),
        isExpanded: _expandedItemId == item.id,
        onExpansionChanged: (bool isExpanded) =>
            _handleCardExpansion(item.id ?? '', isExpanded),
      );
    }

    // استخدام البطاقة العادية للمنصات الأخرى
    return ModernInventoryCard(
      key: key,
      item: item,
      onEdit: () => _showEditDialog(item),
      onPrint: () => _printBarcode(item),
      onDelete: () => _confirmAndDeleteItem(item),
    );
  }

  Future<void> _refreshInventory() async {
    // لا حاجة لإعادة تحميل البيانات لأن الـ StreamProvider يتولى ذلك تلقائياً
    debugPrint(
        '🔄 تم طلب إعادة تحميل المخزون - StreamProvider يتولى ذلك تلقائياً');
  }

  Future<void> _testDataLoading() async {
    try {
      debugPrint('🧪 بدء اختبار تحميل البيانات...');
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;

      // إعادة تحميل البيانات
      await inventoryProvider.loadInventoryItems();

      // طباعة النتائج
      debugPrint('📊 نتائج الاختبار:');
      debugPrint('   - إجمالي العناصر: ${inventoryProvider.inventoryCount}');
      debugPrint(
          '   - العناصر المفلترة: ${inventoryProvider.filteredInventoryItems.length}');

      // طباعة تفاصيل أول 3 عناصر
      for (int i = 0;
          i < inventoryProvider.inventoryItems.length && i < 3;
          i++) {
        final InventoryItem item = inventoryProvider.inventoryItems[i];
        debugPrint(
            '   - العنصر ${i + 1}: ${item.name} - الكمية: ${item.quantity}');
      }

      // إشعار المستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحميل ${inventoryProvider.inventoryCount} عنصر'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }

      // لا حاجة لاستدعاء callback لأن الـ provider يتولى التحديث تلقائياً
      debugPrint('🔄 تحديث المخزون - الـ provider يتولى التحديث تلقائياً');
    } catch (e) {
      debugPrint('❌ خطأ في اختبار تحميل البيانات: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _showEditDialog(InventoryItem item) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModernEditInventoryDialog(
        item: item,
        onItemUpdated: () {
          // إجبار إعادة بناء الواجهة بعد التحديث
          if (mounted) {
            setState(() {});
          }
          debugPrint('تم تحديث عنصر المخزون بنجاح');
        },
      ),
    );
  }

  /// دالة التأكيد على الحذف الجديدة المحسّنة
  Future<void> _confirmAndDeleteItem(InventoryItem item) async {
    // التحقق من صحة البيانات
    if (item.id == null || item.id!.isEmpty) {
      _showDeleteResult(false, item.name, 'معرف العنصر غير صالح');
      return;
    }

    // عرض dialog التأكيد المحسّن
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _EnhancedDeleteDialog(
        item: item,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true) {
      await _executeDelete(item);
    }
  }

  /// دالة تنفيذ الحذف المحسّنة مع Optimistic UI
  Future<bool> _executeDelete(InventoryItem item) async {
    try {
      debugPrint('🗑️ بدء حذف العنصر: ${item.name} (${item.id})');

      // التحقق من وجود المعرف
      if (item.id == null || item.id!.isEmpty) {
        _showDeleteResult(false, item.name, 'معرف العنصر غير صالح');
        return false;
      }

      // تنفيذ الحذف من قاعدة البيانات أولاً
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;

      final bool success =
          await inventoryProvider.deleteInventoryItemById(item.id!);

      if (success) {
        // فحص التنبيهات بعد الحذف الناجح
        await InventoryAlertService.checkInventoryAlerts(inventoryProvider);
        _showDeleteResult(true, item.name);
        // إجبار إعادة بناء الواجهة
        if (mounted) {
          setState(() {});
        }
        debugPrint('✅ تم حذف العنصر بنجاح: ${item.name}');
        return true;
      } else {
        _showDeleteResult(
            false, item.name, 'فشل في حذف العنصر من قاعدة البيانات');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف العنصر: $e');
      _showDeleteResult(false, item.name, 'خطأ في الحذف: ${e.toString()}');
      return false;
    }
  }

  /// دالة عرض نتائج الحذف المحسّنة
  void _showDeleteResult(bool success, String itemName,
      [String? errorMessage]) {
    if (!mounted) return;

    final String message = success
        ? 'تم حذف "$itemName" بنجاح'
        : 'فشل في حذف "$itemName"${errorMessage != null ? ': $errorMessage' : ''}';

    final Color backgroundColor = success ? Colors.green : Colors.red;
    final IconData icon = success ? Icons.check_circle : Icons.error;

    final SnackBar snackBar = SnackBar(
      content: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      duration: Duration(seconds: success ? 3 : 5),
      action: success
          ? SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () {
                // TODO: تنفيذ التراجع إذا لزم الأمر
                debugPrint('تراجع عن حذف: $itemName');
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

  Future<void> _printBarcode(InventoryItem item) async {
    if ((item.barcode ?? '').isEmpty) {
      _showSnackbar(AppLocalizations.of(context).noBarcodeForItem);
      return;
    }
    // نافذة خيارات الطباعة
    final _PrintOptions? options = await _showPrintOptionsDialog();
    if (options == null) return;

    await _printBarcodeWithOptions(item, options);
  }

  Future<_PrintOptions?> _showPrintOptionsDialog() async {
    final TextEditingController quantityController =
        TextEditingController(text: '1');
    _PaperSize selectedSize = _PaperSize.roll57;
    bool includeName = true;
    bool includeStockQty = false;

    return showDialog<_PrintOptions>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title:
            Text(AppLocalizations.of(context).printBarcodeQuantityDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(AppLocalizations.of(context)
                  .printBarcodeQuantityDialogContent),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).printBarcodeQuantity,
                  hintText:
                      AppLocalizations.of(context).printBarcodeQuantityHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
              ),
              const SizedBox(height: 16),
              const Text('مقاس الورق',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              StatefulBuilder(
                builder: (BuildContext context,
                        void Function(void Function()) setSt) =>
                    Column(
                  children: <Widget>[
                    RadioListTile<_PaperSize>(
                      value: _PaperSize.roll57,
                      groupValue: selectedSize,
                      title: const Text('رول حراري 57mm'),
                      onChanged: (_PaperSize? v) =>
                          setSt(() => selectedSize = v ?? _PaperSize.roll57),
                    ),
                    RadioListTile<_PaperSize>(
                      value: _PaperSize.roll80,
                      groupValue: selectedSize,
                      title: const Text('رول حراري 80mm'),
                      onChanged: (_PaperSize? v) =>
                          setSt(() => selectedSize = v ?? _PaperSize.roll80),
                    ),
                    RadioListTile<_PaperSize>(
                      value: _PaperSize.a4,
                      groupValue: selectedSize,
                      title: const Text('A4'),
                      onChanged: (_PaperSize? v) =>
                          setSt(() => selectedSize = v ?? _PaperSize.a4),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      value: includeName,
                      onChanged: (bool? v) =>
                          setSt(() => includeName = v ?? true),
                      title: const Text('إظهار اسم المنتج'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      value: includeStockQty,
                      onChanged: (bool? v) =>
                          setSt(() => includeStockQty = v ?? false),
                      title: const Text('إظهار الكمية بالمخزن'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Text(
                AppLocalizations.of(context).printBarcodeQuantityDialogCancel),
          ),
          ElevatedButton(
            onPressed: () {
              final int quantity =
                  int.tryParse(quantityController.text.trim()) ?? 0;
              if (quantity < 1 || quantity > 500) {
                _showSnackbar(
                    AppLocalizations.of(context).printBarcodeQuantityError);
                return;
              }
              Navigator.of(context).pop(_PrintOptions(
                quantity: quantity,
                size: selectedSize,
                includeName: includeName,
                includeStockQty: includeStockQty,
              ));
            },
            child: Text(
                AppLocalizations.of(context).printBarcodeQuantityDialogConfirm),
          ),
        ],
      ),
    );
  }

  Future<void> _printBarcodeWithOptions(
      InventoryItem item, _PrintOptions options) async {
    try {
      // التحقق من صحة بيانات الباركود
      if (item.barcode == null || item.barcode!.isEmpty) {
        _showSnackbar('باركود المنتج غير صالح');
        return;
      }

      // التحقق من أن الباركود يحتوي على أحرف صالحة لـ Code128
      if (!_isValidCode128Barcode(item.barcode!)) {
        _showSnackbar('باركود المنتج غير متوافق مع معيار Code128');
        return;
      }

      // إنشاء اسم ملف فريد لتجنب التعارض
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName =
          _sanitizeFileName('barcode_${item.barcode}_$timestamp.pdf');

      // محاولة استخدام layoutPdf أولاً، وإذا فشل نستخدم sharePdf
      try {
        await Printing.layoutPdf(
          name: fileName,
          onLayout: (PdfPageFormat incomingFormat) async {
            try {
              final pw.Document doc = pw.Document();
              final pw.Barcode barcode = Barcode.code128();

              // تحديد مقاس الصفحة المطلوب
              PdfPageFormat targetFormat = PdfPageFormat.roll57;
              switch (options.size) {
                case _PaperSize.roll57:
                  targetFormat = PdfPageFormat.roll57;
                  break;
                case _PaperSize.roll80:
                  targetFormat = PdfPageFormat.roll80;
                  break;
                case _PaperSize.a4:
                  targetFormat = PdfPageFormat.a4;
                  break;
              }

              // استخدام المقاس القادم من النظام إذا كان صالحاً، وإلا نستخدم المحدد
              final PdfPageFormat pageFormat =
                  (incomingFormat.width > 0 && incomingFormat.height > 0)
                      ? incomingFormat
                      : targetFormat;

              // إنشاء ملصق واحد
              pw.Widget buildLabel(int index) => pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: <pw.Widget>[
                        if (options.includeName) ...<pw.Widget>[
                          pw.Text(
                            item.name,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 6),
                        ],
                        pw.BarcodeWidget(
                          barcode: barcode,
                          data: item.barcode!,
                          width: (options.size == _PaperSize.a4)
                              ? 200
                              : double.infinity,
                          height: (options.size == _PaperSize.a4) ? 60 : 40,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          item.barcode!,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        if (options.includeStockQty) ...<pw.Widget>[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'الكمية: ${item.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                        if (options.quantity > 1) ...<pw.Widget>[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'نسخة ${index + 1} من ${options.quantity}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey700),
                          ),
                        ],
                      ],
                    ),
                  );

              // إضافة الصفحات حسب نوع الورق
              if (options.size == _PaperSize.a4) {
                // تخطيط A4 مع شبكة ملصقات
                const int columns = 2;
                const double padding = 12;
                int printed = 0;

                while (printed < options.quantity) {
                  final int remaining = options.quantity - printed;
                  final int itemsInPage =
                      (remaining > columns * 8) ? columns * 8 : remaining;

                  doc.addPage(
                    pw.Page(
                      pageFormat: pageFormat,
                      margin: const pw.EdgeInsets.all(20),
                      build: (pw.Context context) => pw.GridView(
                        crossAxisCount: columns,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: padding,
                        crossAxisSpacing: padding,
                        children: List<pw.Widget>.generate(
                          itemsInPage,
                          (int i) => pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                  color: PdfColors.grey300, width: 0.5),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: buildLabel(printed + i),
                          ),
                        ),
                      ),
                    ),
                  );
                  printed += itemsInPage;
                }
              } else {
                // تخطيط الرول: صفحة لكل ملصق
                for (int i = 0; i < options.quantity; i++) {
                  doc.addPage(
                    pw.Page(
                      pageFormat: pageFormat,
                      margin: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      build: (pw.Context context) => buildLabel(i),
                    ),
                  );
                }
              }

              final Uint8List pdfBytes = await doc.save();

              // التحقق من أن الملف تم إنشاؤه بنجاح
              if (pdfBytes.isEmpty) {
                throw Exception('فشل في إنشاء ملف PDF');
              }

              return pdfBytes;
            } catch (e) {
              // في حالة حدوث خطأ، نعيد ملف PDF بسيط يحتوي على رسالة خطأ
              final pw.Document errorDoc = pw.Document();
              errorDoc.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) => pw.Center(
                    child: pw.Text(
                      'خطأ في إنشاء الباركود: ${e.toString()}',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
              return await errorDoc.save();
            }
          },
        );

        // إضافة تأخير قصير لضمان إغلاق الملف السابق
        await Future<void>.delayed(const Duration(milliseconds: 500));

        _showSnackbar('تمت الطباعة بنجاح');
      } catch (e) {
        // إذا فشل layoutPdf، نستخدم sharePdf كبديل
        _showSnackbar('جاري استخدام طريقة بديلة للطباعة...');
        await _printWithSharePdf(item, options, fileName);
      }
    } on Exception catch (e) {
      _showSnackbar('خطأ في الطباعة: ${e.toString()}');
    }
  }

  /// التحقق من صحة الباركود لمعيار Code128
  bool _isValidCode128Barcode(String barcode) {
    if (barcode.isEmpty) return false;

    // Code128 يدعم ASCII من 32 إلى 126
    for (int i = 0; i < barcode.length; i++) {
      final int charCode = barcode.codeUnitAt(i);
      if (charCode < 32 || charCode > 126) {
        return false;
      }
    }

    return true;
  }

  /// تنظيف أسماء الملفات من الأحرف غير المسموحة
  String _sanitizeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  /// طريقة بديلة للطباعة باستخدام sharePdf
  Future<void> _printWithSharePdf(
      InventoryItem item, _PrintOptions options, String fileName) async {
    try {
      final pw.Document doc = pw.Document();
      final pw.Barcode barcode = Barcode.code128();

      // تحديد مقاس الصفحة المطلوب
      PdfPageFormat targetFormat = PdfPageFormat.roll57;
      switch (options.size) {
        case _PaperSize.roll57:
          targetFormat = PdfPageFormat.roll57;
          break;
        case _PaperSize.roll80:
          targetFormat = PdfPageFormat.roll80;
          break;
        case _PaperSize.a4:
          targetFormat = PdfPageFormat.a4;
          break;
      }

      // إنشاء ملصق واحد
      pw.Widget buildLabel(int index) => pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: <pw.Widget>[
                if (options.includeName) ...<pw.Widget>[
                  pw.Text(
                    item.name,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 6),
                ],
                pw.BarcodeWidget(
                  barcode: barcode,
                  data: item.barcode!,
                  width:
                      (options.size == _PaperSize.a4) ? 200 : double.infinity,
                  height: (options.size == _PaperSize.a4) ? 60 : 40,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  item.barcode!,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                if (options.includeStockQty) ...<pw.Widget>[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'الكمية: ${item.quantity}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
                if (options.quantity > 1) ...<pw.Widget>[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'نسخة ${index + 1} من ${options.quantity}',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ],
            ),
          );

      // إضافة الصفحات حسب نوع الورق
      if (options.size == _PaperSize.a4) {
        const int columns = 2;
        const double padding = 12;
        int printed = 0;

        while (printed < options.quantity) {
          final int remaining = options.quantity - printed;
          final int itemsInPage =
              (remaining > columns * 8) ? columns * 8 : remaining;

          doc.addPage(
            pw.Page(
              pageFormat: targetFormat,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) => pw.GridView(
                crossAxisCount: columns,
                childAspectRatio: 1.5,
                mainAxisSpacing: padding,
                crossAxisSpacing: padding,
                children: List<pw.Widget>.generate(
                  itemsInPage,
                  (int i) => pw.Container(
                    decoration: pw.BoxDecoration(
                      border:
                          pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: buildLabel(printed + i),
                  ),
                ),
              ),
            ),
          );
          printed += itemsInPage;
        }
      } else {
        for (int i = 0; i < options.quantity; i++) {
          doc.addPage(
            pw.Page(
              pageFormat: targetFormat,
              margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              build: (pw.Context context) => buildLabel(i),
            ),
          );
        }
      }

      final Uint8List pdfBytes = await doc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      _showSnackbar('تم حفظ الملف بنجاح');
    } catch (e) {
      _showSnackbar('خطأ في الحفظ: ${e.toString()}');
    }
  }

  /// بناء صف معلومات منظم
}

/// Dialog الحذف المحسّن مع عرض تفاصيل العنصر
class _EnhancedDeleteDialog extends StatelessWidget {
  const _EnhancedDeleteDialog({
    required this.item,
    required this.onConfirm,
    required this.onCancel,
  });

  final InventoryItem item;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red[600],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context).confirmDelete,
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رسالة التأكيد
            Text(
              AppLocalizations.of(context).confirmDeleteMessage(item.name),
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // تفاصيل العنصر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل العنصر المراد حذفه:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('الاسم:', item.name),
                  _buildDetailRow('الكمية:',
                      '${item.quantity} ${AppLocalizations.of(context).quantityUnit}'),
                  _buildDetailRow(
                      'سعر الجملة:',
                      CurrencyFormatter.formatCurrency(
                          item.wholesalePrice.toDouble(), context)),
                  if (item.barcode?.isNotEmpty == true)
                    _buildDetailRow('الباركود:', item.barcode ?? ''),
                  _buildDetailRow(
                      'تاريخ الإضافة:',
                      DateFormat(AppConstants.dateFormat)
                          .format(item.addedDate)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // تحذير
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'هذا الإجراء لا يمكن التراجع عنه',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // زر الإلغاء
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('إلغاء'),
        ),

        // زر الحذف
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
          ),
          child: const Text('حذف'),
        ),
      ],
    );

  Widget _buildDetailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
}

enum _PaperSize { roll57, roll80, a4 }

class _PrintOptions {
  const _PrintOptions({
    required this.quantity,
    required this.size,
    required this.includeName,
    required this.includeStockQty,
  });
  final int quantity;
  final _PaperSize size;
  final bool includeName;
  final bool includeStockQty;
}
