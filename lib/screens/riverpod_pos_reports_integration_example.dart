import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'enhanced_pos_reports_screen_riverpod.dart';
import '../providers/pos_reports_riverpod_providers.dart';

/// مثال على كيفية دمج شاشة تقارير POS الجديدة مع Riverpod
class RiverpodPOSReportsIntegrationExample extends ConsumerWidget {
  const RiverpodPOSReportsIntegrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مثال دمج تقارير POS - Riverpod'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.analytics,
              size: 80,
              color: Colors.purple,
            ),
            const SizedBox(height: 20),
            const Text(
              'تقارير نقطة البيع المحسنة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'نسخة Riverpod مع إدارة حالة محسنة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _navigateToReports(context),
              icon: const Icon(Icons.bar_chart),
              label: const Text('فتح التقارير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'المميزات الجديدة:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• إدارة حالة محسنة مع Riverpod\n'
              '• إعادة بناء تفاعلية\n'
              '• سهولة الاختبار والصيانة\n'
              '• أداء أفضل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// التنقل إلى شاشة التقارير
  void _navigateToReports(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const EnhancedPOSReportsScreenRiverpod(),
      ),
    );
  }
}

/// مثال على كيفية استخدام الـ providers في widget آخر
class POSReportsStatsWidget extends ConsumerWidget {
  const POSReportsStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final POSReportsState state = ref.watch(posReportsProvider);
    final int unsyncedCount = ref.watch(unsyncedSalesCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'إحصائيات سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatItem(
                    'المبيعات',
                    state.sales.length.toString(),
                    Icons.shopping_cart,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'الجرد السريع',
                    state.quickInventoryItems.length.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatItem(
                    'غير مزامن',
                    unsyncedCount.toString(),
                    Icons.sync_disabled,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'الحالة',
                    (state.isLoading == true) ? 'جاري التحميل' : 'جاهز',
                    (state.isLoading == true)
                        ? Icons.hourglass_empty
                        : Icons.check_circle,
                    (state.isLoading == true) ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: <Widget>[
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

/// مثال على كيفية إضافة الشاشة إلى BottomNavigationBar
class MainNavigationExample extends ConsumerWidget {
  const MainNavigationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const Center(
        child: Text('الصفحة الرئيسية'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'نقطة البيع',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'التقارير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
        onTap: (int index) {
          switch (index) {
            case 0:
              // الصفحة الرئيسية
              break;
            case 1:
              // نقطة البيع
              break;
            case 2:
              // التقارير - فتح النسخة الجديدة
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) =>
                      const EnhancedPOSReportsScreenRiverpod(),
                ),
              );
              break;
            case 3:
              // الإعدادات
              break;
          }
        },
      ),
    );
  }
}
