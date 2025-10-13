<!-- c723587b-87b9-42d1-969c-c9d9c100c162 a8654427-cb19-42d6-bd5d-10fc29c41534 -->
# Fix POS Cart Items Disappearing Issue

## Problem Analysis

نقطة البيع (POS) تفقد عناصر السلة عند:

1. التنقل بين التبويبات (tabs)
2. حدوث Windows periodic sync (كل 3 ثوان)
3. تحديث الشاشة

**السبب الجذري:**

- Windows periodic sync يحدث كل 3 ثوان ويؤدي إلى `notifyListeners()` في Providers
- هذا يسبب rebuild للـ widget tree
- حتى مع `AutomaticKeepAliveClientMixin`، قد تفقد السلة حالتها إذا كان parent widget يتم rebuild
- السلة مخزنة حاليًا في widget state: `final List<CartItem> _cart = <CartItem>[];`

## Solution: Create Dedicated CartProvider

### Implementation Steps

#### Step 1: Create CartProvider

**File: `lib/providers/cart_provider.dart`** (new file)

```dart
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cart = <CartItem>[];
  
  List<CartItem> get cart => _cart;
  bool get isEmpty => _cart.isEmpty;
  int get itemCount => _cart.length;
  
  // Calculate total amount
  int getTotalAmount() => _cart.fold(0, (sum, item) => sum + item.totalPrice);
  
  // Calculate total profit
  int getTotalProfit() => _cart.fold(0, (sum, item) => sum + item.totalProfit);
  
  // Add item to cart
  void addItem(CartItem item) {
    final existingIndex = _cart.indexWhere((i) => i.productId == item.productId);
    if (existingIndex != -1) {
      _cart[existingIndex] = item;
    } else {
      _cart.add(item);
    }
    notifyListeners();
  }
  
  // Update item quantity
  void updateQuantity(String productId, int quantity) {
    final index = _cart.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index] = _cart[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }
  
  // Remove item
  void removeItem(String productId) {
    _cart.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }
  
  // Clear cart
  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
  
  // Apply discount
  void applyDiscount(String productId, int discount) {
    final index = _cart.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      _cart[index] = _cart[index].copyWith(discount: discount);
      notifyListeners();
    }
  }
}
```

#### Step 2: Register CartProvider in StreamAppProvider

**File: `lib/providers/stream_app_provider.dart`**

Add CartProvider as a field and getter:

```dart
class StreamAppProvider with ChangeNotifier {
  // ... existing code ...
  
  final CartProvider _cartProvider = CartProvider();  // ADD
  
  CartProvider get cartProvider => _cartProvider;  // ADD
  
  // ... rest of code ...
}
```

#### Step 3: Update POSScreen to use CartProvider

**File: `lib/screens/pos_screen.dart`**

Replace local `_cart` with `cartProvider`:

- Remove: `final List<CartItem> _cart = <CartItem>[];`
- Use: `context.read<StreamAppProvider>().cartProvider`
- Update all `_cart` references to use `cartProvider.cart`
- Update methods to use CartProvider methods

#### Step 4: Update WindowsPOSScreen to use CartProvider  

**File: `lib/screens/windows_pos_screen.dart`**

Same changes as POSScreen

## Key Changes Summary

### What Changes:

1. ✅ Create new `CartProvider` class
2. ✅ Add `CartProvider` to `StreamAppProvider`
3. ✅ Update `POSScreen` to use `cartProvider` instead of local `_cart`
4. ✅ Update `WindowsPOSScreen` to use `cartProvider` instead of local `_cart`

### What Stays the Same:

- ❌ NO changes to periodic sync (stays at 3 seconds)
- ❌ NO changes to `AutomaticKeepAliveClientMixin`
- ❌ NO changes to sync logic

## Benefits

- 🔒 Cart state persists across tab switches
- 🔒 Cart state survives widget rebuilds
- 🔒 Cart state independent of periodic sync
- 📦 Better architecture - separation of concerns
- ♻️ Reusable cart logic

### To-dos

- [ ] Create new CartProvider class in lib/providers/cart_provider.dart
- [ ] Register CartProvider in StreamAppProvider
- [ ] Update POSScreen to use CartProvider instead of local _cart
- [ ] Update WindowsPOSScreen to use CartProvider instead of local _cart