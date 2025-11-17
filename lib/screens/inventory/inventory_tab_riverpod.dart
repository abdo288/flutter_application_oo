import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/inventory_riverpod_providers.dart';
import '../../providers/riverpod/stream_app_riverpod_provider.dart';
import '../../providers/riverpod/stream_inventory_riverpod_provider.dart'
    as stream;
import '../../utils/constants.dart';
import '../../utils/responsive_breakpoints.dart';
import 'widgets/action_buttons_section.dart';
import 'widgets/advanced_options_section.dart';
import 'widgets/basic_info_section.dart';
import 'widgets/header_section.dart';
import 'widgets/loading_states.dart';
import 'widgets/price_quantity_section.dart';

/// تبويب نموذج المنتج المحسن بـ Riverpod - لإضافة/تعديل منتج جديد
class ProductFormTabRiverpod extends ConsumerStatefulWidget {
  const ProductFormTabRiverpod({
    super.key,
    required this.onInventoryUpdated,
  });

  final VoidCallback onInventoryUpdated;

  @override
  ConsumerState<ProductFormTabRiverpod> createState() =>
      _ProductFormTabRiverpodState();
}

class _ProductFormTabRiverpodState extends ConsumerState<ProductFormTabRiverpod>
    with AutomaticKeepAliveClientMixin<ProductFormTabRiverpod> {
  @override
  void initState() {
    super.initState();
    // تأجيل تهيئة البيانات حتى بعد انتهاء بناء الـ widget tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  bool get wantKeepAlive => true;

  /// تهيئة البيانات
  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      // تأجيل تهيئة البيانات حتى بعد انتهاء بناء الـ widget tree
      await Future<void>.delayed(Duration.zero);
      await ref.read(inventoryStateProvider.notifier).initialize();
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة البيانات: $e');
    }
  }

  /// Pull-to-refresh لإعادة تحميل بيانات المخزون
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 بدء تحديث بيانات المخزون...');

      final AppState appState = ref.read(appControllerProvider);

      if (!appState.isInitialized) {
        debugPrint('⚠️ التطبيق لم يتم تهيئته بعد');
        return;
      }

      // إعادة تحميل البيانات من stream controller
      await ref.read(stream.inventoryControllerProvider.notifier).refresh();

      // إعادة تحميل حالة تبويب نموذج المنتج
      await ref.read(inventoryStateProvider.notifier).initialize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث بيانات المخزون بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        debugPrint('✅ تم تحديث بيانات المخزون بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث بيانات المخزون: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('خطأ في التحديث: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    debugPrint('🏗️ RIVERPOD: ProductFormTabRiverpod build() called');

    // مراقبة رسالة الخطأ
    final String? errorMessage = ref.watch(inventoryErrorProvider);

    // التحقق من أن Provider مهيأ
    final AppState appState = ref.read(appControllerProvider);
    if (!appState.isInitialized) {
      return LoadingStates.buildShimmerLoading();
    }

    // التحقق من وجود خطأ
    if (errorMessage != null) {
      return LoadingStates.buildErrorState(
          context, errorMessage, _initializeData);
    }

    try {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double width = constraints.maxWidth;
          final bool isWide = width >= 700;
          final double maxFormWidth = isWide ? 800.0 : width;

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppConstants.primaryColor,
            backgroundColor: Colors.white,
            strokeWidth: 3.0,
            displacement: 60,
            child: SingleChildScrollView(
              physics: context.responsiveScrollPhysics,
              padding: context.responsivePadding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // العنوان الرئيسي
                      const HeaderSection(),

                      SizedBox(height: context.responsiveSpacing * 2),

                      // معلومات المنتج الأساسية
                      const BasicInfoSection(),

                      SizedBox(height: context.responsiveSpacing),

                      // معلومات السعر والكمية
                      const PriceQuantitySection(),

                      SizedBox(height: context.responsiveSpacing),

                      // خيارات متقدمة
                      const AdvancedOptionsSection(),

                      SizedBox(height: context.responsiveSpacing * 2),

                      // أزرار الإجراءات
                      ActionButtonsSection(
                        onAddItem: _addInventoryItem,
                        onClearFields: _clearFields,
                        onBulkAdd: _showBulkAddDialog,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ خطأ في بناء ProductFormTabRiverpod: $e');
      return LoadingStates.buildErrorState(
          context, 'خطأ في تحميل تبويب نموذج المنتج', _initializeData);
    }
  }

  /// إضافة عنصر مخزون
  Future<void> _addInventoryItem() async {
    try {
      // استخدام stream.inventoryControllerProvider للتحديث المباشر
      final bool success =
          await ref.read(inventoryStateProvider.notifier).addInventoryItem();

      if (success && mounted) {
        // إعادة تحميل البيانات في stream controller لضمان التزامن
        await ref.read(stream.inventoryControllerProvider.notifier).refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم إضافة العنصر بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // إشعار التبويبات الأخرى بالتحديث
        widget.onInventoryUpdated();
      }
    } catch (e) {
      debugPrint('❌ خطأ في إضافة عنصر المخزون: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: <Widget>[
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('خطأ في إضافة العنصر: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// مسح الحقول
  void _clearFields() {
    ref.read(inventoryStateProvider.notifier).clearForm();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: <Widget>[
              Icon(Icons.clear_all, color: Colors.white),
              SizedBox(width: 8),
              Text('تم مسح النموذج'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// عرض نافذة الإضافة المجمعة
  void _showBulkAddDialog() {
    // TODO: Implement bulk add dialog
    debugPrint('Show bulk add dialog - TODO: Implement');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: <Widget>[
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('ميزة الإضافة المجمعة قيد التطوير'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
