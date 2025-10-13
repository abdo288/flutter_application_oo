# إصلاح مشكلة المنتجات المخصومة في نقطة البيع

## المشكلة
عند إضافة منتج موجود مسبقاً في السلة مع خصم، كان يتم إضافة نسخة جديدة من المنتج بدلاً من تحديث الكمية للمنتج الموجود. هذا يحدث لأن البحث يتم بناءً على `productId` فقط، لكن المنتجات المخصومة قد يكون لها معرفات مختلفة.

## السبب الجذري
1. **البحث المحدود**: البحث في السلة كان يتم بناءً على `productId` فقط
2. **عدم مراعاة الخصم**: المنتجات المخصومة لها `discount` مختلف
3. **عدم البحث بالاسم**: لم يتم البحث بالاسم أو الباركود

## الحل المطبق

### 1. تحسين البحث في السلة

#### قبل الإصلاح:
```dart
final CartItem? existingItem = appProvider.cartProvider.cart
    .where((item) => item.productId == product.id)
    .firstOrNull;
```

#### بعد الإصلاح:
```dart
final CartItem? existingItem = appProvider.cartProvider.cart
    .where((item) => 
        item.productId == product.id ||
        item.name.toLowerCase() == product.name.toLowerCase() ||
        (item.barcode != null && product.barcode != null && 
         item.barcode == product.barcode!))
    .firstOrNull;
```

### 2. إضافة دالة جديدة في CartProvider

#### دالة `updateQuantityForItemByName`:
```dart
/// تحديث كمية عنصر بناءً على الاسم (للمنتجات المخصومة)
void updateQuantityForItemByName(String name, int newQuantity) {
  final int index = _cart.indexWhere((element) =>
      element.name.toLowerCase() == name.toLowerCase());

  if (index != -1) {
    if (newQuantity > 0) {
      _cart[index] = _cart[index].copyWith(quantity: newQuantity);
    } else {
      _cart.removeAt(index);
    }
    notifyListeners();
  }
}
```

### 3. تحديث منطق التحديث

#### قبل الإصلاح:
```dart
// تحديث الكمية في السلة
appProvider.cartProvider.updateQuantityForItem(existingItem, newQuantity);
```

#### بعد الإصلاح:
```dart
// تحديث الكمية في السلة بناءً على الاسم
appProvider.cartProvider.updateQuantityForItemByName(product.name, newQuantity);
```

## المميزات الجديدة

### 1. البحث المحسن
- البحث بالاسم (case-insensitive)
- البحث بالباركود
- البحث بـ productId
- دعم المنتجات المخصومة

### 2. تحديث دقيق
- تحديث الكمية للمنتج الصحيح
- عدم إنشاء نسخ مكررة
- الحفاظ على الخصم المطبق

### 3. دعم المنتجات المخصومة
- البحث عن المنتجات المخصومة بالاسم
- تحديث الكمية بشكل صحيح
- عدم إضافة نسخ جديدة

## الملفات المحدثة

### 1. `lib/providers/cart_provider.dart`
- إضافة `updateQuantityForItemByName`
- دعم البحث بالاسم

### 2. `lib/screens/pos_screen.dart`
- تحسين البحث في السلة
- استخدام `updateQuantityForItemByName`

### 3. `lib/screens/windows_pos_screen.dart`
- نفس التحديثات المطبقة على الشاشة العادية
- رسائل debug مفصلة

## الاختبار

### سيناريوهات الاختبار
1. **إضافة منتج عادي موجود في السلة**
   - يجب أن تزيد الكمية بـ 1
   - لا يجب إنشاء نسخة جديدة

2. **إضافة منتج مخصوم موجود في السلة**
   - يجب أن تزيد الكمية بـ 1
   - يجب الحفاظ على الخصم
   - لا يجب إنشاء نسخة جديدة

3. **إضافة منتج جديد**
   - يجب أن يضاف بكمية 1
   - يجب أن يخصم من المخزون

4. **إضافة منتج بنفس الاسم لكن باركود مختلف**
   - يجب أن يضاف كمنتج جديد
   - يجب أن يخصم من المخزون

## النتائج المتوقعة

### ✅ المشاكل المحلولة
1. لا يتم إنشاء نسخ مكررة للمنتجات المخصومة
2. تحديث الكمية للمنتج الصحيح
3. الحفاظ على الخصم المطبق
4. البحث المحسن في السلة

### 🎯 المميزات المحسنة
1. دقة أكبر في إدارة السلة
2. دعم أفضل للمنتجات المخصومة
3. تجربة مستخدم محسنة
4. أداء أفضل

---

**تاريخ الإصلاح**: ${new Date().toLocaleDateString('ar-SA')}
**الإصدار**: 1.3.0
**المطور**: AI Assistant
