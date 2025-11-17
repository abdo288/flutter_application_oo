import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sale.dart';
// ✅ استخدام النظام المحسن
import '../../providers/enhanced_pos_reports_providers.dart';
import '../models/common/date_range.dart';
import '../models/report_filter.dart';
import '../widgets/filter_widget.dart';
import '../widgets/loading_widget.dart' as loading_widget;
import '../widgets/stat_card_widget.dart';

/// شاشة المبيعات المحسنة
class SalesScreenFixed extends ConsumerStatefulWidget {
  const SalesScreenFixed({super.key});

  @override
  ConsumerState<SalesScreenFixed> createState() => _SalesScreenFixedState();
}

class _SalesScreenFixedState extends ConsumerState<SalesScreenFixed> {
  final TextEditingController _searchController = TextEditingController();
  ReportFilter _currentFilter = ReportFilter(
    dateRange: DateRange(
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    ),
    searchQuery: '',
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('المبيعات المحسنة'),
          actions: <Widget>[
            IconButton(
              onPressed: () {
                // ✅ تحديث البيانات باستخدام النظام المحسن
                ref.read(enhancedPOSReportsProvider.notifier).refreshData();
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث البيانات',
            ),
            IconButton(
              onPressed: _showExportDialog,
              icon: const Icon(Icons.download),
              tooltip: 'تصدير البيانات',
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            // ✅ فلاتر البحث المحسنة
            FilterWidget(
              filter: _currentFilter,
              onFilterChanged: (ReportFilter newFilter) {
                setState(() {
                  _currentFilter = newFilter;
                });
              },
            ),

            // إحصائيات ملخصة
            _buildSummaryStats(),

            // ✅ قائمة المبيعات المحسنة
            Expanded(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) {
                  final EnhancedPOSReportsState enhancedReports = ref.watch(enhancedPOSReportsProvider);
                  final List<Sale> sales = enhancedReports.sales;

                  if (enhancedReports.isLoading) {
                    return const loading_widget.LoadingWidget(
                      message: 'جاري تحميل المبيعات...',
                    );
                  }

                  if (enhancedReports.errorMessage != null) {
                    return loading_widget.ErrorWidget(
                      message:
                          'حدث خطأ في تحميل المبيعات: ${enhancedReports.errorMessage}',
                      onRetry: () {
                        ref
                            .read(enhancedPOSReportsProvider.notifier)
                            .refreshData();
                      },
                    );
                  }

                  if (sales.isEmpty) {
                    return const loading_widget.EmptyWidget(
                      message: 'لا توجد مبيعات',
                      icon: Icons.shopping_cart,
                    );
                  }

                  return Column(
                    children: <Widget>[
                      // شريط البحث
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'البحث في المبيعات',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (String value) {
                            // TODO: تطبيق البحث
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ جدول المبيعات المحسن
                      Expanded(
                        child: _buildEnhancedDataTable(sales),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildSummaryStats() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final EnhancedPOSReportsState enhancedReports = ref.watch(enhancedPOSReportsProvider);
          final List<Sale> sales = enhancedReports.sales;

          final int totalSales =
              sales.fold(0, (int sum, Sale sale) => sum + sale.totalAmount);
          final int transactionCount = sales.length;
          final double averageTransaction =
              transactionCount > 0 ? totalSales / transactionCount : 0.0;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: StatCardWidget(
                    title: 'إجمالي المبيعات',
                    value: '$totalSales دج',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCardWidget(
                    title: 'عدد المعاملات',
                    value: '$transactionCount',
                    icon: Icons.shopping_cart,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatCardWidget(
                    title: 'متوسط المعاملة',
                    value: '${averageTransaction.toStringAsFixed(0)} دج',
                    icon: Icons.trending_up,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          );
        },
      );

  void _showExportDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: const Text('سيتم تنفيذ التصدير قريباً'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  /// عرض تفاصيل عملية البيع
  void _showSaleDetailsDialog(Sale sale) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('تفاصيل عملية البيع #${sale.id ?? 'غير محدد'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('التاريخ: ${_formatDate(sale.saleDate)}'),
            Text('المبلغ الإجمالي: ${sale.totalAmount} دج'),
            Text('الربح الإجمالي: ${sale.totalProfit} دج'),
            Text('طريقة الدفع: ${sale.paymentMethod}'),
            if (sale.customerName != null)
              Text('اسم العميل: ${sale.customerName}'),
            if (sale.notes != null) Text('ملاحظات: ${sale.notes}'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _exportSale(Sale sale) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ التصدير قريباً'),
      ),
    );
  }

  // ✅ الدوال الجديدة للنظام المحسن

  /// بناء جدول البيانات المحسن
  Widget _buildEnhancedDataTable(List<Sale> sales) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'قائمة المبيعات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'إجمالي: ${sales.length} عملية بيع',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: sales.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Sale sale = sales[index];
                    return _buildSaleCard(sale);
                  },
                ),
              ),
            ],
          ),
        ),
      );

  /// بناء بطاقة المبيعات
  Widget _buildSaleCard(Sale sale) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green,
            child: Text(
              '${sale.totalAmount}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          title: Text(
            'عملية بيع #${sale.id ?? 'غير محدد'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('التاريخ: ${_formatDate(sale.saleDate)}'),
              Text('طريقة الدفع: ${sale.paymentMethod}'),
              if (sale.customerName != null)
                Text('العميل: ${sale.customerName}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                onPressed: () => _showSaleDetailsDialog(sale),
                icon: const Icon(Icons.visibility),
                tooltip: 'عرض التفاصيل',
              ),
              IconButton(
                onPressed: () => _exportSale(sale),
                icon: const Icon(Icons.download),
                tooltip: 'تصدير',
              ),
            ],
          ),
        ),
      );
}
