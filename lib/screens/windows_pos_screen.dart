import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/page_result.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../models/cart_item.dart';
import '../models/eod_report.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../providers/pos_riverpod_providers.dart';
import '../providers/riverpod/stream_app_riverpod_provider.dart';
// ✅ استخدام النظام المحسن
import '../services/app_event_bus.dart';
import '../services/eod_service.dart';
import '../services/pos_service.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/snackbar_utils.dart';
import '../utils/windows_platform_utils.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/pos_product_search_widget.dart';
import '../widgets/windows_pos_card.dart';

// Simple currency formatter function
String formatCurrency(int amount) => '${amount.toString()} DZ';

/// شاشة نقطة البيع المحسنة لمنصة Windows
class WindowsPOSScreen extends ConsumerStatefulWidget {
  const WindowsPOSScreen({super.key});

  @override
  ConsumerState<WindowsPOSScreen> createState() => _WindowsPOSScreenState();
}

class _WindowsPOSScreenState extends ConsumerState<WindowsPOSScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _discountControllers =
      <String, TextEditingController>{};

  bool _showDiscountedOnly = false;
  bool _hasInitialized = false;

  // إدارة حالة التوسيع للبطاقات
  String? _expandedItemId;

  // ✅ إدارة الأحداث والتزامن
  StreamSubscription<AppEvent>? _eventSubscription;
  StreamSubscription<List<CartItem>>? _cartFirebaseSubscription;
  String? _currentSessionId;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // متغيرات إدارة إنهاء اليوم
  String _currentStep = '';
  bool _isProcessingEOD = false;

  @override
  void initState() {
    super.initState();

    // تهيئة متحكمات الحركة
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

    // لا نبدأ الـ animations في initState لتجنب مشاكل setState أثناء build

    // إعداد اختصارات لوحة المفاتيح
    _setupKeyboardShortcuts();

    // ✅ تهيئة البيانات والاستماع للأحداث
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeData();
        _startEventListening();
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    // ✅ إيقاف الاستماع للأحداث والسلة
    _eventSubscription?.cancel();
    _cartFirebaseSubscription?.cancel();

    // إنهاء جلسة POS
    if (_currentSessionId != null) {
      POSService.endPOSSession(sessionId: _currentSessionId!);
    }

    // تنظيف discount controllers
    for (final TextEditingController controller
        in _discountControllers.values) {
      controller.dispose();
    }
    _discountControllers.clear();
    super.dispose();
  }

  /// إدارة حالة التوسيع للبطاقات (أكورديون)
  void _handleCardExpansion(String itemId, bool isExpanded) {
    if (mounted) {
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
  }

  /// ✅ تهيئة البيانات عند فتح الشاشة
  Future<void> _initializeData() async {
    if (!mounted || _hasInitialized) return;

    try {
      final AppController appController =
          ref.read(appControllerProvider.notifier);

      // ✅ تبسيط منطق التهيئة - إزالة الحجب الكامل للمحتوى
      final AppState appState = ref.read(appControllerProvider);
      if (!appState.isInitialized) {
        debugPrint('🪟 Windows POS: انتظار تهيئة التطبيق...');
        try {
          await appController
              .waitForInitialization()
              .timeout(WindowsPlatformUtils.windowsTimeout);
        } on TimeoutException {
          WindowsPlatformUtils.handleWindowsError(
              'Windows POS AppController initialization', 'timeout');
          // المتابعة حتى لو انتهت المهلة - لا نحجب الواجهة
        }
      }

      // تحسين خاص بـ Windows - إعادة تحميل البيانات
      if (Platform.isWindows) {
        debugPrint('🪟 Windows POS: إعادة تحميل البيانات...');
        await appController.refreshAll();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      // ✅ التأكد من تهيئة CartProvider
      debugPrint('🪟 Windows POS: تهيئة CartProvider...');
      // CartNotifier initializes automatically in build()

      // ✅ إنشاء جلسة POS مشتركة لجميع المنصات
      _currentSessionId =
          'shared_pos_session_${DateTime.now().toIso8601String().split('T')[0]}';
      await POSService.savePOSSession(
        sessionId: _currentSessionId!,
        platform: 'Windows',
        deviceInfo: 'Windows POS Screen',
      );

      // ✅ فحص السلات الموجودة في Firebase
      await _checkExistingCartsInFirebase();

      // ✅ استعادة السلة من Firebase
      await _loadCartFromFirebase();

      // ✅ تأخير بدء الاستماع لتجنب التضارب
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      _startCartFirebaseListening();

      // ✅ التأكد من حفظ السلة الحالية في SharedPreferences
      debugPrint('🪟 Windows POS: التأكد من حفظ السلة الحالية...');
      if (mounted) {
        try {
          final CartState cartState = ref.read(cartStateProvider);
          final List<CartItem> currentCart = cartState.cart;
          if (currentCart.isNotEmpty) {
            debugPrint(
                '🪟 Windows POS: تم العثور على ${currentCart.length} عنصر في السلة المحلية');
            // إعادة حفظ السلة للتأكد
            // CartNotifier saves automatically when items are modified
          }
        } catch (e) {
          debugPrint('❌ خطأ في جلب بيانات السلة: $e');
        }
      }

      if (appState.isInitialized) {
        debugPrint('🔄 تم جلب بيانات POS في Windows POS Screen');
      }

      _hasInitialized = true;
    } catch (e) {
      WindowsPlatformUtils.handleWindowsError('Windows POS data loading', e);
    }
  }

  /// ✅ بدء الاستماع للأحداث
  void _startEventListening() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      if (!mounted) return;

      switch (event.runtimeType) {
        case ProductAddedEvent:
          _handleProductAdded(event as ProductAddedEvent);
          break;
        case ProductUpdatedEvent:
          _handleProductUpdated(event as ProductUpdatedEvent);
          break;
        case ProductDeletedEvent:
          _handleProductDeleted(event as ProductDeletedEvent);
          break;
        case InventoryUpdatedEvent:
          _handleInventoryUpdated(event as InventoryUpdatedEvent);
          break;
        case SaleCompletedEvent:
          _handleSaleCompleted(event as SaleCompletedEvent);
          break;
        case LowStockAlertEvent:
          _handleLowStockAlert(event as LowStockAlertEvent);
          break;
        case StatsUpdatedEvent:
          _handleStatsUpdated(event as StatsUpdatedEvent);
          break;
        default:
          debugPrint('📨 حدث غير معالج في Windows POS: ${event.runtimeType}');
      }
    });
  }

  /// ✅ معالجة إضافة منتج جديد
  void _handleProductAdded(ProductAddedEvent event) {
    debugPrint('📦 معالجة إضافة منتج في Windows POS: ${event.product.name}');

    // تحديث الواجهة
    if (mounted) {
      if (mounted) {
        setState(() {});
      }
    }

    // إظهار إشعار
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تمت إضافة "${event.product.name}"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ معالجة تحديث منتج
  void _handleProductUpdated(ProductUpdatedEvent event) {
    debugPrint('✏️ معالجة تحديث منتج في Windows POS: ${event.product.name}');

    // تحديث الواجهة
    if (mounted) {
      if (mounted) {
        setState(() {});
      }
    }

    // إظهار إشعار
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✏️ تم تحديث "${event.product.name}"'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ معالجة حذف منتج
  void _handleProductDeleted(ProductDeletedEvent event) {
    debugPrint('🗑️ معالجة حذف منتج في Windows POS: ${event.productName}');

    // تحديث الواجهة
    if (mounted) {
      if (mounted) {
        setState(() {});
      }
    }

    // إظهار إشعار
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ تم حذف "${event.productName}"'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ معالجة تحديث المخزون
  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    debugPrint('📦 معالجة تحديث المخزون في Windows POS: ${event.itemName}');

    // تحديث الواجهة
    if (mounted) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// ✅ معالجة إتمام عملية بيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    debugPrint('💰 معالجة إتمام عملية بيع في Windows POS: ${event.sale.id}');

    // تحديث الواجهة
    if (mounted) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// ✅ معالجة تنبيه المخزون المنخفض
  void _handleLowStockAlert(LowStockAlertEvent event) {
    debugPrint('⚠️ معالجة تنبيه مخزون منخفض في Windows POS: ${event.itemName}');

    // إظهار تنبيه
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ مخزون منخفض: ${event.itemName}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// ✅ معالجة تحديث الإحصائيات
  void _handleStatsUpdated(StatsUpdatedEvent event) {
    debugPrint('📊 معالجة تحديث الإحصائيات في Windows POS');

    // تحديث الواجهة
    if (mounted) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// ✅ Pull-to-refresh لإعادة تحميل البيانات
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 بدء تحديث بيانات POS...');

      // التأكد من أن التطبيق مهيأ
      final AppController appController =
          ref.read(appControllerProvider.notifier);
      final AppState appState = ref.read(appControllerProvider);
      if (!appState.isInitialized) {
        debugPrint('⚠️ التطبيق لم يتم تهيئته بعد');
        return;
      }

      await appController.refreshAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث بيانات POS بنجاح'),
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
        debugPrint('✅ تم تحديث بيانات POS بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث بيانات POS: $e');
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

  /// ✅ فحص السلات الموجودة في Firebase
  Future<void> _checkExistingCartsInFirebase() async {
    try {
      debugPrint('🔍 فحص السلات الموجودة في Firebase...');

      // البحث عن جميع السلات في Firebase
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('pos_carts').get();

      debugPrint('🔍 تم العثور على ${snapshot.docs.length} سلة في Firebase');

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();
        final String sessionId = doc.id;
        final List<dynamic> items =
            data['items'] as List<dynamic>? ?? <dynamic>[];
        final String platform = data['platform'] as String? ?? 'Unknown';
        final String lastUpdated = data['lastUpdated']?.toString() ?? 'Unknown';

        debugPrint(
            '🔍 جلسة: $sessionId | منصة: $platform | عناصر: ${items.length} | آخر تحديث: $lastUpdated');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص السلات الموجودة: $e');
    }
  }

  /// ✅ استعادة السلة من Firebase
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

        // ✅ تحسين: فقط إذا كانت السلة المحلية فارغة وكان Firebase يحتوي على عناصر
        if (currentCart.isEmpty && firebaseCart.isNotEmpty) {
          // إضافة العناصر من Firebase فقط إذا كانت السلة المحلية فارغة
          for (final CartItem item in firebaseCart) {
            cartNotifier.addItem(item);
          }

          if (mounted) {
            setState(() {});
          }

          debugPrint('✅ تم استعادة ${firebaseCart.length} عنصر من Firebase');
        } else if (currentCart.isNotEmpty &&
            !_areCartsEqual(firebaseCart, currentCart)) {
          // إذا كانت السلة المحلية تحتوي على عناصر مختلفة عن Firebase
          debugPrint('🔄 السلة المحلية مختلفة عن Firebase - تجاهل التحديث');
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

  /// ✅ بدء الاستماع لتغييرات السلة في Firebase
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

        // ✅ تحسين: تجاهل التحديثات الفارغة أو المتطابقة
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

          // ✅ تحسين: فقط إذا كان Firebase يحتوي على عناصر والسلة المحلية فارغة
          if (firebaseCart.isNotEmpty && currentCart.isEmpty) {
            // إضافة العناصر من Firebase فقط إذا كانت السلة المحلية فارغة
            for (final CartItem item in firebaseCart) {
              cartNotifier.addItem(item);
            }

            if (mounted) {
              setState(() {});
            }
          } else if (firebaseCart.isEmpty && currentCart.isNotEmpty) {
            // إذا كان Firebase فارغ والسلة المحلية تحتوي على عناصر، مسح السلة المحلية
            cartNotifier.clearCart();
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

  /// ✅ مقارنة السلات
  bool _areCartsEqual(List<CartItem> cart1, List<CartItem> cart2) {
    if (cart1.length != cart2.length) return false;

    for (int i = 0; i < cart1.length; i++) {
      final CartItem item1 = cart1[i];
      final CartItem item2 = cart2[i];

      if (item1.productId != item2.productId ||
          item1.quantity != item2.quantity ||
          item1.discount != item2.discount) {
        return false;
      }
    }

    return true;
  }

  /// ✅ حفظ السلة في Firebase
  Future<void> _saveCartToFirebase() async {
    if (_currentSessionId == null) return;

    try {
      final CartState cartState = ref.read(cartStateProvider);
      final List<CartItem> cart = cartState.cart;

      // ✅ حفظ السلة مع معلومات إضافية
      await POSService.saveCartToFirebase(
        cart: cart,
        sessionId: _currentSessionId!,
        userId: 'shared_user', // معرف مشترك لجميع المنصات
        platform: 'Windows',
        deviceInfo: 'Windows POS Screen',
      );

      debugPrint('✅ تم حفظ السلة في Firebase: ${cart.length} عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة في Firebase: $e');
    }
  }

  /// إعداد اختصارات لوحة المفاتيح
  void _setupKeyboardShortcuts() {
    RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _clearCart();
          } else if (event.logicalKey == LogicalKeyboardKey.f1) {
            _scanBarcode();
          }
        }
      },
      child: const SizedBox.shrink(),
    );
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
        await _addProductToCart(barcode);
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في مسح الباركود: $e');
    }
  }

  /// إضافة منتج إلى السلة بالاسم
  Future<void> _addProductToCartByName(String name) async {
    try {
      debugPrint('🪟 Windows: بدء إضافة منتج للسلة بالاسم: $name');

      debugPrint('🪟 Windows: تم الحصول على Controllers');

      // البحث عن المنتج في المخزون
      final Product? product = await POSService.findProductByName(
        ref,
        name,
      );

      if (product == null) {
        debugPrint('🪟 Windows: لم يتم العثور على منتج بالاسم: $name');
        SnackbarUtils.showError(
            context, 'لم يتم العثور على منتج بالاسم: $name');
        return;
      }

      debugPrint('🪟 Windows: تم العثور على المنتج: ${product.name}');

      // التحقق من توفر الكمية
      final int availableQuantity = await POSService.getAvailableQuantityByName(
        ref,
        name,
      );

      debugPrint('🪟 Windows: الكمية المتوفرة: $availableQuantity');

      if (availableQuantity <= 0) {
        debugPrint('🪟 Windows: المنتج نفذ من المخزون');
        SnackbarUtils.showError(context, 'المنتج نفذ من المخزون');
        return;
      }

      debugPrint('🪟 Windows: إضافة منتج للسلة باستخدام CartProvider.addItem');

      // إنشاء عنصر السلة
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

      debugPrint('🪟 Windows: تم خصم الكمية من المخزون');

      // إضافة العنصر إلى CartProvider (سيتعامل مع المنتجات المكررة تلقائياً)
      final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
      cartNotifier.addItem(newItem);

      debugPrint('🪟 Windows: تم إضافة المنتج للسلة');

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // تحديث الواجهة فوراً
      if (mounted) {
        if (mounted) {
          setState(() {});
        }
        debugPrint('🪟 Windows: تم استدعاء setState');
      } else {
        debugPrint('🪟 Windows: تحذير - Widget غير mounted');
      }

      // تأثير بصري عند الإضافة
      _fadeController.reset();
      _fadeController.forward();

      debugPrint('🪟 Windows: بدء عرض رسالة النجاح');
      SnackbarUtils.showSuccess(context, 'تم إضافة ${product.name} إلى السلة');
      debugPrint('🪟 Windows: تم عرض رسالة النجاح');
    } on Exception catch (e) {
      debugPrint('🪟 Windows: Exception في _addProductToCartByName: $e');
      SnackbarUtils.showError(context, e.toString());
    } catch (e) {
      debugPrint('🪟 Windows: خطأ غير متوقع في _addProductToCartByName: $e');
      SnackbarUtils.showError(context, 'خطأ غير متوقع: $e');
    }
  }

  /// إضافة منتج إلى السلة
  Future<void> _addProductToCart(String barcode) async {
    try {
      debugPrint('🪟 Windows: بدء إضافة منتج للسلة: $barcode');

      debugPrint('🪟 Windows: تم الحصول على Controllers');

      final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
      final CartState cartState = ref.read(cartStateProvider);
      final List<CartItem> currentCart = cartState.cart;
      final CartItem? cartItem =
          await POSService.addProductToCartWithValidation(
        ref: ref,
        barcode: barcode,
        currentCart: List<CartItem>.from(currentCart),
      );

      debugPrint(
          '🪟 Windows: CartItem من addProductToCartWithValidation: ${cartItem?.name ?? "NULL"}');
      debugPrint(
          '🪟 Windows: CartItem quantity: ${cartItem?.quantity ?? "NULL"}');
      debugPrint(
          '🪟 Windows: CartItem productId: ${cartItem?.productId ?? "NULL"}');

      if (cartItem != null) {
        debugPrint('🪟 Windows: CartItem صالح، بدء تحديث المخزون');

        // تحديث المخزون فوراً عند الإضافة - نخصم 1 فقط (الكمية المضافة)
        await POSService.decreaseInventoryQuantity(
          ref,
          barcode,
          1, // ✓ دائماً نخصم 1 فقط عند الإضافة
        );

        debugPrint('🪟 Windows: تم تحديث المخزون، بدء إضافة للسلة');
        final CartState cartState = ref.read(cartStateProvider);
        final int currentCartLength = cartState.itemCount;
        debugPrint('🪟 Windows: حجم السلة قبل الإضافة: $currentCartLength');

        // إضافة العنصر إلى CartProvider
        cartNotifier.addItem(cartItem);

        debugPrint('🪟 Windows: تم إضافة العنصر إلى CartProvider');
        final CartState newCartState = ref.read(cartStateProvider);
        final int newCartLength = newCartState.itemCount;
        debugPrint('🪟 Windows: حجم السلة بعد الإضافة: $newCartLength');

        // ✅ حفظ السلة في Firebase
        await _saveCartToFirebase();

        // تحديث الواجهة فوراً (مثل Android)
        if (mounted) {
          if (mounted) {
            setState(() {});
          }
          debugPrint('🪟 Windows: تم استدعاء setState');
        } else {
          debugPrint('🪟 Windows: تحذير - Widget غير mounted');
        }

        // تأثير بصري عند الإضافة
        _fadeController.reset();
        _fadeController.forward();

        debugPrint('🪟 Windows: بدء عرض رسالة النجاح');
        SnackbarUtils.showSuccess(
            context, 'تم إضافة ${cartItem.name} إلى السلة');
        debugPrint('🪟 Windows: تم عرض رسالة النجاح');
      } else {
        debugPrint('🪟 Windows: خطأ - CartItem يساوي null');
        SnackbarUtils.showError(context, 'فشل في إنشاء عنصر السلة');
      }
    } on Exception catch (e) {
      debugPrint('🪟 Windows: Exception في _addProductToCart: $e');
      // ✅ عرض رسالة الخطأ الأصلية الواضحة
      SnackbarUtils.showError(context, e.toString());
    } catch (e) {
      debugPrint('🪟 Windows: خطأ غير متوقع في _addProductToCart: $e');
      // ✅ معالجة الأخطاء الأخرى
      SnackbarUtils.showError(context, 'خطأ غير متوقع: $e');
    }
  }

  /// تحديث كمية منتج في السلة
  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    try {
      // الحصول على الكمية الحالية في السلة
      final int currentQuantity = item.quantity;
      final int quantityDifference = newQuantity - currentQuantity;

      // إذا لم يتغير شيء، لا نفعل شيئاً
      if (quantityDifference == 0) return;

      // التحقق من توفر الكمية في المخزون (فقط إذا كانت الزيادة)
      if (quantityDifference > 0) {
        final int availableQuantity = await POSService.getAvailableQuantity(
          ref,
          item.barcode,
        );

        if (newQuantity > availableQuantity) {
          SnackbarUtils.showWarning(
            context,
            'الكمية المطلوبة ($newQuantity) غير متوفرة. المتوفر: $availableQuantity',
          );
          return;
        }
      }

      // تحديث المخزون بناءً على الفرق في الكمية
      if (quantityDifference > 0) {
        // زيادة الكمية - نخصم من المخزون
        await POSService.decreaseInventoryQuantity(
          ref,
          item.barcode,
          quantityDifference,
        );
      } else {
        // تقليل الكمية - نضيف للمخزون
        await POSService.increaseInventoryQuantity(
          ref,
          item.barcode,
          -quantityDifference, // نضيف القيمة المطلقة
        );
      }

      // تحديث الكمية في السلة
      final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
      cartNotifier.updateQuantity(item.productId, newQuantity,
          discount: item.discount);

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // إعادة بناء الواجهة فوراً
      if (mounted) {
        setState(() {});
      }

      SnackbarUtils.showSuccess(
        context,
        'تم تحديث كمية ${item.name} إلى $newQuantity',
      );
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في تحديث الكمية: $e');
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
      final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
      cartNotifier.updateQuantity(item.productId, item.quantity + 1,
          discount: item.discount);

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // تحديث الواجهة
      if (mounted) {
        if (mounted) {
          setState(() {});
        }
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
        final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
        cartNotifier.updateQuantity(item.productId, item.quantity - 1,
            discount: item.discount);

        // ✅ حفظ السلة في Firebase
        await _saveCartToFirebase();

        // تحديث الواجهة
        if (mounted) {
          if (mounted) {
            setState(() {});
          }
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
    try {
      // إرجاع الكمية إلى المخزون فوراً
      await POSService.increaseInventoryQuantity(
        ref,
        item.barcode,
        item.quantity,
      );
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في إرجاع الكمية للمخزون: $e');
    }

    final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
    cartNotifier.removeItem(item.productId, discount: item.discount);

    // ✅ حفظ السلة في Firebase
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
    final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
    cartNotifier.clearCart();

    // ✅ حفظ السلة في Firebase
    await _saveCartToFirebase();

    setState(() {});
    SnackbarUtils.showInfo(context, 'تم مسح السلة');
  }

  /// تطبيق الخصم على منتج
  Future<void> _applyDiscount(CartItem item, String value) async {
    debugPrint('🏪 WindowsPOSScreen - تطبيق خصم');
    debugPrint('🏪 المنتج: ${item.name}');
    debugPrint('🏪 معرف المنتج: ${item.productId}');
    debugPrint('🏪 قيمة الخصم المدخلة: $value');

    final int? discount = int.tryParse(value);
    if (discount != null && discount >= 0) {
      debugPrint('🏪 تم تحويل الخصم إلى رقم: $discount');

      final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
      // استخدام applyDiscountToItem بدلاً من updateQuantity
      cartNotifier.applyDiscountToItem(item, discount);

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // إعادة بناء الواجهة فوراً
      if (mounted) {
        setState(() {});
      }

      SnackbarUtils.showSuccess(context, 'تم تطبيق الخصم: $discount دينار');
    } else {
      debugPrint('❌ قيمة الخصم غير صحيحة: $value');
      SnackbarUtils.showError(context, 'قيمة الخصم غير صحيحة');
    }
  }

  /// إلغاء الخصم على منتج
  Future<void> _removeDiscount(CartItem item) async {
    debugPrint('🏪 WindowsPOSScreen - إلغاء خصم');
    debugPrint('🏪 المنتج: ${item.name}');
    debugPrint('🏪 معرف المنتج: ${item.productId}');
    debugPrint('🏪 الخصم الحالي: ${item.discount}');
    debugPrint('🏪 الكمية: ${item.quantity}');

    final CartNotifier cartNotifier = ref.read(cartStateProvider.notifier);
    cartNotifier.removeDiscountFromItem(item);

    // ✅ حفظ السلة في Firebase
    await _saveCartToFirebase();

    // إعادة بناء الواجهة فوراً
    if (mounted) {
      setState(() {});
    }

    SnackbarUtils.showSuccess(context, 'تم إلغاء الخصم');
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

    // التحقق من منصة Windows
    if (!Platform.isWindows) {
      return const Center(
        child: Text('هذه الشاشة مخصصة لمنصة Windows فقط'),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.grey[50],
      appBar: _buildWindowsAppBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildWindowsLayout(),
          ),
        ),
      ),
    );
  }

  /// بناء شريط التطبيق المحسن لـ Windows
  PreferredSizeWidget _buildWindowsAppBar() => AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'نقطة البيع - Windows',
              style: TextStyle(
                fontSize: context.responsiveFontSize(20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // إحصائيات سريعة
            _buildQuickStats(),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppConstants.primaryColor,
                AppConstants.primaryColor.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          // زر فلترة المنتجات المخصومة
          if (ref.read(cartStateProvider).cart.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
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
                  size: context.isSmallScreen ? 20 : 24,
                ),
                tooltip: _showDiscountedOnly
                    ? 'عرض جميع المنتجات'
                    : 'عرض المخصومة فقط',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          if (ref.read(cartStateProvider).cart.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _clearCart,
                icon: Icon(Icons.clear_all,
                    size: context.isSmallScreen ? 20 : 24),
                tooltip: 'مسح السلة (Esc)',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'مسح الباركود (F1)',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
              ),
            ),
          ),
          // زر إنهاء اليوم
          Container(
            margin: const EdgeInsets.only(right: 16),
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
      );

  /// بناء الإحصائيات السريعة
  Widget _buildQuickStats() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) =>
            context.shouldUseVerticalLayout
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildStatChip(
                        icon: Icons.shopping_cart,
                        value: '${ref.read(cartStateProvider).cart.length}',
                        label: 'منتج',
                        color: Colors.blue,
                      ),
                      SizedBox(height: context.responsiveSpacing * 0.5),
                      _buildStatChip(
                        icon: Icons.attach_money,
                        value: formatCurrency(ref.read(totalAmountProvider)),
                        label: 'المجموع',
                        color: Colors.green,
                      ),
                    ],
                  )
                : Row(
                    children: <Widget>[
                      _buildStatChip(
                        icon: Icons.shopping_cart,
                        value: '${ref.read(cartStateProvider).cart.length}',
                        label: 'منتج',
                        color: Colors.blue,
                      ),
                      SizedBox(width: context.responsiveSpacing * 0.8),
                      _buildStatChip(
                        icon: Icons.attach_money,
                        value: formatCurrency(ref.read(totalAmountProvider)),
                        label: 'المجموع',
                        color: Colors.green,
                      ),
                    ],
                  ),
      );

  /// بناء شريط إحصائية
  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) =>
      Container(
        padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing * 0.8,
            vertical: context.responsiveSpacing * 0.4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon,
                color: Colors.white, size: context.isSmallScreen ? 14 : 16),
            SizedBox(width: context.responsiveSpacing * 0.4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(14),
              ),
            ),
            SizedBox(width: context.responsiveSpacing * 0.3),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: context.responsiveFontSize(12),
              ),
            ),
          ],
        ),
      );

  /// بناء التخطيط المحسن لـ Windows
  Widget _buildWindowsLayout() => context.shouldUseVerticalLayout
      ? Column(
          children: <Widget>[
            // شريط البحث المحسن
            _buildEnhancedSearchBar(),

            // المحتوى الرئيسي
            Expanded(
              child: Consumer(
                builder: (BuildContext context, WidgetRef ref, Widget? child) =>
                    (ref.read(cartStateProvider).isEmpty)
                        ? _buildEmptyState()
                        : _buildCartGrid(),
              ),
            ),

            _buildEnhancedCheckoutSection(),
          ],
        )
      : Row(
          children: <Widget>[
            // الشريط الجانبي للبحث والتحكم
            _buildSidebar(),

            // المحتوى الرئيسي
            Expanded(
              child: Column(
                children: <Widget>[
                  // شريط البحث المحسن
                  _buildEnhancedSearchBar(),

                  // المحتوى الرئيسي
                  Expanded(
                    child: Consumer(
                      builder: (BuildContext context, WidgetRef ref,
                              Widget? child) =>
                          (ref.read(cartStateProvider).isEmpty)
                              ? _buildEmptyState()
                              : _buildCartGrid(),
                    ),
                  ),

                  _buildEnhancedCheckoutSection(),
                ],
              ),
            ),
          ],
        );

  /// بناء الشريط الجانبي
  Widget _buildSidebar() => Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey[300]!),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            // عنوان الشريط الجانبي
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.tune, color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'أدوات التحكم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // أدوات التحكم
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // إدخال الباركود
                    _buildSidebarBarcodeInput(),

                    const SizedBox(height: 20),

                    // ملخص البيع
                    _buildSaleSummary(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  /// بناء إدخال الباركود في الشريط الجانبي
  Widget _buildSidebarBarcodeInput() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'إضافة منتج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),

          // شريط البحث عن المنتجات
          POSProductSearchWidget(
            onProductSelected: (Product product) {
              _addProductToCartByName(product.name);
            },
            placeholder: 'البحث بالاسم...',
          ),

          const SizedBox(height: 12),

          // شريط إدخال الباركود
          TextField(
            controller: _barcodeController,
            decoration: InputDecoration(
              labelText: 'باركود المنتج',
              hintText: 'أدخل الباركود أو امسحه',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.camera_alt),
                tooltip: 'مسح الباركود (F1)',
              ),
            ),
            onSubmitted: (String value) {
              if (value.isNotEmpty) {
                _addProductToCart(value);
                _barcodeController.clear();
              }
            },
          ),
        ],
      );

  /// بناء ملخص البيع
  Widget _buildSaleSummary() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppConstants.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'ملخص البيع',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) =>
                  Column(
                children: <Widget>[
                  _buildSummaryRow('المنتجات:',
                      '${ref.read(cartStateProvider).cart.length}'),
                  _buildSummaryRow('الكمية الإجمالية:',
                      '${ref.read(cartStateProvider).cart.fold<int>(0, (int sum, CartItem item) => sum + item.quantity)}'),
                  _buildSummaryRow(
                      'الربح:', formatCurrency(ref.read(totalProfitProvider))),
                ],
              ),
            ),
            const Divider(),
            _buildSummaryRow(
              'المجموع النهائي:',
              formatCurrency(ref.read(totalAmountProvider)),
              isTotal: true,
            ),
          ],
        ),
      );

  /// بناء صف في الملخص
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal
                    ? AppConstants.primaryColor
                    : AppConstants.textColor,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal
                    ? AppConstants.primaryColor
                    : AppConstants.textColor,
              ),
            ),
          ],
        ),
      );

  /// بناء شريط البحث المحسن
  Widget _buildEnhancedSearchBar() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
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
                    decoration: InputDecoration(
                      labelText: 'باركود المنتج',
                      hintText: 'أدخل الباركود أو امسحه',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                    ),
                    onSubmitted: (String value) {
                      if (value.isNotEmpty) {
                        _addProductToCart(value);
                        _barcodeController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('مسح الباركود'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// بناء حالة السلة الفارغة
  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppConstants.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'السلة فارغة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppConstants.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'امسح الباركود أو أدخل الباركود لإضافة منتجات',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('بدء مسح الباركود'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );

  /// بناء شبكة المنتجات في السلة
  Widget _buildCartGrid() => Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? child) {
          final CartState cartState = ref.watch(cartStateProvider);
          // فلترة المنتجات حسب الخصم
          final List<CartItem> filteredCart = _showDiscountedOnly
              ? cartState.cart
                  .where((CartItem item) => item.discount > 0)
                  .toList()
              : (cartState.cart);

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

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: filteredCart.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final CartItem item = filteredCart[index];
                return _buildEnhancedCartItemCard(item, index);
              },
            ),
          );
        },
      );

  /// بناء بطاقة منتج محسنة في السلة
  Widget _buildEnhancedCartItemCard(CartItem item, int index) => WindowsPOSCard(
        key: ValueKey(
            '${item.productId}_${item.quantity}_${item.discount}_${item.retailPrice}_${item.discountedPrice}_$index'),
        item: item,
        onQuantityChanged: (int newQuantity) {
          if (newQuantity <= 0) {
            _confirmRemoveItem(item);
          } else {
            _updateQuantity(item, newQuantity);
          }
        },
        onRemove: () => _confirmRemoveItem(item),
        onDiscountChanged: (double discount) =>
            _applyDiscount(item, discount.toInt().toString()),
        onRemoveDiscount: () => _removeDiscount(item),
        isExpanded: _expandedItemId == 'cart_item_$index',
        onExpansionChanged: (bool isExpanded) =>
            _handleCardExpansion('cart_item_$index', isExpanded),
        onIncreaseQuantity: () => _increaseQuantity(item),
        onDecreaseQuantity: () => _decreaseQuantity(item),
      );

  Widget _buildEnhancedCheckoutSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            // ملخص البيع
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'ملخص البيع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder:
                        (BuildContext context, WidgetRef ref, Widget? child) =>
                            Text(
                      '${ref.read(cartStateProvider).cart.length} منتج • ${ref.read(cartStateProvider).cart.fold<int>(0, (int sum, CartItem item) => sum + item.quantity)} كمية',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // المبلغ الإجمالي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  const Text(
                    'المجموع النهائي',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    formatCurrency(ref.read(totalAmountProvider)),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// عرض شاشة تأكيد إنهاء اليوم
  Future<void> _showEndOfDayConfirmation() async {
    final List<CartItem> cartItems = ref.read(cartStateProvider).cart;
    final bool hasUnsavedItems = cartItems.isNotEmpty;

    // جلب الإحصائيات السريعة
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
                          'تحذير: لديك ${cartItems.length} منتج في السلة لم يتم حفظه!',
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
                      Icons.attach_money,
                    ),
                    const Divider(height: 16),
                    _buildQuickStat(
                      'عدد المنتجات المباعة',
                      '${todayStats['totalItems'] as int}',
                      Icons.shopping_cart,
                    ),
                    const Divider(height: 16),
                    _buildQuickStat(
                      'آخر عملية بيع',
                      (todayStats['lastSaleTime'] as String?) ?? 'لا توجد',
                      Icons.access_time,
                    ),
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

  /// بناء إحصائية سريعة
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

  /// جلب الإحصائيات السريعة لليوم
  Future<Map<String, dynamic>> _getTodayQuickStats() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

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
        'lastSaleTime': 'لا توجد',
      };
    }
  }

  /// حفظ سريع للسلة
  Future<void> _quickSave() async {
    try {
      final List<CartItem> cartItems = ref.read(cartStateProvider).cart;
      if (cartItems.isNotEmpty) {
        // حفظ السلة في Firebase
        await POSService.saveCartToFirebase(
          cart: cartItems,
          sessionId: _currentSessionId ?? 'default_session',
        );
        SnackbarUtils.showSuccess(context, 'تم حفظ السلة بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة: $e');
      SnackbarUtils.showError(context, 'فشل في حفظ السلة');
    }
  }

  /// تنفيذ عملية إنهاء اليوم
  Future<void> _performEndOfDay() async {
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
                  const Text(
                    'جارٍ إنهاء اليوم...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep,
                    style: const TextStyle(color: Colors.grey),
                  ),
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
      final List<CartItem> cartItems = ref.read(cartStateProvider).cart;
      if (cartItems.isNotEmpty) {
        await _quickSave();
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // الخطوة 2: إنشاء تقرير نهاية اليوم
      setState(() => _currentStep = 'إنشاء تقرير نهاية اليوم...');
      final List<CartItem> currentCartItems = ref.read(cartStateProvider).cart;
      final EODReport report = await EODService.generateEODReport(
        employeeId: 'windows_user',
        employeeName: 'مستخدم Windows',
        currentCartItems: currentCartItems, // تمرير السلة الحالية
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // الخطوة 3: حفظ التقرير محلياً
      setState(() => _currentStep = 'حفظ التقرير...');
      await EODService.saveEODReportLocally(report);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // الخطوة 4: المزامنة مع الخادم
      setState(() => _currentStep = 'المزامنة مع الخادم...');
      await EODService.syncEODReport(report);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // الخطوة 5: إنشاء نسخة احتياطية
      setState(() => _currentStep = 'إنشاء نسخة احتياطية...');
      await EODService.createBackup(report);
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // إغلاق مؤشر التحميل
      Navigator.pop(context);

      // عرض تقرير نهاية اليوم
      await _showEODReport(report);
    } catch (e) {
      // إغلاق مؤشر التحميل
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // عرض رسالة خطأ مع خيارات إضافية
      showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Text('فشل إنهاء اليوم'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('حدث خطأ أثناء إنهاء اليوم:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  e.toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('البيانات محفوظة محلياً وسيتم إعادة المحاولة لاحقاً.'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // إعادة تعيين الحالة
                setState(() {
                  _isProcessingEOD = false;
                });
              },
              child: const Text('حسناً'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // إعادة تعيين الحالة
                setState(() {
                  _isProcessingEOD = false;
                });
                // إعادة المحاولة
                _performEndOfDay();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    } finally {
      // التأكد من إعادة تعيين الحالة حتى لو حدث خطأ في العرض
      if (mounted) {
        setState(() {
          _isProcessingEOD = false;
        });
      }
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
                              '${report.totalSales.toStringAsFixed(2)} DZ',
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
                              '${report.totalProfit.toStringAsFixed(2)} DZ',
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
                              '${(report.totalSales / report.totalItemsSold).toStringAsFixed(2)} DZ',
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
                                  horizontal: 12,
                                  vertical: 6,
                                ),
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
                                  '${product.totalValue.toStringAsFixed(2)} DZ',
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
                child: Row(
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
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDayEndedSuccess();
                        },
                        icon: const Icon(Icons.check_circle),
                        label:
                            const Text('إتمام', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
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
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  /// تنسيق التاريخ
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  /// طباعة تقرير نهاية اليوم
  void _printEODReport(EODReport report) {
    // TODO: تطبيق وظيفة الطباعة
    SnackbarUtils.showInfo(context, 'وظيفة الطباعة قيد التطوير');
  }

  /// تصدير تقرير نهاية اليوم إلى Excel
  void _exportEODToExcel(EODReport report) {
    // TODO: تطبيق وظيفة التصدير إلى Excel
    SnackbarUtils.showInfo(context, 'وظيفة التصدير إلى Excel قيد التطوير');
  }

  /// عرض رسالة نجاح إنهاء اليوم
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForNewDay();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('بدء يوم جديد'),
          ),
        ],
      ),
    );
  }

  /// إعادة تعيين ليوم جديد
  void _resetForNewDay() {
    // مسح السلة
    ref.read(cartStateProvider.notifier).clearCart();

    // إعادة تحميل البيانات
    _initializeData();

    SnackbarUtils.showSuccess(context, 'تم بدء يوم جديد بنجاح');
  }
}
