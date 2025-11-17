import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/page_result.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../models/cart_item.dart';
import '../models/eod_report.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/eod_process_provider.dart';
import '../providers/pos_riverpod_providers.dart';
import '../providers/realtime_update_manager.dart';
import '../reports_system/providers/eod_reports_provider.dart';
import '../services/app_event_bus.dart';
import '../services/connectivity_service.dart';
import '../services/cross_tab_sync_service.dart';
import '../services/eod_service.dart';
// ✅ استخدام النظام المحسن
import '../services/error_handler_service.dart';
import '../services/navigation_service.dart';
import '../services/pos_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/pos_product_search_widget.dart';

// Simple currency formatter function
String formatCurrency(int amount) => '${amount.toString()} DZ';

/// شاشة نقطة البيع (POS) مع Riverpod
class POSTabRiverpod extends ConsumerStatefulWidget {
  const POSTabRiverpod({super.key});

  @override
  ConsumerState<POSTabRiverpod> createState() => _POSTabRiverpodState();
}

class _POSTabRiverpodState extends ConsumerState<POSTabRiverpod>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _barcodeController = TextEditingController();
  final Map<String, TextEditingController> _discountControllers =
      <String, TextEditingController>{};

  bool _showDiscountedOnly = false;

  // متغيرات التحسينات الجديدة
  Timer? _searchDebounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // متغيرات إدارة الجلسة والاستماع
  String? _currentSessionId;
  StreamSubscription<List<CartItem>>? _cartFirebaseSubscription;

  // متغيرات إدارة إنهاء اليوم
  String _currentStep = '';
  bool _isProcessingEOD = false;

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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // تهيئة السلة مع استرجاع من Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCartAndSession();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _barcodeController.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    // إيقاف الاستماع للسلة
    _cartFirebaseSubscription?.cancel();

    // تنظيف discount controllers
    for (final TextEditingController controller
        in _discountControllers.values) {
      controller.dispose();
    }
    _discountControllers.clear();
    super.dispose();
  }

  /// تهيئة السلة والجلسة
  Future<void> _initializeCartAndSession() async {
    try {
      debugPrint('🛒 بدء تهيئة السلة والجلسة في POS Tab');

      // تهيئة CartNotifier أولاً
      await ref.read(cartStateProvider.notifier).initialize();

      // إنشاء جلسة POS مشتركة
      _currentSessionId =
          'shared_pos_session_${DateTime.now().toIso8601String().split('T')[0]}';
      await POSService.savePOSSession(
        sessionId: _currentSessionId!,
        platform: 'POS Tab',
        deviceInfo: 'POS Tab Riverpod',
      );

      // استرجاع السلة من Firebase
      await _loadCartFromFirebase();

      // بدء الاستماع لتغييرات السلة في Firebase
      _startCartFirebaseListening();

      debugPrint('✅ تم تهيئة السلة والجلسة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة السلة والجلسة: $e');
    }
  }

  /// استعادة السلة من Firebase
  Future<void> _loadCartFromFirebase() async {
    if (_currentSessionId == null || !mounted) return;

    try {
      final List<CartItem> firebaseCart = await POSService.loadCartFromFirebase(
        sessionId: _currentSessionId!,
      );

      if (firebaseCart.isNotEmpty && mounted) {
        debugPrint('🔄 Firebase: تم العثور على ${firebaseCart.length} عنصر');
        final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
        final CartState cartState = ref.read(cartStateProvider);
        final List<CartItem> currentCart = cartState.cart;
        debugPrint('🔄 المحلي: ${currentCart.length} عنصر');

        // فقط إذا كانت السلة المحلية فارغة أو مختلفة
        if (currentCart.isEmpty || !_areCartsEqual(firebaseCart, currentCart)) {
          // مسح السلة الحالية
          cartNotifier.clearCart();

          // إضافة العناصر من Firebase
          for (final CartItem item in firebaseCart) {
            cartNotifier.addItem(item);
          }

          if (mounted) {
            setState(() {});
          }

          debugPrint('✅ تم استعادة ${firebaseCart.length} عنصر من Firebase');
        } else {
          debugPrint('🔄 السلة المحلية متطابقة مع Firebase - تجاهل التحديث');
        }
      } else {
        debugPrint('🔄 Firebase فارغ - لا توجد عناصر لاستعادتها');
      }
    } catch (e) {
      debugPrint('❌ خطأ في استعادة السلة من Firebase: $e');
    }
  }

  /// بدء الاستماع لتغييرات السلة في Firebase
  void _startCartFirebaseListening() {
    if (_currentSessionId == null) return;

    _cartFirebaseSubscription = POSService.watchCartFromFirebase(
      sessionId: _currentSessionId!,
    ).listen((List<CartItem> firebaseCart) async {
      if (!mounted) return;

      try {
        final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
        final CartState cartState = ref.read(cartStateProvider);
        final List<CartItem> currentCart = cartState.cart;

        // تجاهل التحديثات الفارغة أو المتطابقة
        if (firebaseCart.isEmpty && currentCart.isEmpty) {
          debugPrint('🔄 Firebase و SharedPreferences فارغان - تجاهل التحديث');
          return;
        }

        // مقارنة السلة المحلية مع Firebase
        if (firebaseCart.length != currentCart.length ||
            !_areCartsEqual(firebaseCart, currentCart)) {
          debugPrint('🔄 تم اكتشاف تغيير في السلة من Firebase');
          debugPrint('🔄 Firebase: ${firebaseCart.length} عنصر');
          debugPrint('🔄 المحلي: ${currentCart.length} عنصر');

          // فقط إذا كان Firebase يحتوي على عناصر
          if (firebaseCart.isNotEmpty) {
            // مسح السلة الحالية
            cartNotifier.clearCart();

            // إضافة العناصر من Firebase
            for (final CartItem item in firebaseCart) {
              cartNotifier.addItem(item);
            }

            if (mounted) {
              setState(() {});
            }
          }
        }
      } catch (e) {
        debugPrint('❌ خطأ في معالجة تغييرات السلة من Firebase: $e');
      }
    });
  }

  /// مقارنة السلات
  bool _areCartsEqual(List<CartItem> cart1, List<CartItem> cart2) {
    if (cart1.length != cart2.length) return false;

    for (int i = 0; i < cart1.length; i++) {
      final CartItem item1 = cart1[i];
      final CartItem item2 = cart2[i];

      if (item1.productId != item2.productId ||
          item1.name != item2.name ||
          item1.barcode != item2.barcode ||
          item1.quantity != item2.quantity ||
          item1.discount != item2.discount ||
          item1.retailPrice != item2.retailPrice ||
          item1.wholesalePrice != item2.wholesalePrice) {
        return false;
      }
    }
    return true;
  }

  /// حفظ السلة في Firebase
  Future<void> _saveCartToFirebase() async {
    if (_currentSessionId == null || !mounted) return;

    try {
      final CartState cartState = ref.read(cartStateProvider);
      final List<CartItem> currentCart = cartState.cart;

      await POSService.saveCartToFirebase(
        cart: currentCart,
        sessionId: _currentSessionId!,
        platform: 'POS Tab',
        deviceInfo: 'POS Tab Riverpod',
      );

      debugPrint('✅ تم حفظ السلة في Firebase: ${currentCart.length} عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة في Firebase: $e');
    }
  }

  /// مسح الباركود
  Future<void> _scanBarcode() async {
    final success = await ErrorHelper.safeExecute(
      () async {
        final String? barcode = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
            builder: (BuildContext context) => const BarcodeScannerView(),
          ),
        );

        if (barcode != null && barcode.isNotEmpty) {
          _barcodeController.text = barcode;
          await _addProductToCart(barcode);
        }
      },
      userAction: 'مسح الباركود في شاشة POS',
    );

    if (success == null) {
      SnackbarUtils.showError(context, 'خطأ في مسح الباركود');
    }
  }

  /// إضافة منتج إلى السلة بالاسم
  Future<void> _addProductToCartByName(String name) async {
    try {
      debugPrint('🔄 بدء إضافة منتج للسلة بالاسم: $name');

      // البحث عن المنتج في المخزون
      final Product? product = await POSService.findProductByName(
        ref,
        name,
      );

      if (product == null) {
        SnackbarUtils.showError(
            context, 'لم يتم العثور على منتج بالاسم: $name');
        return;
      }

      debugPrint('✅ تم العثور على المنتج: ${product.name}');

      // التحقق من توفر الكمية
      final int availableQuantity = await POSService.getAvailableQuantityByName(
        ref,
        name,
      );

      debugPrint('📊 الكمية المتوفرة: $availableQuantity');

      if (availableQuantity <= 0) {
        SnackbarUtils.showError(context, 'المنتج نفذ من المخزون');
        return;
      }

      // البحث عن المنتج في السلة الحالية (بالاسم أو الباركود)
      final CartState cartState = ref.read(cartStateProvider);
      final CartItem? existingItem = cartState.cart
          .where((CartItem item) =>
              item.productId == product.id ||
              item.name.toLowerCase() == product.name.toLowerCase() ||
              (item.barcode.isNotEmpty &&
                  product.barcode != null &&
                  product.barcode!.isNotEmpty &&
                  item.barcode == product.barcode))
          .firstOrNull;

      if (existingItem != null) {
        // تحديث الكمية إذا كان المنتج موجود بالفعل
        final int newQuantity = existingItem.quantity + 1;

        // التحقق من توفر الكمية الجديدة
        if (newQuantity > availableQuantity) {
          SnackbarUtils.showError(context,
              'الكمية المطلوبة ($newQuantity) غير متوفرة. المتوفر: $availableQuantity');
          return;
        }

        // خصم كمية واحدة من المخزون
        await POSService.decreaseInventoryQuantityByName(
          ref,
          name,
          1,
        );

        debugPrint('🔄 تم خصم الكمية من المخزون');

        // تحديث الكمية في السلة بناءً على الاسم
        ref
            .read(cartStateProvider.notifier)
            .updateQuantityForItemByName(product.name, newQuantity);
      } else {
        // إضافة منتج جديد للسلة
        final CartItem newItem = CartItem(
          productId: product.id ?? 'unknown',
          name: product.name,
          barcode: product.barcode ?? product.id ?? 'unknown',
          wholesalePrice: product.wholesalePrice,
          retailPrice: product.retailPrice,
          quantity: 1,
        );

        // خصم كمية واحدة من المخزون
        await POSService.decreaseInventoryQuantityByName(
          ref,
          name,
          1,
        );

        debugPrint('🔄 تم خصم الكمية من المخزون');

        // إضافة العنصر إلى السلة
        ref.read(cartStateProvider.notifier).addItem(newItem);
      }

      // حفظ السلة في Firebase
      await _saveCartToFirebase();

      // تحديث الواجهة فوراً
      if (mounted) {
        setState(() {});
        debugPrint('🔄 تم استدعاء setState لتحديث الواجهة');
      }

      // تشغيل الـ animation عند إضافة منتج جديد
      _fadeController.reset();
      _fadeController.forward();

      SnackbarUtils.showSuccess(context, 'تم إضافة ${product.name} إلى السلة');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج للسلة بالاسم: $e');
      SnackbarUtils.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// إضافة منتج إلى السلة
  Future<void> _addProductToCart(String barcode) async {
    try {
      final CartItem? cartItem =
          await POSService.addProductToCartWithValidation(
        ref: ref,
        barcode: barcode,
        currentCart: ref.read(cartStateProvider).cart,
      );

      if (cartItem != null) {
        // تحديث المخزون فوراً عند الإضافة - نخصم 1 فقط (الكمية المضافة)
        await POSService.decreaseInventoryQuantity(
          ref,
          barcode,
          1, // نخصم 1 فقط عند الإضافة
        );

        // إضافة العنصر إلى السلة
        ref.read(cartStateProvider.notifier).addItem(cartItem);

        // حفظ السلة في Firebase
        await _saveCartToFirebase();

        // تحديث الواجهة فوراً
        if (mounted) {
          setState(() {});
        }

        // تشغيل الـ animation عند إضافة منتج جديد
        _fadeController.reset();
        _fadeController.forward();

        SnackbarUtils.showSuccess(
            context, 'تم إضافة ${cartItem.name} إلى السلة');
      }
    } catch (e) {
      SnackbarUtils.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// زيادة كمية منتج في السلة
  Future<void> _increaseQuantity(CartItem item) async {
    try {
      // التحقق من توفر الكمية في المخزون
      final int availableQuantity = await POSService.getAvailableQuantity(
        ref,
        item.barcode,
      );

      if (availableQuantity <= 0) {
        SnackbarUtils.showError(context, 'المنتج نفذ من المخزون');
        return;
      }

      // خصم كمية من المخزون
      await POSService.decreaseInventoryQuantity(
        ref,
        item.barcode,
        1,
      );

      // زيادة الكمية في السلة - استخدام الطريقة الجديدة
      ref
          .read(cartStateProvider.notifier)
          .updateQuantityForItem(item, item.quantity + 1);

      // حفظ السلة في Firebase
      await _saveCartToFirebase();

      // تحديث الواجهة
      if (mounted) {
        setState(() {});
      }

      SnackbarUtils.showSuccess(context, 'تم زيادة كمية ${item.name}');
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في زيادة الكمية: $e');
    }
  }

  /// تقليل كمية منتج في السلة
  Future<void> _decreaseQuantity(CartItem item) async {
    try {
      if (item.quantity > 1) {
        // إرجاع كمية واحدة إلى المخزون
        await POSService.increaseInventoryQuantity(
          ref,
          item.barcode,
          1,
        );

        // تقليل الكمية في السلة - استخدام الطريقة الجديدة
        ref
            .read(cartStateProvider.notifier)
            .updateQuantityForItem(item, item.quantity - 1);

        // حفظ السلة في Firebase
        await _saveCartToFirebase();

        // تحديث الواجهة
        if (mounted) {
          setState(() {});
        }

        SnackbarUtils.showSuccess(context, 'تم تقليل كمية ${item.name}');
      } else {
        // إذا كانت الكمية = 1، اعرض تأكيد الحذف
        _confirmRemoveItem(item);
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في تقليل الكمية: $e');
    }
  }

  /// حذف منتج من السلة
  Future<void> _removeItem(CartItem item) async {
    await ErrorHelper.safeExecute(
      () async {
        // إرجاع الكمية إلى المخزون فوراً
        await POSService.increaseInventoryQuantity(
          ref,
          item.barcode,
          item.quantity,
        );
      },
      userAction: 'حذف منتج من السلة وإرجاع الكمية للمخزون',
    );

    // حذف العنصر من السلة - استخدام الطريقة الجديدة
    ref.read(cartStateProvider.notifier).removeItemByObject(item);

    // حفظ السلة في Firebase
    await _saveCartToFirebase();

    setState(() {});
    SnackbarUtils.showInfo(
        context, 'تم حذف ${item.name} من السلة وإرجاع الكمية للمخزون');
  }

  /// تأكيد حذف منتج من السلة
  Future<void> _confirmRemoveItem(CartItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteConfirmationDialog(
        title: 'حذف المنتج',
        message:
            'هل تريد حذف ${item.name} من السلة؟ سيتم إرجاع الكمية إلى المخزون.',
        onConfirm: () {}, // dummy callback - لن يُستخدم
      ),
    );

    if (confirmed == true) {
      await _removeItem(item);
    }
  }

  /// مسح السلة
  Future<void> _clearCart() async {
    ref.read(cartStateProvider.notifier).clearCart();

    // حفظ السلة الفارغة في Firebase
    await _saveCartToFirebase();

    setState(() {});
    SnackbarUtils.showInfo(context, 'تم مسح السلة');
  }

  /// تطبيق الخصم على منتج
  Future<void> _applyDiscount(CartItem item, String value) async {
    final int? discount = int.tryParse(value);
    if (discount != null && discount >= 0) {
      ref.read(cartStateProvider.notifier).applyDiscountToItem(item, discount);

      // حفظ السلة في Firebase
      await _saveCartToFirebase();

      if (mounted) {
        setState(() {});
      }
      SnackbarUtils.showSuccess(context, 'تم تطبيق الخصم');
    } else {
      SnackbarUtils.showError(context, 'قيمة الخصم غير صحيحة');
    }
  }

  /// إلغاء الخصم على منتج
  Future<void> _cancelDiscount(CartItem item) async {
    ref.read(cartStateProvider.notifier).removeDiscountFromItem(item);

    // حفظ السلة في Firebase
    await _saveCartToFirebase();

    if (mounted) {
      setState(() {});
    }
    // مسح حقل النص
    final String uniqueKey =
        '${item.productId}_${item.discount}_${item.quantity}';
    if (_discountControllers.containsKey(uniqueKey)) {
      _discountControllers[uniqueKey]!.text = '0';
    }
    SnackbarUtils.showSuccess(context, 'تم إلغاء الخصم');
  }

  /// الحصول على أو إنشاء controller للخصم
  TextEditingController _getDiscountController(CartItem item) {
    // استخدام معرف فريد يجمع productId + discount + quantity
    final String uniqueKey =
        '${item.productId}_${item.discount}_${item.quantity}';
    if (!_discountControllers.containsKey(uniqueKey)) {
      _discountControllers[uniqueKey] = TextEditingController();
    }
    return _discountControllers[uniqueKey]!;
  }

  /// تنظيف controllers غير المستخدمة
  void _cleanupUnusedControllers() {
    final CartState cartState = ref.read(cartStateProvider);
    final List<String> currentKeys = cartState.cart
        .map((CartItem item) =>
            '${item.productId}_${item.discount}_${item.quantity}')
        .toList();

    final List<String> keysToRemove = <String>[];
    for (final String key in _discountControllers.keys) {
      if (!currentKeys.contains(key)) {
        keysToRemove.add(key);
      }
    }

    for (final String key in keysToRemove) {
      _discountControllers[key]?.dispose();
      _discountControllers.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مهم جداً للحفاظ على الحالة!

    // تنظيف controllers غير المستخدمة
    _cleanupUnusedControllers();

    // تشغيل الـ animations عند أول بناء للواجهة
    if (!_fadeController.isAnimating && !_slideController.isAnimating) {
      _fadeController.forward();
      _slideController.forward();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'نقطة البيع',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: <Widget>[
          // مؤشر التحديثات الفورية
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final bool isConnected = ref.watch(isConnectedProvider);
              final String? error = ref.watch(updateErrorProvider);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  error != null
                      ? Icons.error_outline
                      : isConnected
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                  color: error != null
                      ? Colors.red[300]
                      : isConnected
                          ? Colors.green[300]
                          : Colors.orange[300],
                  size: 20,
                ),
              );
            },
          ),
          // زر فلترة المنتجات المخصومة
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final bool cartIsNotEmpty = ref.watch(cartIsNotEmptyProvider);
              if (!cartIsNotEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _showDiscountedOnly = !_showDiscountedOnly;
                    });
                  }
                },
                icon: Icon(
                  _showDiscountedOnly
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                ),
                tooltip: _showDiscountedOnly
                    ? 'عرض جميع المنتجات'
                    : 'عرض المخصومة فقط',
              );
            },
          ),
          Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? child) {
              final bool cartIsNotEmpty = ref.watch(cartIsNotEmptyProvider);
              if (!cartIsNotEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: _clearCart,
                icon: const Icon(Icons.clear_all),
                tooltip: 'مسح السلة',
              );
            },
          ),
          // زر إنهاء اليوم
          Container(
            margin: const EdgeInsets.only(left: 8),
            child: ElevatedButton.icon(
              onPressed: _isProcessingEOD ? null : _showEndOfDayConfirmation,
              icon: _isProcessingEOD
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.event_available, color: Colors.white),
              label: Text(
                _isProcessingEOD ? 'جاري المعالجة...' : 'إنهاء اليوم',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    // شريط مسح الباركود
                    _buildBarcodeInput(),

                    // إحصائيات السلة
                    _buildCartStats(),

                    // قائمة المنتجات في السلة
                    _buildCartList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء قسم إدخال الباركود والبحث
  Widget _buildBarcodeInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Column(
          children: <Widget>[
            // شريط البحث عن المنتجات
            POSProductSearchWidget(
              onProductSelected: (Product product) {
                _addProductToCartByName(product.name);
              },
            ),

            const SizedBox(height: 12),

            // شريط إدخال الباركود
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'باركود المنتج',
                      hintText: 'أدخل الباركود أو امسحه',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code_scanner),
                    ),
                    onSubmitted: (String value) {
                      if (value.isNotEmpty) {
                        _addProductToCart(value);
                        _barcodeController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'مسح الباركود',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// بناء إحصائيات السلة
  Widget _buildCartStats() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final CartState cartState = ref.watch(cartStateProvider);
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_cart,
                    label: 'المنتجات',
                    value: '${cartState.itemCount}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.inventory,
                    label: 'الكمية',
                    value: '${cartState.totalQuantity}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.attach_money,
                    label: 'المجموع',
                    value: formatCurrency(cartState.totalAmount),
                  ),
                ),
              ],
            ),
          );
        },
      );

  /// بناء عنصر إحصائية
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  /// بناء السلة الفارغة
  Widget _buildEmptyCart() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'السلة فارغة',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'امسح الباركود أو أدخل الباركود لإضافة منتجات',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// بناء قائمة منتجات السلة
  Widget _buildCartList() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final CartState cartState = ref.watch(cartStateProvider);

          // Debug logging لتتبع UI rebuilds
          debugPrint('🔄 Cart UI rebuilding: ${cartState.cart.length} items');
          debugPrint('   - isEmpty: ${cartState.isEmpty}');
          debugPrint('   - Total amount: ${cartState.totalAmount}');

          if (cartState.isEmpty) {
            debugPrint('📭 عرض السلة الفارغة');
            return _buildEmptyCart();
          }

          debugPrint('📦 عرض ${cartState.cart.length} عنصر في السلة');

          // فلترة المنتجات حسب الخصم
          final List<CartItem> filteredCart = _showDiscountedOnly
              ? cartState.cart
                  .where((CartItem item) => item.discount > 0)
                  .toList()
              : cartState.cart;

          if (filteredCart.isEmpty && _showDiscountedOnly) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.discount_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منتجات مخصومة',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCart.length,
            itemBuilder: (BuildContext context, int index) {
              final CartItem item = filteredCart[index];
              return _buildCartItemCard(item);
            },
          );
        },
      );

  /// بناء بطاقة منتج في السلة
  Widget _buildCartItemCard(CartItem item) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (BuildContext context, double value, Widget? child) =>
            Transform.scale(
          scale: 0.9 + (0.1 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing16,
              vertical: AppConstants.spacing8,
            ),
            elevation: item.discount > 0
                ? AppConstants.elevation3
                : AppConstants.elevation1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              side: BorderSide(
                color: item.discount > 0
                    ? AppConstants.warningColor
                    : Colors.grey[300]!,
                width: item.discount > 0 ? 2 : 0.5,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                gradient: item.discount > 0
                    ? LinearGradient(
                        colors: <Color>[
                          AppConstants.warningColor.withValues(alpha: 0.05),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // معلومات المنتج مع علامة الخصم
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.discount > 0) ...<Widget>[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'خصم',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'باركود: ${item.barcode}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(
                                'السعر: ${formatCurrency(item.retailPrice)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (item.discount > 0)
                                Text(
                                  'بعد الخصم: ${formatCurrency(item.discountedPrice)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // عرض الكمية مع أزرار التحكم
                    Row(
                      children: <Widget>[
                        // أزرار التحكم في الكمية
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              // زر تقليل الكمية
                              IconButton(
                                onPressed: () => _decreaseQuantity(item),
                                icon: const Icon(Icons.remove, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.orange[50],
                                  foregroundColor: Colors.orange[700],
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(32, 32),
                                ),
                                tooltip: 'تقليل الكمية',
                              ),
                              // عرض الكمية
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(Icons.shopping_bag,
                                        size: 16, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // زر زيادة الكمية
                              IconButton(
                                onPressed: () => _increaseQuantity(item),
                                icon: const Icon(Icons.add, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.green[50],
                                  foregroundColor: Colors.green[700],
                                  padding: const EdgeInsets.all(8),
                                  minimumSize: const Size(32, 32),
                                ),
                                tooltip: 'زيادة الكمية',
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // زر الحذف (يظهر فقط عندما تكون الكمية = 1)
                        if (item.quantity == 1)
                          IconButton(
                            onPressed: () => _confirmRemoveItem(item),
                            icon: const Icon(Icons.delete),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red,
                            ),
                            tooltip: 'حذف المنتج',
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // حقل الخصم الفردي مع أزرار التحكم
                    Row(
                      children: <Widget>[
                        const Icon(Icons.discount,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'الخصم:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _getDiscountController(item)
                              ..text = item.discount.toString(),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // زر تطبيق الخصم
                        IconButton(
                          onPressed: () => _applyDiscount(
                              item, _getDiscountController(item).text),
                          icon: const Icon(Icons.check, color: Colors.green),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green[50],
                            padding: const EdgeInsets.all(8),
                          ),
                          tooltip: 'تطبيق الخصم',
                        ),
                        const SizedBox(width: 4),
                        // زر إلغاء الخصم
                        IconButton(
                          onPressed: () => _cancelDiscount(item),
                          icon: const Icon(Icons.clear, color: Colors.red),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            padding: const EdgeInsets.all(8),
                          ),
                          tooltip: 'إلغاء الخصم',
                        ),
                        const SizedBox(width: 8),
                        const Text('دينار',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // الإجمالي
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'الإجمالي:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCurrency(item.totalPrice),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  /// Pull-to-refresh مع animation
  Future<void> _onRefresh() async {
    try {
      // إعادة تشغيل الـ animations
      _fadeController.reset();
      _slideController.reset();

      debugPrint('🔄 Refreshing data...');

      // إعادة تشغيل الـ animations
      _fadeController.forward();
      _slideController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث بيانات نقطة البيع بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
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
          ),
        );
      }
    }
  }

  // ========== End of Day Functions ==========

  /// عرض شاشة تأكيد إنهاء اليوم
  Future<void> _showEndOfDayConfirmation() async {
    final CartState cartState = ref.read(cartStateProvider);
    final bool hasUnsavedItems = cartState.cart.isNotEmpty;

    // جمع إحصائيات سريعة لليوم
    final Map<String, dynamic> todayStats = await _getTodayQuickStats();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Row(
          children: <Widget>[
            Icon(Icons.warning_amber, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('إنهاء اليوم'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'أنت على وشك إنهاء يوم العمل وإغلاق دفتر المبيعات.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // تحذيرات
              if (hasUnsavedItems)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تحذير: لديك ${cartState.cart.length} منتج في السلة لم يتم حفظه!',
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // معاينة سريعة لليوم
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: <Widget>[
                    _buildQuickStat(
                        'إجمالي المبيعات اليوم',
                        '${todayStats['totalSales'] as int} DZ',
                        Icons.attach_money),
                    const Divider(height: 16),
                    _buildQuickStat(
                        'عدد المنتجات المباعة',
                        '${todayStats['totalItems'] as int}',
                        Icons.shopping_cart),
                    const Divider(height: 16),
                    _buildQuickStat(
                        'آخر عملية بيع',
                        (todayStats['lastSaleTime'] as String?) ?? 'لا توجد',
                        Icons.access_time),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ملاحظة مهمة
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'سيتم إنشاء تقرير نهاية اليوم وإعادة تصفير العدادات',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(fontSize: 16)),
          ),
          if (hasUnsavedItems)
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context, false);
                // حفظ السلة أولاً
                await _quickSave();
                // ثم إعادة فتح الحوار
                _showEndOfDayConfirmation();
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ السلة أولاً'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('إنهاء اليوم', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performEndOfDay();
    }
  }

  /// بناء عنصر إحصائية سريعة
  Widget _buildQuickStat(String label, String value, IconData icon) => Row(
        children: <Widget>[
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      );

  /// جلب إحصائيات سريعة لليوم
  Future<Map<String, dynamic>> _getTodayQuickStats() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      // جلب بيانات المبيعات المحلية
      final List<Sale> todaySales = await POSService.getCombinedSalesPage(
        startDate: startOfDay,
        endDate: endOfDay,
      ).then((PageResult<Sale> page) => page.items);

      final double totalSales = todaySales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalAmount);
      final int totalItems =
          todaySales.fold(0, (int sum, Sale sale) => sum + sale.totalQuantity);

      String lastSaleTime = 'لا توجد';
      if (todaySales.isNotEmpty) {
        final DateTime lastSale = todaySales.first.saleDate;
        lastSaleTime =
            '${lastSale.hour.toString().padLeft(2, '0')}:${lastSale.minute.toString().padLeft(2, '0')}';
      }

      return <String, dynamic>{
        'totalSales': totalSales.toInt(),
        'totalItems': totalItems,
        'lastSaleTime': lastSaleTime,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات السريعة: $e');
      return <String, dynamic>{
        'totalSales': 0,
        'totalItems': 0,
        'lastSaleTime': 'خطأ',
      };
    }
  }

  /// حفظ سريع للسلة
  Future<void> _quickSave() async {
    try {
      await _saveCartToFirebase();
      SnackbarUtils.showSuccess(context, 'تم حفظ السلة بنجاح');
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في حفظ السلة: $e');
    }
  }

  /// تنفيذ عملية إنهاء اليوم
  Future<void> _performEndOfDay() async {
    if (_isProcessingEOD) return;

    setState(() {
      _isProcessingEOD = true;
    });

    // عرض مؤشر التحميل
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('جارٍ إنهاء اليوم...',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(_currentStep,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // الخطوة 1: التحقق من السلة
      setState(() => _currentStep = 'التحقق من السلة...');
      final CartState cartState = ref.read(cartStateProvider);
      if (cartState.cart.isNotEmpty) {
        // حفظ تلقائي للسلة
        await _quickSave();
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // الخطوة 2: استخدام المدير المركزي لإنشاء التقرير
      setState(() => _currentStep = 'إنشاء تقرير نهاية اليوم...');
      final CartState currentCartState = ref.read(cartStateProvider);

      await ref.read(eodProcessNotifierProvider.notifier).generateEODReport(
            employeeId: 'pos_user',
            employeeName: 'موظف نقطة البيع',
            currentCartItems: currentCartState.cart,
          );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // الخطوة 6: إعادة تصفير العدادات
      setState(() => _currentStep = 'إعادة التصفير...');
      await _resetDailyCounters();
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // الخطوة 3: تحديث مزود التقارير لإظهار التقرير الجديد (مهم للتناسق)
      ref.invalidate(realEODReportsProvider);

      // الخطوة 4: الحصول على التقرير وعرضه
      final EODReport? report = ref.read(eodProcessNotifierProvider).value;
      if (report != null) {
        await _showEODReport(report);
      }

      // إعادة تعيين الحالة
      ref.read(eodProcessNotifierProvider.notifier).resetState();
    } catch (e) {
      // إغلاق مؤشر التحميل
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // عرض رسالة خطأ
      if (mounted) {
        SnackbarUtils.showError(context, 'فشل إنهاء اليوم: $e');
      }

      // إعادة تعيين الحالة
      ref.read(eodProcessNotifierProvider.notifier).resetState();
    } finally {
      // التأكد من إعادة تعيين الحالة حتى لو حدث خطأ في العرض
      if (mounted) {
        setState(() {
          _isProcessingEOD = false;
          _currentStep = '';
        });
      }
    }
  }

  /// إعادة تصفير العدادات اليومية
  Future<void> _resetDailyCounters() async {
    try {
      debugPrint('🔄 بدء إعادة تصفير العدادات اليومية...');

      // 1. مسح السلة بالكامل
      ref.read(cartStateProvider.notifier).clearCart();
      debugPrint('✅ تم مسح السلة');

      // 2. مسح السلة من Firebase
      await _clearCartFromFirebase();
      debugPrint('✅ تم مسح السلة من Firebase');

      // 3. إعادة تحميل البيانات
      _onRefresh();
      debugPrint('✅ تم إعادة تحميل البيانات');

      // 4. إعادة تهيئة CartController
      ref.invalidate(cartStateProvider);
      debugPrint('✅ تم إعادة تهيئة CartController');

      // 5. مسح بيانات المبيعات اليومية فقط (بدون مسح جميع البيانات)
      await EODService.clearTodaySalesData();
      debugPrint('✅ تم مسح بيانات المبيعات اليومية');

      debugPrint('🔄 تم إعادة تصفير العدادات اليومية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تصفير العدادات: $e');
    }
  }

  /// عرض تقرير نهاية اليوم
  Future<void> _showEODReport(EODReport report) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Container(
          width: 800,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            children: <Widget>[
              // رأس التقرير
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Colors.deepOrange, Colors.orange.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.assignment_turned_in,
                        color: Colors.white, size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'تقرير نهاية اليوم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(report.date),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'تقرير #${report.reportNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // محتوى التقرير
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // الإحصائيات الرئيسية
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _buildStatCard(
                              'إجمالي المبيعات',
                              '${report.totalSales.toStringAsFixed(0)} دج',
                              Icons.attach_money,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'المنتجات المباعة',
                              '${report.totalItemsSold}',
                              Icons.shopping_cart,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'الربح الإجمالي',
                              '${report.totalProfit.toStringAsFixed(0)} دج',
                              Icons.trending_up,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // معلومات إضافية
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _buildInfoCard(
                              'عدد المنتجات المختلفة',
                              '${report.uniqueProducts}',
                              Icons.inventory_2,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              'متوسط سعر المنتج',
                              report.totalItemsSold > 0
                                  ? '${(report.totalSales / report.totalItemsSold).toStringAsFixed(0)} DZ'
                                  : '0 DZ',
                              Icons.calculate,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // أكثر 10 منتجات مبيعاً
                      const Text(
                        'أكثر المنتجات مبيعاً اليوم',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...report.topProducts
                          .take(10)
                          .toList()
                          .asMap()
                          .entries
                          .map((MapEntry<int, TopProduct> entry) {
                        final int index = entry.key;
                        final TopProduct product = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: index < 3
                                ? Colors.amber.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: index < 3
                                  ? Colors.amber.shade200
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              // الترتيب
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: index < 3
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: index < 3
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // اسم المنتج
                              Expanded(
                                flex: 2,
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),

                              // الكمية
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${product.quantity} وحدة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // القيمة
                              Expanded(
                                child: Text(
                                  '${product.totalValue.toStringAsFixed(0)} DZ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ملخص المخزون
                      const Text(
                        'تنبيهات المخزون',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (report.lowStockProducts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 12),
                              Text('لا توجد منتجات بمخزون منخفض'),
                            ],
                          ),
                        )
                      else
                        ...report.lowStockProducts.map(
                          (LowStockProduct product) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.warning, color: Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  'المخزون: ${product.currentStock}',
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // أزرار التحكم
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    // الصف الأول - أزرار الإجراءات
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printEODReport(report),
                            icon: const Icon(Icons.print),
                            label: const Text('طباعة التقرير'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportEODToExcel(report),
                            icon: const Icon(Icons.file_download),
                            label: const Text('تصدير Excel'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _navigateToReportsTab();
                            },
                            icon: const Icon(Icons.analytics),
                            label: const Text('عرض في التقارير'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // الصف الثاني - أزرار الإلغاء والإتمام
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('إلغاء'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDayEndedSuccess();
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('إتمام',
                                style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
          String label, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );

  /// بناء بطاقة معلومات
  Widget _buildInfoCard(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// تنسيق التاريخ
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  /// طباعة تقرير نهاية اليوم
  Future<void> _printEODReport(EODReport report) async {
    // TODO: تطبيق وظيفة الطباعة
    SnackbarUtils.showInfo(context, 'وظيفة الطباعة قيد التطوير');
  }

  /// تصدير تقرير نهاية اليوم إلى Excel
  Future<void> _exportEODToExcel(EODReport report) async {
    // TODO: تطبيق وظيفة التصدير
    SnackbarUtils.showInfo(context, 'وظيفة التصدير قيد التطوير');
  }

  /// عرض رسالة نجاح نهاية اليوم
  void _showDayEndedSuccess() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text(
              'تم إنهاء اليوم بنجاح!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'التقرير محفوظ ومتزامن مع الخادم',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(100, 50),
            ),
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // إعادة تحميل الشاشة ليوم جديد
                _resetForNewDay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('بدء يوم جديد'),
            ),
          ),
        ],
      ),
    );
  }

  /// إعادة تعيين الشاشة ليوم جديد
  Future<void> _resetForNewDay() async {
    try {
      // مسح السلة محلياً
      ref.read(cartStateProvider.notifier).clearCart();

      // مسح السلة من Firebase أيضاً
      await _clearCartFromFirebase();

      // إعادة تحميل البيانات
      _onRefresh();

      SnackbarUtils.showSuccess(context, 'مرحباً بيوم جديد!');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين اليوم: $e');
      SnackbarUtils.showError(context, 'خطأ في إعادة تعيين اليوم: $e');
    }
  }

  /// مسح السلة من Firebase
  Future<void> _clearCartFromFirebase() async {
    try {
      if (!ConnectivityService.isOnline) {
        debugPrint('📡 غير متصل - لا يمكن مسح السلة من Firebase');
        return;
      }

      final String sessionId = _currentSessionId ?? 'default_session';
      final DocumentReference cartRef =
          FirebaseFirestore.instance.collection('pos_sessions').doc(sessionId);

      await cartRef.update(<Object, Object?>{
        'cart': <Map<String, dynamic>>[],
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': 'cleared',
      });

      debugPrint('🗑️ تم مسح السلة من Firebase');
    } catch (e) {
      debugPrint('❌ خطأ في مسح السلة من Firebase: $e');
      // لا نرمي الخطأ هنا لأن مسح السلة المحلية كافي
    }
  }

  /// الانتقال إلى تبويب التقارير
  void _navigateToReportsTab() {
    try {
      debugPrint('📊 التنقل إلى تبويب التقارير...');

      // إطلاق حدث تحديث التقارير
      AppEventBus.fire(ReportsUpdateEvent(
        'eod',
        sourceTab: 'POS Tab',
        data: <String, dynamic>{
          'action': 'navigate_to_reports',
          'timestamp': DateTime.now().toIso8601String(),
        },
      ));

      // إشعار CrossTabSyncService
      CrossTabSyncService.notifyReportsUpdate(
        'eod',
        sourceTab: 'POS Tab',
        data: <String, dynamic>{
          'action': 'navigate_to_reports',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // إغلاق شاشة تقرير EOD
      Navigator.pop(context);

      // استخدام NavigationService للتنقل
      NavigationService.navigateToTab(
        ref as Ref,
        4, // Reports tab index
        data: <String, dynamic>{
          'refreshReports': true,
          'showEODSuccess': true,
          'sourceTab': 'POS Tab',
          'triggerReportsUpdate': true,
        },
        sourceTab: 'POS Tab',
      );

      // عرض رسالة للمستخدم
      SnackbarUtils.showSuccess(context,
          'تم إنهاء اليوم بنجاح! انتقل إلى تبويب التقارير لعرض التقرير الجديد');

      debugPrint('✅ تم التنقل إلى تبويب التقارير');
    } catch (e) {
      debugPrint('❌ خطأ في التنقل إلى تبويب التقارير: $e');
      // إغلاق شاشة تقرير EOD في حالة الخطأ
      Navigator.pop(context);
    }
  }
}
