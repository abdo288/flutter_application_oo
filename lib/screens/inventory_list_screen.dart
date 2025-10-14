import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/inventory_item.dart';
import '../providers/stream_app_provider.dart';
import '../providers/stream_inventory_provider.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/modern_inventory_card.dart';
import '../widgets/windows_inventory_card.dart';
import 'inventory_item_details_screen.dart';
import 'dart:io';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // إدارة حالة التوسيع للبطاقات
  String? _expandedItemId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // إعادة تعيين الفلتر عند الدخول للشاشة لضمان عرض كل البيانات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final StreamInventoryProvider inventoryProvider =
          context.read<StreamAppProvider>().inventoryProvider;
      inventoryProvider.resetFilter();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
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

  void _onSearchChanged() {
    // إلغاء debounce السابق
    _debounce?.cancel();

    // تطبيق debouncing محسن
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        try {
          final StreamInventoryProvider inventoryProvider =
              context.read<StreamAppProvider>().inventoryProvider;
          inventoryProvider.filterInventoryItems(_searchController.text);
          // إجبار إعادة بناء الواجهة
          setState(() {});
        } catch (e) {
          debugPrint('❌ خطأ في تطبيق البحث في المخزون: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final StreamAppProvider appProvider = context.watch<StreamAppProvider>();
    final StreamInventoryProvider inventoryProvider =
        appProvider.inventoryProvider;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).storeDisplay),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Column(
        children: <Widget>[
          _buildSearchAndFilterBar(context, inventoryProvider),
          Expanded(
            child: _buildInventoryList(context, inventoryProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(
          BuildContext context, StreamInventoryProvider provider) =>
      Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).searchInventoryHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _debounce?.cancel();
                            final StreamInventoryProvider inventoryProvider =
                                context
                                    .read<StreamAppProvider>()
                                    .inventoryProvider;
                            inventoryProvider.filterInventoryItems('');
                          },
                          tooltip: 'مسح البحث',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            _buildSortMenu(context, provider),
          ],
        ),
      );

  Widget _buildSortMenu(
          BuildContext context, StreamInventoryProvider provider) =>
      PopupMenuButton<String>(
        onSelected: (String value) {
          if (value == 'toggle') {
            provider.setSortAscending(!provider.sortAscending);
          } else {
            provider.setSortBy(value);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'name',
            child: _buildSortOption(context, 'name',
                AppLocalizations.of(context).sortByName, provider),
          ),
          PopupMenuItem<String>(
            value: 'quantity',
            child: _buildSortOption(context, 'quantity',
                AppLocalizations.of(context).sortByQuantity, provider),
          ),
          PopupMenuItem<String>(
            value: 'price',
            child: _buildSortOption(context, 'price',
                AppLocalizations.of(context).sortByPrice, provider),
          ),
          PopupMenuItem<String>(
            value: 'date',
            child: _buildSortOption(context, 'date',
                AppLocalizations.of(context).sortByDate, provider),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'toggle',
            child: Row(
              children: <Widget>[
                Icon(
                  provider.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(provider.sortAscending
                    ? AppLocalizations.of(context).ascending
                    : AppLocalizations.of(context).descending),
              ],
            ),
          ),
        ],
        icon: const Icon(Icons.sort, color: AppConstants.primaryColor),
      );

  Widget _buildSortOption(BuildContext context, String value, String text,
          StreamInventoryProvider provider) =>
      Row(
        children: <Widget>[
          Icon(
            provider.sortBy == value
                ? Icons.check_circle
                : Icons.circle_outlined,
            color: provider.sortBy == value
                ? AppConstants.primaryColor
                : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      );

  Widget _buildInventoryList(
      BuildContext context, StreamInventoryProvider provider) {
    if (provider.isLoading && provider.inventoryItems.isEmpty) {
      return const LoadingWidget();
    }

    if (provider.errorMessage != null) {
      return ErrorStateWidget(
        message: provider.errorMessage!,
        onRetry: () => provider.initialize(),
      );
    }

    final List<InventoryItem> items = provider.filteredInventoryItems;

    if (items.isEmpty) {
      return EmptyStateWidget(
        message: _searchController.text.isEmpty
            ? AppLocalizations.of(context).noInventoryItems
            : AppLocalizations.of(context).noResults,
        icon: Icons.inventory_2,
      );
    }

    // استخدام ListView للويندوز لعرض البطاقات المضغوطة
    if (Platform.isWindows) {
      return ListView.separated(
        itemCount: items.length,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing * 0.3,
          vertical: context.responsiveSpacing * 0.2, // تقليل المسافة العمودية
        ),
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 6), // مسافة صغيرة بين البطاقات
        itemBuilder: (BuildContext context, int index) {
          final InventoryItem item = items[index];
          return _buildInventoryItemCard(context, item);
        },
      );
    }

    // استخدام ListView للمنصات الأخرى
    return ListView.separated(
      itemCount: items.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing * 1.0, // تقليل المسافة الأفقية
        vertical: context.responsiveSpacing * 0.2, // تقليل المسافة العمودية
      ),
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 8), // مسافة صغيرة بين البطاقات
      itemBuilder: (BuildContext context, int index) {
        final InventoryItem item = items[index];
        return _buildInventoryItemCard(context, item);
      },
    );
  }

  Widget _buildInventoryItemCard(BuildContext context, InventoryItem item) {
    // استخدام بطاقة Windows المحسنة إذا كان النظام Windows
    if (Platform.isWindows) {
      return WindowsInventoryCard(
        item: item,
        onEdit: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  InventoryItemDetailsScreen(item: item),
            ),
          );
          // إجبار إعادة بناء الواجهة بعد الرجوع من شاشة التفاصيل
          if (mounted) {
            setState(() {});
          }
        },
        onPrint: () {
          // يمكن إضافة منطق الطباعة هنا
        },
        onDelete: () {
          // يمكن إضافة منطق الحذف هنا
        },
        showActions: false,
        isExpanded: _expandedItemId == item.id,
        onExpansionChanged: (bool isExpanded) =>
            _handleCardExpansion(item.id ?? '', isExpanded),
      );
    }

    // استخدام البطاقة العادية للمنصات الأخرى
    return ModernInventoryCard(
      item: item,
      onEdit: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                InventoryItemDetailsScreen(item: item),
          ),
        );
        // إجبار إعادة بناء الواجهة بعد الرجوع من شاشة التفاصيل
        if (mounted) {
          setState(() {});
        }
      },
      onPrint: () {
        // يمكن إضافة منطق الطباعة هنا
      },
      onDelete: () {
        // يمكن إضافة منطق الحذف هنا
      },
      showActions: false,
    );
  }
}
