import 'package:intl/intl.dart';

/// نموذج عنصر المخزون مع معالجة محسنة للأخطاء
class InventoryItem {
  // تاريخ انتهاء الصلاحية (اختياري)

  InventoryItem({
    this.id,
    required this.name,
    this.barcode,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.quantity,
    required this.originalQuantity,
    required this.addedDate,
    required this.addedTime,
    this.expiryDate,
    this.lastModified,
  });

  // تم نقل دالة fromMap إلى DataConversionService
  // لمركزية تحويل البيانات
  String? id;
  String name;
  String? barcode;
  int wholesalePrice;
  int retailPrice;
  int quantity;
  int originalQuantity;
  DateTime addedDate;
  DateTime addedTime;
  DateTime? expiryDate;
  DateTime? lastModified;

  /// التحقق من صحة بيانات عنصر المخزون
  bool isValid() =>
      name.isNotEmpty &&
      wholesalePrice >= 0 &&
      retailPrice >= 0 &&
      quantity >= 0 &&
      originalQuantity >= 0;

  /// التحقق من نفاد الكمية
  bool isOutOfStock() => quantity == 0;

  /// الحصول على نص الكمية للعرض
  String getQuantityDisplayText() =>
      isOutOfStock() ? 'نفذت الكمية' : quantity.toString();

  /// حساب القيمة الإجمالية للمخزون
  int getTotalValue() => wholesalePrice * (isOutOfStock() ? 0 : quantity);

  /// إنشاء نسخة من عنصر المخزون مع تحديث الكمية
  InventoryItem copyWith({
    String? id,
    String? name,
    String? barcode,
    int? wholesalePrice,
    int? retailPrice,
    int? quantity,
    int? originalQuantity,
    DateTime? addedDate,
    DateTime? addedTime,
    DateTime? expiryDate,
  }) =>
      InventoryItem(
        id: id ?? this.id,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        wholesalePrice: wholesalePrice ?? this.wholesalePrice,
        retailPrice: retailPrice ?? this.retailPrice,
        quantity: quantity ?? this.quantity,
        originalQuantity: originalQuantity ?? this.originalQuantity,
        addedDate: addedDate ?? this.addedDate,
        addedTime: addedTime ?? this.addedTime,
        expiryDate: expiryDate ?? this.expiryDate,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name.trim(),
        'barcode': barcode,
        'wholesalePrice': wholesalePrice,
        'retailPrice': retailPrice,
        'quantity': quantity,
        'originalQuantity': originalQuantity,
        'addedDate': DateFormat('yyyy-MM-dd').format(addedDate),
        'addedTime': DateFormat('HH:mm:ss').format(addedTime),
        'expiryDate': expiryDate != null
            ? DateFormat('yyyy-MM-dd').format(expiryDate!)
            : null,
        'lastModified': (lastModified ?? DateTime.now()).toIso8601String(),
      };

  // تم نقل _parseInt إلى DataConversionService

  // تم نقل جميع دوال التحليل إلى DataConversionService
  // لمركزية تحويل البيانات

  @override
  String toString() =>
      'InventoryItem{id: $id, name: $name, wholesalePrice: $wholesalePrice, quantity: $quantity, expiryDate: $expiryDate}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Getters للتنسيق
  String get formattedAddedDate => DateFormat('yyyy/MM/dd').format(addedDate);
  String get formattedExpiryDate =>
      expiryDate != null ? DateFormat('yyyy/MM/dd').format(expiryDate!) : 'N/A';
}
