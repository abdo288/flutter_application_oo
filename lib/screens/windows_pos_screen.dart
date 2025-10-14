import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/stream_app_provider.dart';
import '../services/pos_service.dart';
import '../services/unified_sales_service.dart';
import '../services/app_event_bus.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/pos_product_search_widget.dart';
import '../widgets/windows_pos_card.dart';

// Simple currency formatter function
String formatCurrency(int amount) => '${amount.toString()} DZ';

/// شاشة نقطة البيع المحسنة لمنصة Windows
class WindowsPOSScreen extends StatefulWidget {
  const WindowsPOSScreen({super.key});

  @override
  State<WindowsPOSScreen> createState() => _WindowsPOSScreenState();
}

class _WindowsPOSScreenState extends State<WindowsPOSScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _discountControllers =
      <String, TextEditingController>{};

  bool _isLoading = false;
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

  /// ✅ تهيئة البيانات عند فتح الشاشة
  Future<void> _initializeData() async {
    if (!mounted || _hasInitialized) return;

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // ✅ انتظار تهيئة التطبيق بالكامل
      if (!appProvider.isInitialized) {
        debugPrint('🪟 Windows POS: انتظار تهيئة التطبيق...');
        await appProvider.initializationComplete;
      }

      // تحسين خاص بـ Windows - إعادة تحميل البيانات
      if (Platform.isWindows) {
        debugPrint('🪟 Windows POS: إعادة تحميل البيانات...');
        await appProvider.refreshAll();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      // ✅ التأكد من تهيئة CartProvider
      debugPrint('🪟 Windows POS: تهيئة CartProvider...');
      await appProvider.cartProvider.initialize();

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
      final List<CartItem> currentCart = appProvider.cartProvider.cart;
      if (currentCart.isNotEmpty) {
        debugPrint(
            '🪟 Windows POS: تم العثور على ${currentCart.length} عنصر في السلة المحلية');
        // إعادة حفظ السلة للتأكد
        await appProvider.cartProvider.saveCartManually();
      }

      if (appProvider.isInitialized) {
        debugPrint('🔄 تم جلب بيانات POS في Windows POS Screen');
      }

      _hasInitialized = true;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات POS: $e');
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
      setState(() {});
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
      setState(() {});
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
      setState(() {});
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
      setState(() {});
    }
  }

  /// ✅ معالجة إتمام عملية بيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    debugPrint('💰 معالجة إتمام عملية بيع في Windows POS: ${event.sale.id}');

    // تحديث الواجهة
    if (mounted) {
      setState(() {});
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
      setState(() {});
    }
  }

  /// ✅ Pull-to-refresh لإعادة تحميل البيانات
  Future<void> _onRefresh() async {
    try {
      debugPrint('🔄 بدء تحديث بيانات POS...');

      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // التأكد من أن التطبيق مهيأ
      if (!appProvider.isInitialized) {
        debugPrint('⚠️ التطبيق لم يتم تهيئته بعد');
        return;
      }

      await appProvider.refreshAll();

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
        final List<dynamic> items = data['items'] as List<dynamic>? ?? <dynamic>[];
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
    if (_currentSessionId == null) return;

    try {
      final List<CartItem> firebaseCart = await POSService.loadCartFromFirebase(
        sessionId: _currentSessionId!,
      );

      if (firebaseCart.isNotEmpty) {
        final StreamAppProvider appProvider = context.read<StreamAppProvider>();

        debugPrint('🔄 Firebase: تم العثور على ${firebaseCart.length} عنصر');
        debugPrint('🔄 المحلي: ${appProvider.cartProvider.cart.length} عنصر');

        // ✅ تحسين: فقط إذا كانت السلة المحلية فارغة أو مختلفة
        final List<CartItem> currentCart = appProvider.cartProvider.cart;
        if (currentCart.isEmpty || !_areCartsEqual(firebaseCart, currentCart)) {
          // مسح السلة الحالية
          appProvider.cartProvider.clearCart();

          // إضافة العناصر من Firebase
          for (final CartItem item in firebaseCart) {
            appProvider.cartProvider.addItem(item);
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

  /// ✅ بدء الاستماع لتغييرات السلة في Firebase
  void _startCartFirebaseListening() {
    if (_currentSessionId == null) return;

    _cartFirebaseSubscription = POSService.watchCartFromFirebase(
      sessionId: _currentSessionId!,
    ).listen((List<CartItem> firebaseCart) {
      if (!mounted) return;

      try {
        final StreamAppProvider appProvider = context.read<StreamAppProvider>();
        final List<CartItem> currentCart = appProvider.cartProvider.cart;

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

          // ✅ تحسين: فقط إذا كان Firebase يحتوي على عناصر
          if (firebaseCart.isNotEmpty) {
            // مسح السلة الحالية
            appProvider.cartProvider.clearCart();

            // إضافة العناصر من Firebase
            for (final CartItem item in firebaseCart) {
              appProvider.cartProvider.addItem(item);
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
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final List<CartItem> cart = appProvider.cartProvider.cart;

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
    // Ctrl + Enter لإتمام البيع
    RawKeyboardListener(
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              HardwareKeyboard.instance.isControlPressed) {
            _completeSale();
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
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

      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      debugPrint('🪟 Windows: تم الحصول على StreamAppProvider');

      // البحث عن المنتج في المخزون
      final Product? product = await POSService.findProductByName(
        appProvider.productProvider,
        appProvider.inventoryProvider,
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
        appProvider.inventoryProvider,
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
        appProvider.inventoryProvider,
        name,
        1,
      );

      debugPrint('🪟 Windows: تم خصم الكمية من المخزون');

      // إضافة العنصر إلى CartProvider (سيتعامل مع المنتجات المكررة تلقائياً)
      appProvider.cartProvider.addItem(newItem);

      debugPrint('🪟 Windows: تم إضافة المنتج للسلة');

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // تحديث الواجهة فوراً
      if (mounted) {
        setState(() {});
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

      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      debugPrint('🪟 Windows: تم الحصول على StreamAppProvider');

      final CartItem? cartItem =
          await POSService.addProductToCartWithValidation(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
        barcode: barcode,
        currentCart: List<CartItem>.from(appProvider.cartProvider.cart),
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
          appProvider.inventoryProvider,
          barcode,
          1, // ✓ دائماً نخصم 1 فقط عند الإضافة
        );

        debugPrint('🪟 Windows: تم تحديث المخزون، بدء إضافة للسلة');
        debugPrint(
            '🪟 Windows: حجم السلة قبل الإضافة: ${appProvider.cartProvider.cart.length}');

        // إضافة العنصر إلى CartProvider
        appProvider.cartProvider.addItem(cartItem);

        debugPrint('🪟 Windows: تم إضافة العنصر إلى CartProvider');
        debugPrint(
            '🪟 Windows: حجم السلة بعد الإضافة: ${appProvider.cartProvider.cart.length}');

        // ✅ حفظ السلة في Firebase
        await _saveCartToFirebase();

        // تحديث الواجهة فوراً (مثل Android)
        if (mounted) {
          setState(() {});
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
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // الحصول على الكمية الحالية في السلة
      final int currentQuantity = item.quantity;
      final int quantityDifference = newQuantity - currentQuantity;

      // إذا لم يتغير شيء، لا نفعل شيئاً
      if (quantityDifference == 0) return;

      // التحقق من توفر الكمية في المخزون (فقط إذا كانت الزيادة)
      if (quantityDifference > 0) {
        final int availableQuantity = await POSService.getAvailableQuantity(
          appProvider.inventoryProvider,
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
          appProvider.inventoryProvider,
          item.barcode,
          quantityDifference,
        );
      } else {
        // تقليل الكمية - نضيف للمخزون
        await POSService.increaseInventoryQuantity(
          appProvider.inventoryProvider,
          item.barcode,
          -quantityDifference, // نضيف القيمة المطلقة
        );
      }

      // تحديث الكمية في السلة
      appProvider.cartProvider.updateQuantityForItem(item, newQuantity);

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // إعادة بناء الواجهة فوراً
      setState(() {});

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
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // التحقق من توفر الكمية في المخزون
      final int availableQuantity = await POSService.getAvailableQuantity(
        appProvider.inventoryProvider,
        item.barcode,
      );

      if (availableQuantity <= 0) {
        SnackbarUtils.showError(context, 'المنتج نفذ من المخزون');
        return;
      }

      // خصم كمية من المخزون
      await POSService.decreaseInventoryQuantity(
        appProvider.inventoryProvider,
        item.barcode,
        1,
      );

      // زيادة الكمية في السلة - استخدام الطريقة الجديدة
      appProvider.cartProvider.updateQuantityForItem(item, item.quantity + 1);

      // ✅ حفظ السلة في Firebase
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
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      if (item.quantity > 1) {
        // إرجاع كمية واحدة إلى المخزون
        await POSService.increaseInventoryQuantity(
          appProvider.inventoryProvider,
          item.barcode,
          1,
        );

        // تقليل الكمية في السلة - استخدام الطريقة الجديدة
        appProvider.cartProvider.updateQuantityForItem(item, item.quantity - 1);

        // ✅ حفظ السلة في Firebase
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
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();

    try {
      // إرجاع الكمية إلى المخزون فوراً
      await POSService.increaseInventoryQuantity(
        appProvider.inventoryProvider,
        item.barcode,
        item.quantity,
      );
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في إرجاع الكمية للمخزون: $e');
    }

    appProvider.cartProvider.removeItemByObject(item);

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
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    appProvider.cartProvider.clearCart();

    // ✅ حفظ السلة في Firebase
    await _saveCartToFirebase();

    setState(() {});
    SnackbarUtils.showInfo(context, 'تم مسح السلة');
  }

  /// إتمام عملية البيع
  Future<void> _completeSale() async {
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    if (appProvider.cartProvider.isEmpty) {
      SnackbarUtils.showError(context, 'السلة فارغة');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<CartItem> snapshotCart =
          List<CartItem>.from(appProvider.cartProvider.cart);
      SnackbarUtils.showSuccess(context, 'جارٍ حفظ عملية البيع...');
      _clearCart();
      final String saleId = await UnifiedSalesService.completeCartSaleStatic(
        productProvider: appProvider.productProvider,
        inventoryProvider: appProvider.inventoryProvider,
        cart: snapshotCart,
      );

      _showSaleDetails(saleId);
    } catch (e) {
      SnackbarUtils.showError(context, 'تعذر حفظ عملية البيع، تمت إعادة السلة');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// عرض تفاصيل البيع
  void _showSaleDetails(String saleId) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('تم إتمام البيع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('رقم العملية: $saleId'),
            const SizedBox(height: 8),
            Text('المبلغ الإجمالي: ${formatCurrency(_getTotalAmount())}'),
            Text('الربح: ${formatCurrency(_getTotalProfit())}'),
            const Text('طريقة الدفع: نقدي'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }

  /// حساب المبلغ الإجمالي
  int _getTotalAmount() {
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    return appProvider.cartProvider.getTotalAmount();
  }

  /// حساب الربح الإجمالي
  int _getTotalProfit() {
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    return appProvider.cartProvider.getTotalProfit();
  }

  /// تطبيق الخصم على منتج
  Future<void> _applyDiscount(CartItem item, String value) async {
    final int? discount = int.tryParse(value);
    if (discount != null && discount >= 0) {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      appProvider.cartProvider.applyDiscountToItem(item, discount);

      // ✅ حفظ السلة في Firebase
      await _saveCartToFirebase();

      // إعادة بناء الواجهة فوراً
      setState(() {});

      SnackbarUtils.showSuccess(context, 'تم تطبيق الخصم: $discount دينار');
    } else {
      SnackbarUtils.showError(context, 'قيمة الخصم غير صحيحة');
    }
  }

  /// تنظيف controllers غير المستخدمة
  void _cleanupUnusedControllers() {
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    final List<String> currentKeys = appProvider.cartProvider.cart
        .map((CartItem item) => '${item.productId}_${item.discount}_${item.quantity}')
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
          if (context.watch<StreamAppProvider>().cartProvider.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _showDiscountedOnly = !_showDiscountedOnly;
                  });
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
          if (context.watch<StreamAppProvider>().cartProvider.isNotEmpty)
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
        ],
      );

  /// بناء الإحصائيات السريعة
  Widget _buildQuickStats() => Consumer<StreamAppProvider>(
      builder: (context, appProvider, child) {
        return context.shouldUseVerticalLayout
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildStatChip(
                    icon: Icons.shopping_cart,
                    value: '${appProvider.cartProvider.itemCount}',
                    label: 'منتج',
                    color: Colors.blue,
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  _buildStatChip(
                    icon: Icons.attach_money,
                    value: formatCurrency(_getTotalAmount()),
                    label: 'المجموع',
                    color: Colors.green,
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  _buildStatChip(
                    icon: Icons.shopping_cart,
                    value: '${appProvider.cartProvider.itemCount}',
                    label: 'منتج',
                    color: Colors.blue,
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.8),
                  _buildStatChip(
                    icon: Icons.attach_money,
                    value: formatCurrency(_getTotalAmount()),
                    label: 'المجموع',
                    color: Colors.green,
                  ),
                ],
              );
      },
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
              child: Consumer<StreamAppProvider>(
                builder: (BuildContext context, StreamAppProvider appProvider, Widget? child) => appProvider.cartProvider.isEmpty
                      ? _buildEmptyState()
                      : _buildCartGrid(),
              ),
            ),

            // شريط إتمام البيع المحسن
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
                    child: Consumer<StreamAppProvider>(
                      builder: (BuildContext context, StreamAppProvider appProvider, Widget? child) => appProvider.cartProvider.isEmpty
                            ? _buildEmptyState()
                            : _buildCartGrid(),
                    ),
                  ),

                  // شريط إتمام البيع المحسن
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
            Consumer<StreamAppProvider>(
              builder: (BuildContext context, StreamAppProvider appProvider, Widget? child) => Column(
                  children: [
                    _buildSummaryRow(
                        'المنتجات:', '${appProvider.cartProvider.itemCount}'),
                    _buildSummaryRow('الكمية الإجمالية:',
                        '${appProvider.cartProvider.getTotalQuantity()}'),
                    _buildSummaryRow(
                        'الربح:', formatCurrency(_getTotalProfit())),
                  ],
                ),
            ),
            const Divider(),
            _buildSummaryRow(
              'المجموع النهائي:',
              formatCurrency(_getTotalAmount()),
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
  Widget _buildCartGrid() => Consumer<StreamAppProvider>(
      builder: (context, appProvider, child) {
        // فلترة المنتجات حسب الخصم
        final List<CartItem> filteredCart = _showDiscountedOnly
            ? appProvider.cartProvider.cart
                .where((item) => item.discount > 0)
                .toList()
            : appProvider.cartProvider.cart;

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
            separatorBuilder: (context, index) => const SizedBox(height: 8),
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
        isExpanded: _expandedItemId == 'cart_item_$index',
        onExpansionChanged: (bool isExpanded) =>
            _handleCardExpansion('cart_item_$index', isExpanded),
        onIncreaseQuantity: () => _increaseQuantity(item),
        onDecreaseQuantity: () => _decreaseQuantity(item),
      );

  /// بناء قسم إتمام البيع المحسن
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
                  Consumer<StreamAppProvider>(
                    builder: (BuildContext context, StreamAppProvider appProvider, Widget? child) => Text(
                        '${appProvider.cartProvider.itemCount} منتج • ${appProvider.cartProvider.getTotalQuantity()} كمية',
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
                    formatCurrency(_getTotalAmount()),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // زر إتمام البيع
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(Icons.check_circle),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? 'جاري المعالجة...' : 'إتمام البيع',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
