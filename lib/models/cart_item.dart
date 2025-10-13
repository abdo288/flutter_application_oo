import 'inventory_item.dart';
import 'product.dart';

/// نموذج عنصر سلة التسوق
class CartItem {
  CartItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.retailPrice,
    required this.quantity,
    this.wholesalePrice = 0,
    this.discount = 0,
  });

  factory CartItem.fromInventoryItem(InventoryItem inventoryItem,
          {int quantity = 1, int discount = 0}) =>
      CartItem(
        productId: inventoryItem.id ?? '',
        name: inventoryItem.name,
        barcode: inventoryItem.barcode ?? '',
        retailPrice: inventoryItem.retailPrice, // استخدام سعر التجزئة
        wholesalePrice: inventoryItem.wholesalePrice,
        quantity: quantity,
        discount: discount,
      );

  factory CartItem.fromProduct(Product product,
          {int quantity = 1, int discount = 0}) =>
      CartItem(
        productId: product.id ?? '',
        name: product.name,
        barcode: product.barcode ?? '', // استخدام باركود المنتج
        retailPrice: product.retailPrice,
        wholesalePrice: product.wholesalePrice,
        quantity: quantity,
        discount: discount,
      );

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
        productId: map['productId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        barcode: map['barcode'] as String? ?? '',
        retailPrice: map['retailPrice'] as int? ?? 0,
        wholesalePrice: map['wholesalePrice'] as int? ?? 0,
        quantity: map['quantity'] as int? ?? 1,
        discount: map['discount'] as int? ?? 0,
      );

  String productId;
  String name;
  String barcode;
  int retailPrice;
  int wholesalePrice;
  int quantity;
  int discount;

  /// السعر بعد الخصم (خصم من السعر الفردي)
  int get discountedPrice => retailPrice - discount;

  /// السعر الإجمالي قبل الخصم
  int get totalRetailPrice => retailPrice * quantity;

  /// حساب السعر الإجمالي للعنصر (خصم من المجموع الإجمالي)
  int get totalPrice => (retailPrice * quantity) - discount;

  /// حساب الربح الإجمالي للعنصر (بعد الخصم من المجموع)
  int get totalProfit => totalPrice - (wholesalePrice * quantity);

  /// إنشاء نسخة من عنصر السلة مع تحديث الكمية
  CartItem copyWith({
    String? productId,
    String? name,
    String? barcode,
    int? retailPrice,
    int? wholesalePrice,
    int? quantity,
    int? discount,
  }) =>
      CartItem(
        productId: productId ?? this.productId,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        retailPrice: retailPrice ?? this.retailPrice,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        quantity: quantity ?? this.quantity,
        discount: discount ?? this.discount,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'productId': productId,
        'name': name,
        'barcode': barcode,
        'retailPrice': retailPrice,
        'wholesalePrice': wholesalePrice,
        'quantity': quantity,
        'discount': discount,
      };

  @override
  String toString() =>
      'CartItem{productId: $productId, name: $name, quantity: $quantity, totalPrice: $totalPrice}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}
