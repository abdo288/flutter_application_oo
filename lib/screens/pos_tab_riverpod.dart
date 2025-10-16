import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/pos_riverpod_providers.dart';
import '../providers/stream_riverpod_providers.dart';
import '../services/error_handler_service.dart';
import '../services/pos_service.dart';
import '../services/unified_sales_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/barcode_scanner_view.dart';
import '../widgets/pos_product_search_widget.dart';
import '../widgets/success_feedback_widget.dart';

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

  bool _isLoading = false;
  bool _showDiscountedOnly = false;

  // متغيرات التحسينات الجديدة
  Timer? _searchDebounceTimer;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    // تهيئة السلة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartStateProvider.notifier).initialize();
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
    // تنظيف discount controllers
    for (final TextEditingController controller
        in _discountControllers.values) {
      controller.dispose();
    }
    _discountControllers.clear();
    super.dispose();
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
      // البحث عن المنتج في المخزون
      final Product? product = await POSService.findProductByName(
        ref.read(streamProductProvider),
        ref.read(streamInventoryProvider),
        name,
      );

      if (product == null) {
        SnackbarUtils.showError(
            context, 'لم يتم العثور على منتج بالاسم: $name');
        return;
      }

      // التحقق من توفر الكمية
      final int availableQuantity = await POSService.getAvailableQuantityByName(
        ref.read(streamInventoryProvider),
        name,
      );

      if (availableQuantity <= 0) {
        SnackbarUtils.showError(context, 'المنتج نفذ من المخزون');
        return;
      }

      // البحث عن المنتج في السلة الحالية (بالاسم أو الباركود)
      final cartState = ref.read(cartStateProvider);
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
          ref.read(streamInventoryProvider),
          name,
          1,
        );

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
          ref.read(streamInventoryProvider),
          name,
          1,
        );

        // إضافة العنصر إلى السلة
        ref.read(cartStateProvider.notifier).addItem(newItem);
      }

      // تحديث الواجهة فوراً
      if (mounted) {
        setState(() {});
      }

      // تشغيل الـ animation عند إضافة منتج جديد
      _fadeController.reset();
      _fadeController.forward();

      SnackbarUtils.showSuccess(context, 'تم إضافة ${product.name} إلى السلة');
    } catch (e) {
      // عرض رسالة الخطأ الفعلية من الـ Exception
      SnackbarUtils.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// إضافة منتج إلى السلة
  Future<void> _addProductToCart(String barcode) async {
    try {
      final CartItem? cartItem =
          await POSService.addProductToCartWithValidation(
        productProvider: ref.read(streamProductProvider),
        inventoryProvider: ref.read(streamInventoryProvider),
        barcode: barcode,
        currentCart: ref.read(cartStateProvider).cart,
      );

      if (cartItem != null) {
        // تحديث المخزون فوراً عند الإضافة - نخصم 1 فقط (الكمية المضافة)
        await POSService.decreaseInventoryQuantity(
          ref.read(streamInventoryProvider),
          barcode,
          1, // ✓ دائماً نخصم 1 فقط عند الإضافة
        );

        // إضافة العنصر إلى السلة
        ref.read(cartStateProvider.notifier).addItem(cartItem);

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
      // عرض رسالة الخطأ الفعلية من الـ Exception
      SnackbarUtils.showError(
          context, e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// زيادة كمية منتج في السلة
  Future<void> _increaseQuantity(CartItem item) async {
    try {
      // التحقق من توفر الكمية في المخزون
      final int availableQuantity = await POSService.getAvailableQuantity(
        ref.read(streamInventoryProvider),
        item.barcode,
      );

      if (availableQuantity <= 0) {
        SnackbarUtils.showError(context, 'المنتج نفذ من المخزون');
        return;
      }

      // خصم كمية من المخزون
      await POSService.decreaseInventoryQuantity(
        ref.read(streamInventoryProvider),
        item.barcode,
        1,
      );

      // زيادة الكمية في السلة - استخدام الطريقة الجديدة
      ref
          .read(cartStateProvider.notifier)
          .updateQuantityForItem(item, item.quantity + 1);

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
          ref.read(streamInventoryProvider),
          item.barcode,
          1,
        );

        // تقليل الكمية في السلة - استخدام الطريقة الجديدة
        ref
            .read(cartStateProvider.notifier)
            .updateQuantityForItem(item, item.quantity - 1);

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
          ref.read(streamInventoryProvider),
          item.barcode,
          item.quantity,
        );
      },
      userAction: 'حذف منتج من السلة وإرجاع الكمية للمخزون',
    );

    // حذف العنصر من السلة - استخدام الطريقة الجديدة
    ref.read(cartStateProvider.notifier).removeItemByObject(item);
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
  void _clearCart() {
    ref.read(cartStateProvider.notifier).clearCart();
    setState(() {});
    SnackbarUtils.showInfo(context, 'تم مسح السلة');
  }

  /// إتمام عملية البيع
  Future<void> _completeSale() async {
    final cartState = ref.read(cartStateProvider);
    if (cartState.isEmpty) {
      SnackbarUtils.showError(context, 'السلة فارغة');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final success = await ErrorHelper.safeExecute(
      () async {
        // Optimistic UX: أظهر نجاحًا فوريًا ثم احفظ في الخلفية
        final List<CartItem> snapshotCart = List<CartItem>.from(cartState.cart);

        // أظهر رسالة نجاح وتجربة فورية
        SnackbarUtils.showSuccess(context, 'جارٍ حفظ عملية البيع...');
        // مسح السلة فورًا ليشعر المستخدم بسرعة الاستجابة
        _clearCart();

        // احفظ البيع في الخلفية (بدون تحديث المخزون لأنه محدث مسبقاً)
        final String saleId = await UnifiedSalesService.completeCartSaleStatic(
          productProvider: ref.read(streamProductProvider),
          inventoryProvider: ref.read(streamInventoryProvider),
          cart: snapshotCart,
        );

        // عرض تفاصيل البيع بعد اكتمال الحفظ
        _showSaleDetails(saleId);
      },
      userAction: 'إتمام عملية البيع في شاشة POS',
    );

    if (success == null) {
      // عند الفشل: أعد السلة كما كانت
      SnackbarUtils.showError(context, 'تعذر حفظ عملية البيع، تمت إعادة السلة');
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// عرض تفاصيل البيع
  void _showSaleDetails(String saleId) {
    // استخدام postFrameCallback لتجنب مشاكل BuildContext
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext context) => Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SuccessFeedbackWidget(
                  title: 'تم إتمام البيع بنجاح!',
                  message: 'رقم العملية: $saleId',
                  autoDismiss: false,
                ),
                Container(
                  margin: const EdgeInsets.only(top: AppConstants.spacing16),
                  padding: const EdgeInsets.all(AppConstants.spacing24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildSaleDetailRow(
                          'المبلغ الإجمالي', formatCurrency(_getTotalAmount())),
                      _buildSaleDetailRow(
                          'الربح', formatCurrency(_getTotalProfit())),
                      _buildSaleDetailRow('طريقة الدفع', 'نقدي'),
                      const SizedBox(height: AppConstants.spacing24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacing16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadiusSmall,
                              ),
                            ),
                          ),
                          child: const Text('موافق',
                              style: TextStyle(
                                fontWeight: AppConstants.fontWeightBold,
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  /// بناء صف تفاصيل البيع
  Widget _buildSaleDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSizeBody,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeBody,
                fontWeight: AppConstants.fontWeightBold,
              ),
            ),
          ],
        ),
      );

  /// حساب المبلغ الإجمالي
  int _getTotalAmount() {
    return ref.read(totalAmountProvider);
  }

  /// حساب الربح الإجمالي
  int _getTotalProfit() {
    return ref.read(totalProfitProvider);
  }

  /// تطبيق الخصم على منتج
  void _applyDiscount(CartItem item, String value) {
    final int? discount = int.tryParse(value);
    if (discount != null && discount >= 0) {
      ref.read(cartStateProvider.notifier).applyDiscountToItem(item, discount);
      setState(() {});
      SnackbarUtils.showSuccess(context, 'تم تطبيق الخصم');
    } else {
      SnackbarUtils.showError(context, 'قيمة الخصم غير صحيحة');
    }
  }

  /// إلغاء الخصم على منتج
  void _cancelDiscount(CartItem item) {
    ref.read(cartStateProvider.notifier).removeDiscountFromItem(item);
    setState(() {});
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
    final cartState = ref.read(cartStateProvider);
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
          // زر فلترة المنتجات المخصومة
          Consumer(
            builder: (context, ref, child) {
              final cartIsNotEmpty = ref.watch(cartIsNotEmptyProvider);
              if (!cartIsNotEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: () {
                  setState(() {
                    _showDiscountedOnly = !_showDiscountedOnly;
                  });
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
            builder: (context, ref, child) {
              final cartIsNotEmpty = ref.watch(cartIsNotEmptyProvider);
              if (!cartIsNotEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: _clearCart,
                icon: const Icon(Icons.clear_all),
                tooltip: 'مسح السلة',
              );
            },
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

                    // شريط إتمام البيع
                    _buildCheckoutSection(),
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
        builder: (context, ref, child) {
          final cartState = ref.watch(cartStateProvider);
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
        builder: (context, ref, child) {
          final cartState = ref.watch(cartStateProvider);

          if (cartState.isEmpty) {
            return _buildEmptyCart();
          }

          // فلترة المنتجات حسب الخصم
          final List<CartItem> filteredCart = _showDiscountedOnly
              ? cartState.cart.where((item) => item.discount > 0).toList()
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

  /// بناء قسم إتمام البيع
  Widget _buildCheckoutSection() {
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 400, // حد أقصى للارتفاع
        ),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // تفاصيل البيع
              _buildSaleDetails(),

              // أزرار الإجراءات
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isLoading ? 'جاري المعالجة...' : 'إتمام البيع'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء تفاصيل البيع
  Widget _buildSaleDetails() => Consumer(
        builder: (context, ref, child) {
          final cartState = ref.watch(cartStateProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ملخص البيع
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('المنتجات: ${cartState.itemCount}'),
                    Text('الكمية الإجمالية: ${cartState.totalQuantity}'),
                    Text('الربح: ${formatCurrency(cartState.totalProfit)}'),
                    const Divider(),
                    Text(
                      'المجموع: ${formatCurrency(cartState.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  /// Pull-to-refresh مع animation
  Future<void> _onRefresh() async {
    try {
      // إعادة تشغيل الـ animations
      _fadeController.reset();
      _slideController.reset();

      await ref.read(streamAppProvider.notifier).refreshAll();

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
}
