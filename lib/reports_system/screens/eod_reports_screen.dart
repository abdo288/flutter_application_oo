import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/eod_report.dart';
import '../providers/eod_reports_provider.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/date_range_picker.dart';
import '../widgets/loading_widget.dart' as loading_widget;
import '../widgets/search_widget.dart';

/// شاشة تقارير نهاية اليوم
class EODReportsScreen extends ConsumerStatefulWidget {
  const EODReportsScreen({super.key});

  @override
  ConsumerState<EODReportsScreen> createState() => _EODReportsScreenState();
}

class _EODReportsScreenState extends ConsumerState<EODReportsScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedEmployee = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// جلب التقارير الحقيقية من Firebase
  Future<void> _loadRealReports() async {
    try {
      debugPrint('🔍 جلب التقارير الحقيقية...');

      // إظهار مؤشر التحميل
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // تحديث provider للتقارير الحقيقية
      ref.invalidate(realEODReportsProvider);

      // إغلاق مؤشر التحميل
      if (mounted) {
        Navigator.of(context).pop();
      }

      debugPrint('📊 تم تحديث provider للتقارير الحقيقية');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث التقارير الحقيقية'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب التقارير الحقيقية: $e');

      if (mounted) {
        Navigator.of(context).pop(); // إغلاق مؤشر التحميل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب التقارير: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ EODReportsScreen: بناء الشاشة');

    // استخدام provider التقارير الحقيقية
    final AsyncValue<List<EODReport>> eodReports = ref.watch(realEODReportsProvider);

    debugPrint(
        '🏗️ EODReportsScreen: حالة eodReports: ${eodReports.runtimeType}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير نهاية اليوم'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              ref.invalidate(realEODReportsProvider);
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'فلاتر البحث',
          ),
          IconButton(
            onPressed: _loadRealReports,
            icon: const Icon(Icons.cloud_download),
            tooltip: 'جلب التقارير الحقيقية',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchWidget(
              onSearchChanged: (String query) {
                setState(() {
                  _searchController.text = query;
                });
              },
              hintText: 'البحث في تقارير نهاية اليوم...',
              showFilterButton: true,
              onFilterPressed: _showFilterDialog,
            ),
          ),

          // قائمة التقارير
          Expanded(
            child: eodReports.when(
              data: (List<EODReport> reports) {
                debugPrint(
                    '📊 EODReportsScreen: تم استلام ${reports.length} تقرير');

                // تطبيق الفلاتر محلياً
                List<EODReport> filteredReports = reports;

                // فلتر البحث
                if (_searchController.text.isNotEmpty) {
                  final String query = _searchController.text.toLowerCase();
                  filteredReports = filteredReports.where((EODReport report) => report.reportNumber.toLowerCase().contains(query) ||
                        report.employeeName.toLowerCase().contains(query)).toList();
                }

                // فلتر التاريخ
                if (_startDate != null) {
                  filteredReports = filteredReports.where((EODReport report) => report.date.isAfter(_startDate!) ||
                        report.date.isAtSameMomentAs(_startDate!)).toList();
                }

                if (_endDate != null) {
                  filteredReports = filteredReports.where((EODReport report) => report.date
                            .isBefore(_endDate!.add(const Duration(days: 1))) ||
                        report.date.isAtSameMomentAs(_endDate!)).toList();
                }

                // فلتر الموظف
                if (_selectedEmployee.isNotEmpty) {
                  filteredReports = filteredReports.where((EODReport report) => report.employeeId == _selectedEmployee).toList();
                }

                debugPrint(
                    '📊 EODReportsScreen: بعد الفلترة: ${filteredReports.length} تقرير');

                if (filteredReports.isEmpty) {
                  debugPrint(
                      '📊 EODReportsScreen: لا توجد تقارير بعد الفلترة - عرض EmptyWidget');
                  return const loading_widget.EmptyWidget(
                    message: 'لا توجد تقارير نهاية اليوم',
                    icon: Icons.description,
                  );
                }

                debugPrint(
                    '📊 EODReportsScreen: عرض ${filteredReports.length} تقرير في ListView');
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredReports.length,
                  itemBuilder: (BuildContext context, int index) {
                    final EODReport report = filteredReports[index];
                    debugPrint(
                        '📊 EODReportsScreen: بناء بطاقة التقرير ${index + 1}: ${report.reportNumber}');
                    return _buildEODReportCard(context, report);
                  },
                );
              },
              loading: () {
                debugPrint('📊 EODReportsScreen: في حالة التحميل');
                return const loading_widget.LoadingWidget(
                  message: 'جاري تحميل التقارير...',
                );
              },
              error: (Object error, StackTrace stack) => loading_widget.ErrorWidget(
                message: 'حدث خطأ في تحميل التقارير: $error',
                onRetry: () {
                  ref.read(refreshEODReportsProvider)();
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'eod_reports_fab',
        onPressed: _createNewEODReport,
        icon: const Icon(Icons.add),
        label: const Text('تقرير جديد'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEODReportCard(BuildContext context, EODReport report) {
    debugPrint(
        '🔧 _buildEODReportCard: بناء بطاقة للتقرير ${report.reportNumber}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showReportDetails(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // رأس البطاقة
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          report.reportNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(report.date),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // مؤشر حالة المزامنة
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.isSynced
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          report.isSynced
                              ? Icons.cloud_done
                              : Icons.cloud_upload,
                          size: 16,
                          color: report.isSynced ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.isSynced ? 'مزامن' : 'غير مزامن',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                report.isSynced ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // الإحصائيات
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatItem(
                      'إجمالي المبيعات',
                      '${report.totalSales.toStringAsFixed(2)} ر.س',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'الكمية المباعة',
                      '${report.totalItemsSold}',
                      Icons.inventory,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'المنتجات الفريدة',
                      '${report.uniqueProducts}',
                      Icons.category,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // معلومات إضافية
              Row(
                children: <Widget>[
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'الموظف: ${report.employeeName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'تم الإنشاء: ${_formatTime(report.generatedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // أزرار الإجراءات
              Row(
                children: <Widget>[
                  ActionButton(
                    label: 'عرض التفاصيل',
                    onPressed: () => _showReportDetails(context, report),
                    icon: Icons.visibility,
                    size: ActionButtonSize.small,
                  ),
                  const SizedBox(width: 8),
                  ActionButton(
                    label: 'طباعة',
                    onPressed: () => _printReport(report),
                    icon: Icons.print,
                    type: ActionButtonType.secondary,
                    size: ActionButtonSize.small,
                  ),
                  const SizedBox(width: 8),
                  ActionButton(
                    label: 'تصدير',
                    onPressed: () => _exportReport(report),
                    icon: Icons.download,
                    type: ActionButtonType.outline,
                    size: ActionButtonSize.small,
                  ),
                  if (!report.isSynced) ...<Widget>[
                    const SizedBox(width: 8),
                    ActionButton(
                      label: 'مزامنة',
                      onPressed: () => _syncReport(report),
                      icon: Icons.sync,
                      type: ActionButtonType.warning,
                      size: ActionButtonSize.small,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) => Column(
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('فلاتر البحث'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DateRangePickerWidget(
                startDate: _startDate ??
                    DateTime.now().subtract(const Duration(days: 30)),
                endDate: _endDate ?? DateTime.now(),
                onDateRangeChanged: (DateTimeRange<DateTime> range) {
                  setState(() {
                    _startDate = range.start;
                    _endDate = range.end;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedEmployee.isEmpty ? null : _selectedEmployee,
                decoration: const InputDecoration(
                  labelText: 'الموظف',
                  border: OutlineInputBorder(),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: '', child: Text('جميع الموظفين')),
                  DropdownMenuItem(
                      value: 'employee1', child: Text('أحمد محمد')),
                  DropdownMenuItem(
                      value: 'employee2', child: Text('فاطمة علي')),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedEmployee = value ?? '';
                  });
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
                _selectedEmployee = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('إعادة تعيين'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(BuildContext context, EODReport report) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('تفاصيل ${report.reportNumber}'),
        content: SizedBox(
          width: 600,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDetailRow('رقم التقرير', report.reportNumber),
                _buildDetailRow('التاريخ', _formatDate(report.date)),
                _buildDetailRow('الموظف', report.employeeName),
                _buildDetailRow('إجمالي المبيعات',
                    '${report.totalSales.toStringAsFixed(2)} ر.س'),
                _buildDetailRow('إجمالي الربح',
                    '${report.totalProfit.toStringAsFixed(2)} ر.س'),
                _buildDetailRow('الكمية المباعة', '${report.totalItemsSold}'),
                _buildDetailRow('المنتجات الفريدة', '${report.uniqueProducts}'),
                _buildDetailRow(
                    'حالة المزامنة', report.isSynced ? 'مزامن' : 'غير مزامن'),
                if (report.topProducts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  const Text(
                    'أفضل المنتجات:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...report.topProducts.take(5).map(
                        (TopProduct product) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Text(
                              '• ${product.name}: ${product.quantity} وحدة'),
                        ),
                      ),
                ],
              ],
            ),
          ),
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

  Widget _buildDetailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );

  void _createNewEODReport() {
    // TODO: تنفيذ إنشاء تقرير جديد
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ إنشاء تقرير جديد قريباً'),
      ),
    );
  }

  void _printReport(EODReport report) {
    // TODO: تنفيذ الطباعة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ الطباعة قريباً'),
      ),
    );
  }

  void _exportReport(EODReport report) {
    // TODO: تنفيذ التصدير
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم تنفيذ التصدير قريباً'),
      ),
    );
  }

  void _syncReport(EODReport report) {
    // TODO: تنفيذ المزامنة
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري مزامنة التقرير...'),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime time) => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
