import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../models/quick_inventory_item.dart';
import '../providers/stream_app_provider.dart';
import '../providers/stream_inventory_provider.dart';
import '../services/pos_service.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/barcode_scanner_view.dart';

/// شاشة الجرد السريع
class QuickInventoryTab extends StatefulWidget {
  const QuickInventoryTab({super.key});

  @override
  State<QuickInventoryTab> createState() => _QuickInventoryTabState();
}

class _QuickInventoryTabState extends State<QuickInventoryTab> {
  final List<QuickInventoryItem> _scannedItems = <QuickInventoryItem>[];
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isUpdatingInventory = false;

  @override
  void initState() {
    super.initState();
    // تأجيل تحميل البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadScannedItems();
      }
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// تحميل العناصر الممسوحة
  Future<void> _loadScannedItems() async {
    try {
      final List<QuickInventoryItem> items =
          await POSService.getAllQuickInventoryItems();
      if (mounted) {
        setState(() {
          _scannedItems.clear();
          _scannedItems.addAll(items);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحميل العناصر الممسوحة: $e');
      }
    }
  }

  /// مسح الباركود
  Future<void> _scanBarcode() async {
    try {
      final String? barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (BuildContext context) => const BarcodeScannerView(),
        ),
      );

      if (barcode != null && barcode.isNotEmpty) {
        _barcodeController.text = barcode;
        await _addScannedItem(barcode);
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في مسح الباركود: $e');
    }
  }

  /// إضافة عنصر ممسوح
  Future<void> _addScannedItem(String barcode) async {
    if (barcode.trim().isEmpty) return;

    // التحقق من وجود العنصر مسبقاً
    final bool alreadyExists =
        _scannedItems.any((QuickInventoryItem item) => item.barcode == barcode);
    if (alreadyExists) {
      SnackbarUtils.showWarning(context, 'هذا المنتج تم مسحه مسبقاً');
      return;
    }

    // Optimistic UI: أضف عنصرًا مؤقتًا فورًا
    final QuickInventoryItem tempItem = QuickInventoryItem(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      barcode: barcode.trim(),
      name: 'جاري الإضافة...',
      scannedQuantity: 1,
      scanDate: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() {
      _scannedItems.add(tempItem);
    });

    _barcodeController.clear();
    _quantityController.clear();
    _notesController.clear();

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;
      final QuickInventoryItem item = await POSService.addToQuickInventory(
        inventoryProvider: inventoryProvider,
        barcode: tempItem.barcode,
        quantity: tempItem.scannedQuantity,
        notes: tempItem.notes,
      );

      if (mounted) {
        setState(() {
          final int idx = _scannedItems
              .indexWhere((QuickInventoryItem it) => it.id == tempItem.id);
          if (idx != -1) {
            _scannedItems[idx] = item;
          }
        });
        SnackbarUtils.showSuccess(context, 'تم إضافة ${item.name} إلى الجرد');
      }
    } catch (e) {
      // تراجع عن الإدراج المؤقت
      if (mounted) {
        setState(() {
          _scannedItems
              .removeWhere((QuickInventoryItem it) => it.id == tempItem.id);
        });
        SnackbarUtils.showError(context, 'خطأ في إضافة العنصر: $e');
      }
    }
  }

  /// تحديث كمية عنصر ممسوح
  Future<void> _updateScannedQuantity(
      QuickInventoryItem item, int newQuantity) async {
    if (newQuantity < 0) return;

    setState(() {
      final int index = _scannedItems.indexWhere(
          (QuickInventoryItem scannedItem) => scannedItem.id == item.id);
      if (index != -1) {
        _scannedItems[index] =
            _scannedItems[index].copyWith(scannedQuantity: newQuantity);
      }
    });
  }

  /// حذف عنصر ممسوح - دالة محسنة بالكامل مع مراقبة شاملة
  Future<void> _removeScannedItem(QuickInventoryItem item) async {
    // بدء تتبع العملية
    _logDeleteOperationStart(item);

    // التحقق من صحة البيانات باستخدام الدالة المساعدة
    if (!_isValidItemForDeletion(item)) {
      _logDeleteOperationError('البيانات غير صالحة للحذف', item);
      if (mounted) {
        SnackbarUtils.showError(context, 'البيانات غير صالحة للحذف');
      }
      return;
    }

    // التحقق من وجود العنصر في القائمة
    final int itemIndex =
        _scannedItems.indexWhere((QuickInventoryItem it) => it.id == item.id);
    _logItemIndexFound(itemIndex, item);

    if (itemIndex == -1) {
      _logDeleteOperationError('العنصر غير موجود في القائمة', item);
      if (mounted) {
        SnackbarUtils.showError(context, 'العنصر غير موجود في القائمة');
      }
      return;
    }

    // عرض تأكيد الحذف مع تفاصيل أكثر
    _logShowDeleteConfirmation(item);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // منع الإغلاق بالضغط خارج الحوار
      builder: (BuildContext context) => DeleteConfirmationDialog(
        title: 'حذف العنصر من الجرد',
        message:
            'هل تريد حذف "${item.name}" (${item.barcode}) من الجرد السريع؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
        onConfirm: () {}, // dummy callback - لن يُستخدم
      ),
    );

    // إذا لم يؤكد المستخدم، لا نفعل شيئاً
    _logUserConfirmation(confirmed, item);
    if (confirmed != true) {
      _logDeleteOperationCancelled(item);
      return;
    }

    // تسجيل تأكيد المستخدم للمتابعة
    _logUserConfirmedDeletion(item);

    // حفظ نسخة احتياطية للتراجع في حالة الخطأ
    final QuickInventoryItem backupItem = _scannedItems[itemIndex];
    final int backupIndex = itemIndex;
    _logBackupCreated(backupItem, backupIndex);

    try {
      // إظهار مؤشر التحميل
      _logStartingDeleteProcess(item);
      if (mounted) {
        setState(() {
          _isUpdatingInventory = true;
        });
      }

      // حذف من قاعدة البيانات أولاً
      _logDeletingFromDatabase(item);
      await POSService.deleteQuickInventoryItem(item.id!);
      _logDatabaseDeleteSuccess(item);

      // إذا نجح الحذف من قاعدة البيانات، احذف من الواجهة
      _logRemovingFromUI(item);
      if (mounted) {
        setState(() {
          _scannedItems.removeAt(itemIndex);
          _isUpdatingInventory = false;
        });
      }
      _logUIRemovalSuccess(item);

      // تأخير قصير لضمان اكتمال العملية
      _logWaitingForCompletion();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // إظهار رسالة نجاح
      if (mounted) {
        SnackbarUtils.showSuccess(
            context, 'تم حذف "${item.name}" من الجرد السريع بنجاح');
      }

      // تسجيل العملية
      _logDeleteOperationComplete(item);
    } catch (e) {
      // في حالة الخطأ، أعد العنصر للقائمة
      _logDeleteOperationError('خطأ في حذف العنصر', item, e);

      if (mounted) {
        setState(() {
          _isUpdatingInventory = false;
          // إعادة إدراج العنصر في نفس الموضع
          _scannedItems.insert(backupIndex, backupItem);
        });
      }
      _logItemRestored(backupItem, backupIndex);

      // تسجيل الخطأ
      debugPrint('❌ خطأ في حذف عنصر الجرد السريع: $e');

      // إظهار رسالة خطأ مفصلة
      if (mounted) {
        SnackbarUtils.showError(context, 'فشل في حذف العنصر: ${e.toString()}');
      }

      // محاولة إعادة تحميل البيانات للتأكد من التزامن
      _logAttemptingReload();
      await _reloadScannedItemsSafely();
    }
  }

  /// دالة مساعدة للتحقق من صحة العنصر قبل الحذف
  bool _isValidItemForDeletion(QuickInventoryItem item) {
    if (item.id == null || item.id!.isEmpty) {
      debugPrint('❌ معرف العنصر فارغ أو غير صالح');
      return false;
    }

    if (item.name.isEmpty) {
      debugPrint('❌ اسم العنصر فارغ');
      return false;
    }

    return true;
  }

  /// دالة مساعدة لإعادة تحميل البيانات مع معالجة الأخطاء
  Future<void> _reloadScannedItemsSafely() async {
    try {
      await _loadScannedItems();
      if (mounted) {
        SnackbarUtils.showInfo(context, 'تم إعادة تحميل البيانات بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل البيانات: $e');
      if (mounted) {
        SnackbarUtils.showError(context, 'فشل في إعادة تحميل البيانات');
      }
    }
  }

  // ========== دوال التتبع والمراقبة للحذف ==========

  /// تسجيل بداية عملية الحذف
  void _logDeleteOperationStart(QuickInventoryItem item) {
    debugPrint('🚀 [DELETE] بدء عملية حذف العنصر:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   🔢 الكمية الممسوحة: ${item.scannedQuantity}');
    debugPrint('   📅 تاريخ المسح: ${item.scanDate}');
    debugPrint('   🆕 منتج جديد: ${item.isNewProduct}');
    debugPrint('   📝 الملاحظات: ${item.notes ?? "لا توجد"}');
  }

  /// تسجيل خطأ في عملية الحذف
  void _logDeleteOperationError(String error, QuickInventoryItem item,
      [exception]) {
    debugPrint('❌ [DELETE ERROR] $error:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    if (exception != null) {
      debugPrint('   🔍 تفاصيل الخطأ: $exception');
    }
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل العثور على فهرس العنصر
  void _logItemIndexFound(int index, QuickInventoryItem item) {
    debugPrint('🔍 [DELETE] البحث عن العنصر في القائمة:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   📍 الفهرس: $index');
    debugPrint('   📋 إجمالي العناصر: ${_scannedItems.length}');
  }

  /// تسجيل عرض تأكيد الحذف
  void _logShowDeleteConfirmation(QuickInventoryItem item) {
    debugPrint('💬 [DELETE] عرض تأكيد الحذف:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل تأكيد المستخدم
  void _logUserConfirmation(bool? confirmed, QuickInventoryItem item) {
    debugPrint('👤 [DELETE] رد المستخدم:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   ✅ تأكيد: ${confirmed == true ? "نعم" : "لا"}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل إلغاء عملية الحذف
  void _logDeleteOperationCancelled(QuickInventoryItem item) {
    debugPrint('🚫 [DELETE CANCELLED] تم إلغاء عملية الحذف:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل تأكيد المستخدم للمتابعة
  void _logUserConfirmedDeletion(QuickInventoryItem item) {
    debugPrint('✅ [DELETE CONFIRMED] تأكيد المستخدم للمتابعة:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل إنشاء النسخة الاحتياطية
  void _logBackupCreated(QuickInventoryItem backupItem, int backupIndex) {
    debugPrint('💾 [DELETE] إنشاء نسخة احتياطية:');
    debugPrint('   📦 المعرف: ${backupItem.id}');
    debugPrint('   📝 الاسم: ${backupItem.name}');
    debugPrint('   📊 الباركود: ${backupItem.barcode}');
    debugPrint('   📍 الفهرس: $backupIndex');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل بدء عملية الحذف
  void _logStartingDeleteProcess(QuickInventoryItem item) {
    debugPrint('⚙️ [DELETE] بدء عملية الحذف:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   🔄 حالة التحديث: $_isUpdatingInventory');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل حذف من قاعدة البيانات
  void _logDeletingFromDatabase(QuickInventoryItem item) {
    debugPrint('🗄️ [DELETE] حذف من قاعدة البيانات:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل نجاح حذف من قاعدة البيانات
  void _logDatabaseDeleteSuccess(QuickInventoryItem item) {
    debugPrint('✅ [DELETE] نجح الحذف من قاعدة البيانات:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل حذف من الواجهة
  void _logRemovingFromUI(QuickInventoryItem item) {
    debugPrint('🖥️ [DELETE] حذف من الواجهة:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   📋 العناصر المتبقية: ${_scannedItems.length - 1}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل نجاح حذف من الواجهة
  void _logUIRemovalSuccess(QuickInventoryItem item) {
    debugPrint('✅ [DELETE] نجح الحذف من الواجهة:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   📋 العناصر المتبقية: ${_scannedItems.length}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل انتظار اكتمال العملية
  void _logWaitingForCompletion() {
    debugPrint('⏳ [DELETE] انتظار اكتمال العملية...');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل اكتمال عملية الحذف
  void _logDeleteOperationComplete(QuickInventoryItem item) {
    debugPrint('🎉 [DELETE COMPLETE] اكتملت عملية الحذف بنجاح:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   📋 العناصر المتبقية: ${_scannedItems.length}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
    debugPrint('   🕐 مدة العملية: ${DateTime.now().millisecondsSinceEpoch}ms');
  }

  /// تسجيل استعادة العنصر
  void _logItemRestored(QuickInventoryItem item, int index) {
    debugPrint('🔄 [DELETE] استعادة العنصر:');
    debugPrint('   📦 المعرف: ${item.id}');
    debugPrint('   📝 الاسم: ${item.name}');
    debugPrint('   📊 الباركود: ${item.barcode}');
    debugPrint('   📍 الفهرس: $index');
    debugPrint('   📋 إجمالي العناصر: ${_scannedItems.length}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تسجيل محاولة إعادة التحميل
  void _logAttemptingReload() {
    debugPrint('🔄 [DELETE] محاولة إعادة تحميل البيانات:');
    debugPrint('   📋 العناصر الحالية: ${_scannedItems.length}');
    debugPrint('   ⏰ الوقت: ${DateTime.now().toIso8601String()}');
  }

  /// تحديث المخزون من الجرد السريع
  Future<void> _updateInventory() async {
    if (_scannedItems.isEmpty) {
      SnackbarUtils.showError(context, 'لا توجد عناصر ممسوحة لتحديث المخزون');
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تحديث المخزون'),
        content: Text(
            'هل تريد تحديث المخزون بناءً على ${_scannedItems.length} عنصر ممسوح؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تحديث'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() {
        _isUpdatingInventory = true;
      });
    }

    // إنشاء نسخة احتياطية من العناصر الممسوحة
    final List<QuickInventoryItem> backupItems =
        List<QuickInventoryItem>.from(_scannedItems);

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamInventoryProvider inventoryProvider =
          appProvider.inventoryProvider;
      await POSService.updateInventoryFromQuickInventory(
          inventoryProvider, _scannedItems);
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم تحديث المخزون بنجاح');

        // مسح العناصر الممسوحة فقط بعد نجاح التحديث
        await _clearScannedItemsAfterSuccess();
      }
    } catch (e) {
      if (mounted) {
        // في حالة الفشل، لا نمسح العناصر الممسوحة
        SnackbarUtils.showError(context, 'خطأ في تحديث المخزون: $e');

        // إعادة تحميل العناصر الممسوحة من النسخة الاحتياطية
        setState(() {
          _scannedItems.clear();
          _scannedItems.addAll(backupItems);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingInventory = false;
        });
      }
    }
  }

  /// مسح العناصر الممسوحة بعد نجاح التحديث
  Future<void> _clearScannedItemsAfterSuccess() async {
    try {
      // مسح العناصر من قاعدة البيانات المحلية
      await POSService.clearQuickInventory();

      // مسح العناصر من الواجهة
      if (mounted) {
        setState(_scannedItems.clear);
      }
    } catch (e) {
      // في حالة فشل مسح قاعدة البيانات، نمسح الواجهة فقط
      if (mounted) {
        setState(_scannedItems.clear);
        SnackbarUtils.showWarning(context,
            'تم مسح العناصر من الواجهة، لكن قد تحتاج لإعادة تشغيل التطبيق');
      }
    }
  }

  /// مسح جميع العناصر الممسوحة
  Future<void> _clearScannedItems() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('مسح الجرد'),
        content: const Text('هل تريد مسح جميع العناصر الممسوحة؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('مسح'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Optimistic UI: امسح فورًا مع نسخة احتياطية
      final List<QuickInventoryItem> backup =
          List<QuickInventoryItem>.from(_scannedItems);
      setState(_scannedItems.clear);
      try {
        await POSService.clearQuickInventory();
        SnackbarUtils.showSuccess(context, 'تم مسح جميع العناصر الممسوحة');
      } catch (e) {
        // تراجع
        setState(() {
          _scannedItems.addAll(backup);
        });
        SnackbarUtils.showError(context, 'خطأ في مسح العناصر: $e');
      }
    }
  }

  /// تصدير تقرير الجرد
  Future<void> _exportInventoryReport() async {
    if (_scannedItems.isEmpty) {
      SnackbarUtils.showError(context, 'لا توجد عناصر ممسوحة للتصدير');
      return;
    }

    try {
      // إنشاء تقرير نصي بسيط
      final StringBuffer report = StringBuffer();
      report.writeln('تقرير الجرد السريع');
      report
          .writeln('تاريخ التقرير: ${DateTime.now().toString().split(' ')[0]}');
      report.writeln(
          'وقت التقرير: ${DateTime.now().toString().split(' ')[1].split('.')[0]}');
      report.writeln('=' * 50);
      report.writeln();

      for (final QuickInventoryItem item in _scannedItems) {
        report.writeln('اسم المنتج: ${item.name}');
        report.writeln('الباركود: ${item.barcode}');
        report.writeln('الكمية الممسوحة: ${item.scannedQuantity}');
        report
            .writeln('الكمية السابقة: ${item.originalQuantity ?? 'غير محدد'}');
        report.writeln(
            'الفرق: ${item.originalQuantity != null ? item.scannedQuantity - item.originalQuantity! : 'غير محدد'}');
        report.writeln('-' * 30);
      }

      // استخدام share_plus لحفظ ومشاركة الملف
      await Share.share(
        report.toString(),
        subject: 'تقرير الجرد السريع',
      );

      SnackbarUtils.showSuccess(context, 'تم تصدير التقرير بنجاح');
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في تصدير التقرير: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('الجرد السريع'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: <Widget>[
            if (_scannedItems.isNotEmpty) ...<Widget>[
              IconButton(
                onPressed: _exportInventoryReport,
                icon: const Icon(Icons.file_download),
                tooltip: 'تصدير التقرير',
              ),
              IconButton(
                onPressed: _clearScannedItems,
                icon: const Icon(Icons.clear_all),
                tooltip: 'مسح الجرد',
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // شريط مسح الباركود
              _buildBarcodeInputSection(),

              // إحصائيات الجرد
              _buildInventoryStats(),

              // قائمة العناصر الممسوحة
              if (_scannedItems.isEmpty)
                _buildEmptyInventory()
              else
                _buildScannedItemsList(),

              // شريط تحديث المخزون
              if (_scannedItems.isNotEmpty) _buildUpdateInventorySection(),
            ],
          ),
        ),
      );

  /// بناء قسم إدخال الباركود
  Widget _buildBarcodeInputSection() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'باركود المنتج',
                      hintText: 'أدخل الباركود أو امسحه',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _addScannedItem,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'مسح الباركود',
                    color: Colors.white,
                    iconSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
            ),
          ],
        ),
      );

  /// بناء إحصائيات الجرد
  Widget _buildInventoryStats() {
    if (_scannedItems.isEmpty) return const SizedBox.shrink();

    final int totalItems = _scannedItems.length;
    final int newProducts = _scannedItems
        .where((QuickInventoryItem item) => item.isNewProduct)
        .length;
    final int itemsWithDifference = _scannedItems
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
              'الجرد فارغ',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'امسح الباركود أو أدخل الباركود لبدء الجرد',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// بناء قائمة العناصر الممسوحة
  Widget _buildScannedItemsList() => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _scannedItems.length,
        itemBuilder: (BuildContext context, int index) {
          final QuickInventoryItem item = _scannedItems[index];
          return _buildScannedItemCard(item);
        },
      );

  /// بناء بطاقة عنصر ممسوح
  Widget _buildScannedItemCard(QuickInventoryItem item) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // معلومات المنتج
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'باركود: ${item.barcode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (item.isNewProduct)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'منتج جديد',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // زر الحذف مع مؤشر تحميل
                  IconButton(
                    onPressed: _isUpdatingInventory
                        ? null
                        : () => _removeScannedItem(item),
                    icon: _isUpdatingInventory
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          )
                        : const Icon(Icons.delete),
                    style: IconButton.styleFrom(
                      backgroundColor: _isUpdatingInventory
                          ? Colors.grey[100]
                          : Colors.red[50],
                      foregroundColor:
                          _isUpdatingInventory ? Colors.grey : Colors.red,
                    ),
                    tooltip:
                        _isUpdatingInventory ? 'جاري الحذف...' : 'حذف العنصر',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // معلومات الكمية
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (item.originalQuantity != null) ...<Widget>[
                          Text(
                            'الكمية الأصلية: ${item.originalQuantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          'الكمية الممسوحة: ${item.scannedQuantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // أدوات التحكم في الكمية
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _updateScannedQuantity(
                            item, item.scannedQuantity - 1),
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.scannedQuantity.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _updateScannedQuantity(
                            item, item.scannedQuantity + 1),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // حالة الكمية
              if (item.originalQuantity != null) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.getQuantityStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: item.getQuantityStatusColor()),
                  ),
                  child: Text(
                    item.getQuantityStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: item.getQuantityStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              // ملاحظات
              if (item.notes != null && item.notes!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'ملاحظات: ${item.notes}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  /// بناء قسم تحديث المخزون
  Widget _buildUpdateInventorySection() => Container(
        constraints: const BoxConstraints(
          maxHeight: 100, // حد أقصى للارتفاع
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdatingInventory ? null : _updateInventory,
                  icon: _isUpdatingInventory
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.update),
                  label: Text(_isUpdatingInventory
                      ? 'جاري التحديث...'
                      : 'تحديث المخزون'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
