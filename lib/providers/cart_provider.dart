import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

/// مقدم خدمة السلة - يدير حالة السلة بشكل مركزي
class CartProvider with ChangeNotifier {
  final List<CartItem> _cart = <CartItem>[];

  // مفاتيح SharedPreferences
  static const String _cartKey = 'cart_items';
  static const String _cartTimestampKey = 'cart_timestamp';

  // متغيرات الحفظ
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// الحصول على نسخة غير قابلة للتعديل من السلة
  List<CartItem> get cart => List<CartItem>.unmodifiable(_cart);

  /// التحقق من أن السلة فارغة
  bool get isEmpty => _cart.isEmpty;

  /// التحقق من أن السلة غير فارغة
  bool get isNotEmpty => _cart.isNotEmpty;

  /// عدد العناصر في السلة
  int get itemCount => _cart.length;

  /// تهيئة CartProvider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCartFromStorage();
      _isInitialized = true;
      debugPrint('🛒 تم تهيئة CartProvider بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة CartProvider: $e');
    }
  }

  /// حفظ السلة في SharedPreferences
  Future<void> _saveCartToStorage() async {
    if (_prefs == null) return;

    try {
      // تحويل السلة إلى JSON
      final List<Map<String, dynamic>> cartJson =
          _cart.map((CartItem item) => item.toMap()).toList();
      final String cartString = jsonEncode(cartJson);

      // حفظ السلة والوقت
      await _prefs!.setString(_cartKey, cartString);
      await _prefs!
          .setString(_cartTimestampKey, DateTime.now().toIso8601String());

      debugPrint('💾 تم حفظ السلة في SharedPreferences');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة: $e');
    }
  }

  /// استعادة السلة من SharedPreferences
  Future<void> _loadCartFromStorage() async {
    if (_prefs == null) return;

    try {
      final String? cartString = _prefs!.getString(_cartKey);
      if (cartString != null && cartString.isNotEmpty) {
        final List<dynamic> cartJson = jsonDecode(cartString) as List<dynamic>;
        _cart.clear();

        for (final dynamic itemData in cartJson) {
          final Map<String, dynamic> itemJson =
              itemData as Map<String, dynamic>;
          try {
            final CartItem item = CartItem.fromMap(itemJson);
            _cart.add(item);
          } catch (e) {
            debugPrint('❌ خطأ في تحويل عنصر السلة: $e');
          }
        }

        debugPrint('📦 تم استعادة ${_cart.length} عنصر من السلة');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ خطأ في استعادة السلة: $e');
    }
  }

  /// مسح السلة المحفوظة
  Future<void> _clearStoredCart() async {
    if (_prefs == null) return;

    try {
      await _prefs!.remove(_cartKey);
      await _prefs!.remove(_cartTimestampKey);
      debugPrint('🗑️ تم مسح السلة المحفوظة');
    } catch (e) {
      debugPrint('❌ خطأ في مسح السلة المحفوظة: $e');
    }
  }

  /// حفظ السلة يدوياً (للاستخدام الخارجي)
  Future<void> saveCartManually() async {
    await _saveCartToStorage();
  }

  /// إضافة عنصر إلى السلة
  void addItem(CartItem item) {
    // ✅ البحث عن منتج بنفس productId و نفس الخصم
    final int index = _cart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      // المنتج موجود بنفس الخصم - زيادة الكمية
      _cart[index] = _cart[index]
          .copyWith(quantity: _cart[index].quantity + item.quantity);
    } else {
      // منتج جديد أو نفس المنتج بخصم مختلف - إضافته كعنصر منفصل
      _cart.add(item);
    }
    notifyListeners();
    _saveCartToStorage(); // حفظ السلة تلقائياً
  }

  /// تحديث كمية منتج في السلة
  void updateQuantity(String productId, int newQuantity, {int discount = 0}) {
    final int index = _cart.indexWhere((CartItem element) =>
        element.productId == productId && element.discount == discount);
    if (index != -1) {
      if (newQuantity > 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// تحديث كمية عنصر محدد في السلة
  void updateQuantityForItem(CartItem item, int newQuantity) {
    final int index = _cart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      if (newQuantity > 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    } else {
      // إذا لم يتم العثور على العنصر، جرب البحث بالباركود
      final int barcodeIndex = _cart.indexWhere((CartItem element) =>
          element.barcode == item.barcode && element.discount == item.discount);

      if (barcodeIndex != -1) {
        if (newQuantity > 0) {
          _cart[barcodeIndex] =
              _cart[barcodeIndex].copyWith(quantity: newQuantity);
        } else {
          _cart.removeAt(barcodeIndex);
        }
        notifyListeners();
        _saveCartToStorage(); // حفظ السلة تلقائياً
      }
    }
  }

  /// تحديث كمية عنصر بناءً على الاسم (للمنتجات المخصومة)
  void updateQuantityForItemByName(String name, int newQuantity) {
    final int index = _cart.indexWhere(
        (CartItem element) => element.name.toLowerCase() == name.toLowerCase());

    if (index != -1) {
      if (newQuantity > 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// حذف عنصر من السلة
  void removeItem(String productId, {int discount = 0}) {
    _cart.removeWhere((CartItem element) =>
        element.productId == productId && element.discount == discount);
    notifyListeners();
    _saveCartToStorage(); // حفظ السلة تلقائياً
  }

  /// حذف عنصر محدد من السلة
  void removeItemByObject(CartItem item) {
    final int index = _cart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      _cart.removeAt(index);
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    } else {
      // إذا لم يتم العثور على العنصر، جرب البحث بالباركود
      final int barcodeIndex = _cart.indexWhere((CartItem element) =>
          element.barcode == item.barcode && element.discount == item.discount);

      if (barcodeIndex != -1) {
        _cart.removeAt(barcodeIndex);
        notifyListeners();
        _saveCartToStorage(); // حفظ السلة تلقائياً
      }
    }
  }

  /// مسح السلة بالكامل
  void clearCart() {
    _cart.clear();
    notifyListeners();
    _saveCartToStorage(); // حفظ السلة تلقائياً
    _clearStoredCart(); // مسح السلة المحفوظة أيضاً
  }

  /// تطبيق خصم على منتج
  void applyDiscount(String productId, int discount) {
    final int index =
        _cart.indexWhere((CartItem element) => element.productId == productId);
    if (index != -1) {
      final CartItem oldItem = _cart[index];
      final int oldDiscount = oldItem.discount;

      // إذا كان الخصم مختلف، نحذف العنصر القديم ونضيف واحد جديد
      if (oldDiscount != discount) {
        _cart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: discount);
        _cart.add(newItem);
      } else {
        // نفس الخصم - تحديث مباشر
        _cart[index] = oldItem.copyWith(discount: discount);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// تطبيق خصم على عنصر محدد في السلة
  void applyDiscountToItem(CartItem item, int discount) {
    final int index = _cart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount &&
        element.quantity == item.quantity);

    if (index != -1) {
      final CartItem oldItem = _cart[index];
      final int oldDiscount = oldItem.discount;

      // إذا كان الخصم مختلف، نحذف العنصر القديم ونضيف واحد جديد
      if (oldDiscount != discount) {
        _cart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: discount);
        _cart.add(newItem);
      } else {
        // نفس الخصم - تحديث مباشر
        _cart[index] = oldItem.copyWith(discount: discount);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// إلغاء الخصم على منتج
  void removeDiscount(String productId) {
    final int index =
        _cart.indexWhere((CartItem element) => element.productId == productId);
    if (index != -1) {
      final CartItem oldItem = _cart[index];
      final int oldDiscount = oldItem.discount;

      // إذا كان هناك خصم، نحذف العنصر القديم ونضيف واحد جديد بدون خصم
      if (oldDiscount > 0) {
        _cart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: 0);
        _cart.add(newItem);
      } else {
        // لا يوجد خصم - تحديث مباشر
        _cart[index] = oldItem.copyWith(discount: 0);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// إلغاء الخصم على عنصر محدد في السلة
  void removeDiscountFromItem(CartItem item) {
    final int index = _cart.indexWhere((CartItem element) =>
        element.productId == item.productId &&
        element.discount == item.discount &&
        element.quantity == item.quantity);

    if (index != -1) {
      final CartItem oldItem = _cart[index];
      final int oldDiscount = oldItem.discount;

      // إذا كان هناك خصم، نحذف العنصر القديم ونضيف واحد جديد بدون خصم
      if (oldDiscount > 0) {
        _cart.removeAt(index);
        final CartItem newItem = oldItem.copyWith(discount: 0);
        _cart.add(newItem);
      } else {
        // لا يوجد خصم - تحديث مباشر
        _cart[index] = oldItem.copyWith(discount: 0);
      }
      notifyListeners();
      _saveCartToStorage(); // حفظ السلة تلقائياً
    }
  }

  /// حساب المبلغ الإجمالي
  int getTotalAmount() => _cart.fold(0, (sum, item) => sum + item.totalPrice);

  /// حساب الربح الإجمالي
  int getTotalProfit() => _cart.fold(0, (sum, item) => sum + item.totalProfit);

  /// حساب الكمية الإجمالية
  int getTotalQuantity() => _cart.fold(0, (sum, item) => sum + item.quantity);

  /// البحث عن عنصر بالمعرف
  CartItem? findItemById(String productId, {int discount = 0}) {
    try {
      return _cart.firstWhere(
          (CartItem item) => item.productId == productId && item.discount == discount);
    } catch (e) {
      return null;
    }
  }
}
