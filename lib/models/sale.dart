import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'cart_item.dart';

/// نموذج عملية البيع
class Sale {
  Sale({
    this.id,
    required this.items,
    required this.totalAmount,
    required this.totalProfit,
    required this.saleDate,
    this.customerName,
    this.notes,
    this.paymentMethod = 'نقدي',
    this.discount = 0,
    this.isSynced = true,
  });

  factory Sale.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final Map<String, dynamic> data = doc.data();
      final List<dynamic> itemsData =
          data['items'] as List<dynamic>? ?? <dynamic>[];
      final List<CartItem> items = itemsData
          .map((item) => CartItem(
                productId: (item['productId'] as String?) ?? '',
                name: (item['name'] as String?) ?? '',
                barcode: (item['barcode'] as String?) ?? '',
                retailPrice: _safeParseInt(item['retailPrice']),
                wholesalePrice: _safeParseInt(item['wholesalePrice']),
                quantity: (item['quantity'] as int?) ?? 0,
              ))
          .toList();

      return Sale(
        id: doc.id,
        items: items,
        totalAmount: (data['totalAmount'] as int?) ?? 0,
        totalProfit: (data['totalProfit'] as int?) ?? 0,
        saleDate: _parseDate(data['saleDate']),
        customerName: data['customerName'] as String?,
        notes: data['notes'] as String?,
        paymentMethod: (data['paymentMethod'] as String?) ?? 'نقدي',
        discount: (data['discount'] as int?) ?? 0,
      );
    } on Exception catch (e) {
      debugPrint('خطأ في إنشاء عملية البيع من Firestore: $e');
      rethrow;
    }
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    try {
      final List<dynamic> itemsData =
          map['items'] as List<dynamic>? ?? <dynamic>[];
      final List<CartItem> items = itemsData
          .map((item) => CartItem(
                productId: (item['productId'] as String?) ?? '',
                name: (item['name'] as String?) ?? '',
                barcode: (item['barcode'] as String?) ?? '',
                retailPrice: _safeParseInt(item['retailPrice']),
                wholesalePrice: _safeParseInt(item['wholesalePrice']),
                quantity: (item['quantity'] as int?) ?? 0,
              ))
          .toList();

      return Sale(
        id: map['id'] as String?,
        items: items,
        totalAmount: (map['totalAmount'] as int?) ?? 0,
        totalProfit: (map['totalProfit'] as int?) ?? 0,
        saleDate: map['saleDate'] is DateTime
            ? map['saleDate'] as DateTime
            : _parseDate(map['saleDate']),
        customerName: map['customerName'] as String?,
        notes: map['notes'] as String?,
        paymentMethod: (map['paymentMethod'] as String?) ?? 'نقدي',
        discount: (map['discount'] as int?) ?? 0,
        isSynced: (map['isSynced'] as bool?) ?? true,
      );
    } on Exception catch (e) {
      debugPrint('خطأ في إنشاء عملية البيع من Map: $e');
      rethrow;
    }
  }

  String? id;
  List<CartItem> items;
  int totalAmount;
  int totalProfit;
  DateTime saleDate;
  String? customerName;
  String? notes;
  String paymentMethod;
  int discount;
  bool isSynced;

  /// حساب إجمالي الكمية المباعة
  int get totalQuantity =>
      items.fold(0, (int sum, CartItem item) => sum + item.quantity);

  /// حساب عدد المنتجات المختلفة
  int get uniqueProductCount => items.length;

  /// حساب المبلغ النهائي بعد الخصم
  int get finalAmount => totalAmount - discount;

  /// التحقق من صحة بيانات عملية البيع
  bool isValid() => items.isNotEmpty && totalAmount > 0;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'items': items.map((CartItem item) => item.toMap()).toList(),
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'saleDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(saleDate),
        'customerName': customerName,
        'notes': notes,
        'paymentMethod': paymentMethod,
        'discount': discount,
        'isSynced': isSynced,
      };

  /// تحليل التاريخ مع معالجة أفضل للأخطاء
  static DateTime _parseDate(Object? date) {
    try {
      if (date is Timestamp) {
        return date.toDate();
      } else if (date is String) {
        if (date.contains('T') && date.contains('Z')) {
          return DateTime.parse(date);
        } else {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(date, true);
        }
      } else if (date is DateTime) {
        return date;
      }
    } on Exception catch (e) {
      debugPrint('خطأ في تحليل تاريخ البيع: $e');
    }
    return DateTime.now();
  }

  /// إنشاء نسخة من عملية البيع مع تحديث القيم المحددة
  Sale copyWith({
    String? id,
    List<CartItem>? items,
    int? totalAmount,
    int? totalProfit,
    DateTime? saleDate,
    String? customerName,
    String? notes,
    String? paymentMethod,
    int? discount,
    bool? isSynced,
  }) =>
      Sale(
        id: id ?? this.id,
        items: items ?? this.items,
        totalAmount: totalAmount ?? this.totalAmount,
        totalProfit: totalProfit ?? this.totalProfit,
        saleDate: saleDate ?? this.saleDate,
        customerName: customerName ?? this.customerName,
        notes: notes ?? this.notes,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        discount: discount ?? this.discount,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  String toString() =>
      'Sale{id: $id, totalAmount: $totalAmount, totalProfit: $totalProfit, itemsCount: ${items.length}}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sale && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// تحويل آمن للقيم إلى int
  static int _safeParseInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
