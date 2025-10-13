# Product List with POS Tab

## نظرة عامة
هذا التبويب المدمج يجمع بين عرض المنتجات ونقطة البيع في واجهة واحدة موحدة، مما يوفر تجربة مستخدم محسنة وكفاءة أكبر في إدارة المبيعات.

## الميزات الرئيسية

### 1. عرض المنتجات
- **عرض شبكي وقائمة**: إمكانية التبديل بين عرض الشبكة والقائمة
- **البحث والفلترة**: بحث سريع في المنتجات مع فلاتر متقدمة
- **الترتيب**: ترتيب المنتجات حسب الاسم، السعر، الربح، أو التاريخ
- **الإحصائيات السريعة**: عرض إجمالي المنتجات والقيمة ومتوسط الربح

### 2. نقطة البيع (POS)
- **السلة الذكية**: إضافة المنتجات للسلة مع إدارة الكميات
- **مسح الباركود**: ماسح باركود مدمج لإضافة المنتجات بسرعة
- **البيع السريع**: بيع مباشر للمنتجات مع تحديد الكمية
- **إتمام البيع**: معالجة كاملة للبيع مع تفاصيل العميل والخصم

### 3. واجهة المستخدم
- **تصميم متجاوب**: يتكيف مع أحجام الشاشات المختلفة
- **ألوان تفاعلية**: تغيير الألوان حسب حالة العناصر
- **تأثيرات بصرية**: انيميشن وتأثيرات لتحسين التجربة
- **سهولة الاستخدام**: واجهة بديهية مع أزرار واضحة

## هيكل الملفات

```
lib/screens/product_list_pos/
├── enums.dart                    # التعدادات (SortOption, FilterOption, etc.)
├── product_card_with_pos.dart    # بطاقة المنتج مع وظائف POS
├── cart_widgets.dart            # مكونات السلة والدفع
├── search_and_filter_widgets.dart # مكونات البحث والفلترة
├── barcode_scanner_widget.dart  # مكون مسح الباركود
├── quick_sell_widget.dart       # مكون البيع السريع
├── product_list_pos_service.dart # خدمات إدارة البيانات
├── product_list_with_pos_tab.dart # الملف الرئيسي
└── README.md                    # هذا الملف
```

## الاستخدام

### إضافة منتج للسلة
```dart
// من بطاقة المنتج
ProductCardWithPOS(
  product: product,
  onAddToCart: () => _addProductToCart(product),
  // ...
)

// من مسح الباركود
BarcodeScannerWidget(
  onBarcodeScanned: (barcode) => _handleBarcodeScanned(barcode),
)
```

### البيع السريع
```dart
QuickSellWidget(
  product: product,
  onQuickSell: (product, quantity) => _handleQuickSell(product, quantity),
)
```

### إدارة السلة
```dart
CartItemWidget(
  cartItem: cartItem,
  onUpdateQuantity: (quantity) => _updateQuantity(quantity),
  onRemove: () => _removeFromCart(),
)
```

## الخدمات

### ProductListPOSService
- `addProductToCart()`: إضافة منتج للسلة
- `updateCartItemQuantity()`: تحديث كمية عنصر في السلة
- `removeFromCart()`: حذف عنصر من السلة
- `clearCart()`: مسح السلة بالكامل
- `completeSale()`: إتمام عملية البيع
- `sortProducts()`: ترتيب المنتجات
- `filterProducts()`: فلترة المنتجات
- `searchProducts()`: البحث في المنتجات

## التعدادات (Enums)

### SortOption
- `nameAsc`, `nameDesc`: ترتيب حسب الاسم
- `priceAsc`, `priceDesc`: ترتيب حسب السعر
- `profitAsc`, `profitDesc`: ترتيب حسب الربح
- `dateAsc`, `dateDesc`: ترتيب حسب التاريخ

### FilterOption
- `all`: جميع المنتجات
- `highProfit`: منتجات ربح عالي
- `lowProfit`: منتجات ربح منخفض
- `recent`: منتجات حديثة
- `old`: منتجات قديمة

### ViewMode
- `grid`: عرض شبكي
- `list`: عرض قائمة

### PaymentMethod
- `cash`: نقدي
- `card`: بطاقة
- `bankTransfer`: تحويل بنكي

## التخصيص

يمكن تخصيص التبويب من خلال:

1. **تعديل الألوان**: في `AppConstants`
2. **إضافة فلاتر جديدة**: في `FilterOption` enum
3. **تخصيص المكونات**: تعديل الملفات المنفصلة
4. **إضافة خدمات جديدة**: في `ProductListPOSService`

## الأداء

- **تحميل تدريجي**: تحميل المنتجات بشكل تدريجي
- **ذاكرة محسنة**: إدارة فعالة للذاكرة
- **استجابة سريعة**: واجهة مستخدم سريعة الاستجابة
- **كود منظم**: هيكل ملفات منظم للصيانة السهلة

## الدعم

للمساعدة أو الإبلاغ عن مشاكل، يرجى مراجعة:
- ملفات السجل
- رسائل الخطأ في وحدة التحكم
- وثائق Flutter الرسمية
