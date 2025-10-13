import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/page_result.dart';
import '../models/quick_inventory_item.dart';
import '../models/sale.dart';
import '../services/error_handler_service.dart';
import '../services/pos_service.dart';
import '../utils/snackbar_utils.dart';

// Simple currency formatter function
String formatCurrency(int amount) => '${amount.toString()} DZ';

/// شاشة تقارير نقطة البيع
class POSReportsScreen extends StatefulWidget {
  const POSReportsScreen({super.key});

  @override
  State<POSReportsScreen> createState() => _POSReportsScreenState();
}

class _POSReportsScreenState extends State<POSReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Sale> _sales = <Sale>[];
  List<QuickInventoryItem> _quickInventoryItems = <QuickInventoryItem>[];
  bool _isLoading = false;
  bool _isLoadingMoreSales = false;
  bool _isLoadingMoreQuick = false;
  bool _hasMoreSales = true;
  bool _hasMoreQuick = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastQuickDoc;
  DocumentSnapshot<Map<String, dynamic>>? _lastSaleDoc;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل البيانات
  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Future.wait(<Future<void>>[
        _loadSales(),
        _loadQuickInventoryItems(),
      ]);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحميل البيانات: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// تحميل عمليات البيع
  Future<void> _loadSales() async {
    try {
      _lastSaleDoc = null;
      final PageResult<Sale> page = await POSService.getCombinedSalesPage(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _sales = page.items;
          _lastSaleDoc = page.lastDocument;
          _hasMoreSales = page.hasMore;
        });
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل عمليات البيع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadSales',
        },
      );
      debugPrint('خطأ في تحميل عمليات البيع: $e');
    }
  }

  /// تحميل عناصر الجرد السريع
  Future<void> _loadQuickInventoryItems() async {
    try {
      _lastQuickDoc = null;
      final PageResult<QuickInventoryItem> page =
          await POSService.getQuickInventoryPage();
      if (mounted) {
        setState(() {
          _quickInventoryItems = page.items;
          _lastQuickDoc = page.lastDocument;
          _hasMoreQuick = page.hasMore;
        });
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل عناصر الجرد السريع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadQuickInventoryItems',
        },
      );
      debugPrint('خطأ في تحميل عناصر الجرد السريع: $e');
    }
  }

  Future<void> _loadMoreSales() async {
    if (_isLoadingMoreSales || !_hasMoreSales) return;
    setState(() => _isLoadingMoreSales = true);
    try {
      final PageResult<Sale> page = await POSService.getCombinedSalesPage(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _sales.addAll(page.items);
          _lastSaleDoc = page.lastDocument;
          _hasMoreSales = page.hasMore;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل المزيد من المبيعات: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreSales = false);
    }
  }

  Future<void> _loadMoreQuick() async {
    if (_isLoadingMoreQuick || !_hasMoreQuick) return;
    setState(() => _isLoadingMoreQuick = true);
    try {
      final PageResult<QuickInventoryItem> page =
          await POSService.getQuickInventoryPage(
        startAfter: _lastQuickDoc,
      );
      if (mounted) {
        setState(() {
          _quickInventoryItems.addAll(page.items);
          _lastQuickDoc = page.lastDocument;
          _hasMoreQuick = page.hasMore;
        });
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل المزيد من الجرد السريع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadMoreQuick',
        },
      );
      debugPrint('خطأ في تحميل المزيد من الجرد السريع: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMoreQuick = false);
    }
  }

  /// تحديث الفترة الزمنية
  Future<void> _updateDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          _startDate = picked.start;
          _endDate = picked.end;
        });
      }
      await _loadSales();
    }
  }

  /// تصدير تقرير المبيعات
  Future<void> _exportSalesReport() async {
    if (_sales.isEmpty) {
      SnackbarUtils.showError(context, 'لا توجد عمليات بيع للتصدير');
      return;
    }

    try {
      // إنشاء تقرير نصي للمبيعات
      final StringBuffer report = StringBuffer();
      report.writeln('تقرير المبيعات');
      report
          .writeln('تاريخ التقرير: ${DateTime.now().toString().split(' ')[0]}');
      report.writeln(
          'وقت التقرير: ${DateTime.now().toString().split(' ')[1].split('.')[0]}');
      report.writeln('=' * 50);
      report.writeln();

      double totalSales = 0;
      double totalProfit = 0;

      for (final Sale sale in _sales) {
        report.writeln('رقم العملية: ${sale.id}');
        report.writeln('التاريخ: ${sale.saleDate}');
        report.writeln('المبلغ الإجمالي: ${sale.totalAmount} دج');
        report.writeln('الربح: ${sale.totalProfit} دج');
        report.writeln('طريقة الدفع: ${sale.paymentMethod}');
        if (sale.customerName != null) {
          report.writeln('اسم العميل: ${sale.customerName}');
        }
        report.writeln('-' * 30);

        totalSales += sale.totalAmount.toDouble();
        totalProfit += sale.totalProfit.toDouble();
      }

      report.writeln();
      report.writeln('إجمالي المبيعات: $totalSales دج');
      report.writeln('إجمالي الأرباح: $totalProfit دج');

      // استخدام share_plus لحفظ ومشاركة الملف
      await Share.share(
        report.toString(),
        subject: 'تقرير المبيعات',
      );

      SnackbarUtils.showSuccess(context, 'تم تصدير التقرير بنجاح');
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في تصدير التقرير: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('تقارير نقطة البيع'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            tabs: const <Widget>[
              Tab(text: 'المبيعات', icon: Icon(Icons.shopping_cart)),
              Tab(text: 'الجرد السريع', icon: Icon(Icons.inventory)),
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
            ],
          ),
          actions: <Widget>[
            // مؤشر حالة المزامنة
            _buildSyncStatusIndicator(),
            // زر التحديث
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'تحديث البيانات',
            ),
            IconButton(
              onPressed: _updateDateRange,
              icon: const Icon(Icons.date_range),
              tooltip: 'تحديد الفترة',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _buildSalesTab(),
                      _buildQuickInventoryTab(),
                      _buildStatisticsTab(),
                    ],
                  ),
                ),
              ),
      );

  /// بناء تبويب المبيعات
  Widget _buildSalesTab() => Column(
        children: <Widget>[
          // شريط الفترة الزمنية
          _buildDateRangeBar(),

          // إحصائيات المبيعات
          _buildSalesStats(),

          // قائمة عمليات البيع
          Expanded(
            child: _sales.isEmpty ? _buildEmptySales() : _buildSalesList(),
          ),
        ],
      );

  /// بناء تبويب الجرد السريع
  Widget _buildQuickInventoryTab() => Column(
        children: <Widget>[
          // إحصائيات الجرد
          _buildInventoryStats(),

          // قائمة عناصر الجرد
          Expanded(
            child: _quickInventoryItems.isEmpty
                ? _buildEmptyInventory()
                : _buildQuickInventoryList(),
          ),
        ],
      );

  /// بناء تبويب الإحصائيات
  Widget _buildStatisticsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // إحصائيات عامة
            _buildGeneralStats(),
            const SizedBox(height: 16),

            // إحصائيات المبيعات
            _buildSalesStatistics(),
            const SizedBox(height: 16),

            // إحصائيات الجرد
            _buildInventoryStatistics(),
          ],
        ),
      );

  /// بناء شريط الفترة الزمنية
  Widget _buildDateRangeBar() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'الفترة الزمنية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'من ${DateFormat('yyyy/MM/dd').format(_startDate)} إلى ${DateFormat('yyyy/MM/dd').format(_endDate)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _exportSalesReport,
              icon: const Icon(Icons.file_download),
              tooltip: 'تصدير التقرير',
            ),
          ],
        ),
      );

  /// بناء إحصائيات المبيعات
  Widget _buildSalesStats() {
    if (_sales.isEmpty) return const SizedBox.shrink();

    final int totalSales = _sales.length;
    final int totalAmount =
        _sales.fold(0, (int sum, Sale sale) => sum + sale.totalAmount);
    final int totalProfit =
        _sales.fold(0, (int sum, Sale sale) => sum + sale.totalProfit);
    final int totalQuantity =
        _sales.fold(0, (int sum, Sale sale) => sum + sale.totalQuantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildStatItem(
            icon: Icons.receipt,
            label: 'العمليات',
            value: totalSales.toString(),
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.attach_money,
            label: 'المبلغ',
            value: formatCurrency(totalAmount),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.trending_up,
            label: 'الربح',
            value: formatCurrency(totalProfit),
            color: Colors.orange,
          ),
          _buildStatItem(
            icon: Icons.inventory,
            label: 'الكمية',
            value: totalQuantity.toString(),
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  /// بناء إحصائيات الجرد
  Widget _buildInventoryStats() {
    if (_quickInventoryItems.isEmpty) return const SizedBox.shrink();

    final int totalItems = _quickInventoryItems.length;
    final int newProducts = _quickInventoryItems
        .where((QuickInventoryItem item) => item.isNewProduct)
        .length;
    final int itemsWithDifference = _quickInventoryItems
        .where((QuickInventoryItem item) => item.hasQuantityDifference)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildStatItem(
            icon: Icons.inventory,
            label: 'العناصر',
            value: totalItems.toString(),
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.add_circle,
            label: 'جديدة',
            value: newProducts.toString(),
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.warning,
            label: 'اختلاف',
            value: itemsWithDifference.toString(),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  /// بناء عنصر إحصائية
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  /// بناء المبيعات الفارغة
  Widget _buildEmptySales() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عمليات بيع',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد عمليات بيع في الفترة المحددة',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// بناء الجرد الفارغ
  Widget _buildEmptyInventory() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد عناصر جرد',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد عناصر جرد سريع',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// بناء قائمة عمليات البيع
  Widget _buildSalesList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sales.length + (_hasMoreSales ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _sales.length) {
            _loadMoreSales();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final Sale sale = _sales[index];
          return _buildSaleCard(sale);
        },
      );

  /// بناء قائمة عناصر الجرد السريع
  Widget _buildQuickInventoryList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _quickInventoryItems.length + (_hasMoreQuick ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index >= _quickInventoryItems.length) {
            _loadMoreQuick();
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final QuickInventoryItem item = _quickInventoryItems[index];
          return _buildQuickInventoryCard(item);
        },
      );

  /// بناء بطاقة عملية بيع
  Widget _buildSaleCard(Sale sale) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: sale.isSynced ? null : Colors.orange.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      // مؤشر حالة المزامنة
                      Icon(
                        sale.isSynced ? Icons.cloud_done : Icons.sync_disabled,
                        color: sale.isSynced ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'عملية #${sale.id?.substring(0, 8) ?? 'غير معروف'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(sale.saleDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                      '${sale.uniqueProductCount} منتج • ${sale.totalQuantity} قطعة'),
                  Text(
                    formatCurrency(sale.finalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              if (sale.customerName != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  'العميل: ${sale.customerName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (sale.paymentMethod != 'نقدي') ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  'طريقة الدفع: ${sale.paymentMethod}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  /// بناء بطاقة عنصر جرد سريع
  Widget _buildQuickInventoryCard(QuickInventoryItem item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(item.scanDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'باركود: ${item.barcode}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (item.originalQuantity != null)
                    Text('الأصلي: ${item.originalQuantity}'),
                  Text('الممسوح: ${item.scannedQuantity}'),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.getQuantityStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: item.getQuantityStatusColor()),
                    ),
                    child: Text(
                      item.getQuantityStatusText(),
                      style: TextStyle(
                        fontSize: 10,
                        color: item.getQuantityStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// بناء الإحصائيات العامة
  Widget _buildGeneralStats() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'الإحصائيات العامة',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildStatItem(
                    icon: Icons.receipt,
                    label: 'عمليات البيع',
                    value: _sales.length.toString(),
                    color: Colors.blue,
                  ),
                  _buildStatItem(
                    icon: Icons.inventory,
                    label: 'عناصر الجرد',
                    value: _quickInventoryItems.length.toString(),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// بناء إحصائيات المبيعات
  Widget _buildSalesStatistics() {
    if (_sales.isEmpty) return const SizedBox.shrink();

    final int totalAmount =
        _sales.fold(0, (int sum, Sale sale) => sum + sale.totalAmount);
    final int totalProfit =
        _sales.fold(0, (int sum, Sale sale) => sum + sale.totalProfit);
    final int totalQuantity =
        _sales.fold(0, (int sum, Sale sale) => sum + sale.totalQuantity);
    final double averageSale =
        _sales.isNotEmpty ? totalAmount / _sales.length : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'إحصائيات المبيعات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'المبلغ الإجمالي',
                  value: formatCurrency(totalAmount),
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.trending_up,
                  label: 'الربح الإجمالي',
                  value: formatCurrency(totalProfit),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatItem(
                  icon: Icons.inventory,
                  label: 'الكمية الإجمالية',
                  value: totalQuantity.toString(),
                  color: Colors.purple,
                ),
                _buildStatItem(
                  icon: Icons.analytics,
                  label: 'متوسط البيع',
                  value: formatCurrency(averageSale.toInt()),
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء إحصائيات الجرد
  Widget _buildInventoryStatistics() {
    if (_quickInventoryItems.isEmpty) return const SizedBox.shrink();

    final int newProducts = _quickInventoryItems
        .where((QuickInventoryItem item) => item.isNewProduct)
        .length;
    final int itemsWithDifference = _quickInventoryItems
        .where((QuickInventoryItem item) => item.hasQuantityDifference)
        .length;
    final int totalScannedQuantity = _quickInventoryItems.fold(
        0, (int sum, QuickInventoryItem item) => sum + item.scannedQuantity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'إحصائيات الجرد',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatItem(
                  icon: Icons.add_circle,
                  label: 'منتجات جديدة',
                  value: newProducts.toString(),
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.warning,
                  label: 'عناصر باختلاف',
                  value: itemsWithDifference.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatItem(
                  icon: Icons.inventory,
                  label: 'الكمية الممسوحة',
                  value: totalScannedQuantity.toString(),
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.analytics,
                  label: 'متوسط الكمية',
                  value: _quickInventoryItems.isNotEmpty
                      ? (totalScannedQuantity / _quickInventoryItems.length)
                          .toStringAsFixed(1)
                      : '0',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء مؤشر حالة المزامنة
  Widget _buildSyncStatusIndicator() {
    final int unsyncedCount =
        _sales.where((Sale sale) => !sale.isSynced).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: unsyncedCount > 0 ? Colors.orange : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            unsyncedCount > 0 ? Icons.sync_disabled : Icons.cloud_done,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            unsyncedCount > 0 ? '$unsyncedCount غير مزامن' : 'مزامن',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
