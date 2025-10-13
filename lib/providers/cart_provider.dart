import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// مقدم خدمة السلة - يدير حالة السلة بشكل مركزي
class CartProvider with ChangeNotifier {
  final List<CartItem> _cart = <CartItem>[];

  /// الحصول على نسخة غير قابلة للتعديل من السلة
  List<CartItem> get cart => List<CartItem>.unmodifiable(_cart);

  /// التحقق من أن السلة فارغة
  bool get isEmpty => _cart.isEmpty;

  /// التحقق من أن السلة غير فارغة
  bool get isNotEmpty => _cart.isNotEmpty;

  /// عدد العناصر في السلة
  int get itemCount => _cart.length;

  /// إضافة عنصر إلى السلة
  void addItem(CartItem item) {
    // ✅ البحث عن منتج بنفس productId و نفس الخصم
    final int index = _cart.indexWhere((element) =>
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
  }

  /// تحديث كمية منتج في السلة
  void updateQuantity(String productId, int newQuantity, {int discount = 0}) {
    final int index = _cart.indexWhere((element) =>
        element.productId == productId && element.discount == discount);
    if (index != -1) {
      if (newQuantity > 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// تحديث كمية عنصر محدد في السلة
  void updateQuantityForItem(CartItem item, int newQuantity) {
    final int index = _cart.indexWhere((element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      if (newQuantity > 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    } else {
      // إذا لم يتم العثور على العنصر، جرب البحث بالباركود
      final int barcodeIndex = _cart.indexWhere((element) =>
          element.barcode == item.barcode && element.discount == item.discount);

      if (barcodeIndex != -1) {
        if (newQuantity > 0) {
          _cart[barcodeIndex] =
              _cart[barcodeIndex].copyWith(quantity: newQuantity);
        } else {
          _cart.removeAt(barcodeIndex);
        }
        notifyListeners();
      }
    }
  }

  /// تحديث كمية عنصر بناءً على الاسم (للمنتجات المخصومة)
  void updateQuantityForItemByName(String name, int newQuantity) {
    final int index = _cart.indexWhere(
        (element) => element.name.toLowerCase() == name.toLowerCase());

    if (index != -1) {
      if (newQuantity > 0) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
      } else {
        _cart.removeAt(index);
      }
      notifyListeners();
    }
  }

  /// حذف عنصر من السلة
  void removeItem(String productId, {int discount = 0}) {
    _cart.removeWhere((element) =>
        element.productId == productId && element.discount == discount);
    notifyListeners();
  }

  /// حذف عنصر محدد من السلة
  void removeItemByObject(CartItem item) {
    final int index = _cart.indexWhere((element) =>
        element.productId == item.productId &&
        element.discount == item.discount);

    if (index != -1) {
      _cart.removeAt(index);
      notifyListeners();
    } else {
      // إذا لم يتم العثور على العنصر، جرب البحث بالباركود
      final int barcodeIndex = _cart.indexWhere((element) =>
          element.barcode == item.barcode && element.discount == item.discount);

      if (barcodeIndex != -1) {
        _cart.removeAt(barcodeIndex);
        notifyListeners();
      }
    }
  }

  /// مسح السلة بالكامل
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  /// تطبيق خصم على منتج
  void applyDiscount(String productId, int discount) {
    final int index =
        _cart.indexWhere((element) => element.productId == productId);
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
    }
  }

  /// تطبيق خصم على عنصر محدد في السلة
  void applyDiscountToItem(CartItem item, int discount) {
    final int index = _cart.indexWhere((element) =>
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
    }
  }

  /// إلغاء الخصم على منتج
  void removeDiscount(String productId) {
    final int index =
        _cart.indexWhere((element) => element.productId == productId);
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
    }
  }

  /// إلغاء الخصم على عنصر محدد في السلة
  void removeDiscountFromItem(CartItem item) {
    final int index = _cart.indexWhere((element) =>
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
    }
  }

  /// حساب المبلغ الإجمالي
  int getTotalAmount() {
    return _cart.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// حساب الربح الإجمالي
  int getTotalProfit() {
    return _cart.fold(0, (sum, item) => sum + item.totalProfit);
  }

  /// حساب الكمية الإجمالية
  int getTotalQuantity() {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }

  /// البحث عن عنصر بالمعرف
  CartItem? findItemById(String productId, {int discount = 0}) {
    try {
      return _cart.firstWhere(
          (item) => item.productId == productId && item.discount == discount);
    } catch (e) {
      return null;
    }
  }
}
