/// نموذج تقرير المخزون
class InventoryReport {
  const InventoryReport({
    required this.currentInventory,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.expiredProducts,
    required this.inventoryMovement,
    required this.turnoverAnalysis,
    required this.abcAnalysis,
    required this.period,
    required this.totalValue,
    required this.totalProducts,
  });

  factory InventoryReport.fromMap(Map<String, dynamic> map) => InventoryReport(
      currentInventory: List<InventoryItem>.from(
        (map['currentInventory'] as List<dynamic>?)?.map(
                (x) => InventoryItem.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      lowStockProducts: List<LowStockProduct>.from(
        (map['lowStockProducts'] as List<dynamic>?)?.map(
                (x) => LowStockProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      outOfStockProducts: List<OutOfStockProduct>.from(
        (map['outOfStockProducts'] as List<dynamic>?)?.map(
                (x) => OutOfStockProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      expiredProducts: List<ExpiredProduct>.from(
        (map['expiredProducts'] as List<dynamic>?)?.map(
                (x) => ExpiredProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      inventoryMovement: List<InventoryMovement>.from(
        (map['inventoryMovement'] as List<dynamic>?)?.map(
                (x) => InventoryMovement.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      turnoverAnalysis: TurnoverAnalysis.fromMap(
          map['turnoverAnalysis'] as Map<String, dynamic>),
      abcAnalysis:
          ABCAnalysis.fromMap(map['abcAnalysis'] as Map<String, dynamic>),
      period: ReportPeriod.fromMap(map['period'] as Map<String, dynamic>),
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      totalProducts: (map['totalProducts'] as int?) ?? 0,
    );

  final List<InventoryItem> currentInventory;
  final List<LowStockProduct> lowStockProducts;
  final List<OutOfStockProduct> outOfStockProducts;
  final List<ExpiredProduct> expiredProducts;
  final List<InventoryMovement> inventoryMovement;
  final TurnoverAnalysis turnoverAnalysis;
  final ABCAnalysis abcAnalysis;
  final ReportPeriod period;
  final double totalValue;
  final int totalProducts;

  /// حساب عدد المنتجات منخفضة المخزون
  int get lowStockCount => lowStockProducts.length;

  /// حساب عدد المنتجات النافدة
  int get outOfStockCount => outOfStockProducts.length;

  /// حساب عدد المنتجات المنتهية الصلاحية
  int get expiredCount => expiredProducts.length;

  /// حساب متوسط قيمة المخزون
  double get averageInventoryValue {
    if (currentInventory.isEmpty) return 0.0;
    return totalValue / currentInventory.length;
  }

  /// حساب نسبة المنتجات منخفضة المخزون
  double get lowStockPercentage {
    if (totalProducts == 0) return 0.0;
    return (lowStockCount / totalProducts) * 100;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'currentInventory': currentInventory.map((InventoryItem x) => x.toMap()).toList(),
      'lowStockProducts': lowStockProducts.map((LowStockProduct x) => x.toMap()).toList(),
      'outOfStockProducts': outOfStockProducts.map((OutOfStockProduct x) => x.toMap()).toList(),
      'expiredProducts': expiredProducts.map((ExpiredProduct x) => x.toMap()).toList(),
      'inventoryMovement': inventoryMovement.map((InventoryMovement x) => x.toMap()).toList(),
      'turnoverAnalysis': turnoverAnalysis.toMap(),
      'abcAnalysis': abcAnalysis.toMap(),
      'period': period.toMap(),
      'totalValue': totalValue,
      'totalProducts': totalProducts,
    };
}

/// عنصر المخزون
class InventoryItem {
  const InventoryItem({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    required this.unitCost,
    required this.totalValue,
    required this.category,
    required this.supplier,
    required this.lastUpdated,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map) => InventoryItem(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      currentStock: (map['currentStock'] as int?) ?? 0,
      minimumStock: (map['minimumStock'] as int?) ?? 0,
      maximumStock: (map['maximumStock'] as int?) ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      category: (map['category'] as String?) ?? '',
      supplier: (map['supplier'] as String?) ?? '',
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );

  final String productId;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final double unitCost;
  final double totalValue;
  final String category;
  final String supplier;
  final DateTime lastUpdated;

  /// حساب نسبة المخزون
  double get stockPercentage {
    if (maximumStock == 0) return 0.0;
    return (currentStock / maximumStock) * 100;
  }

  /// التحقق من انخفاض المخزون
  bool get isLowStock => currentStock <= minimumStock;

  /// التحقق من نفاد المخزون
  bool get isOutOfStock => currentStock == 0;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'unitCost': unitCost,
      'totalValue': totalValue,
      'category': category,
      'supplier': supplier,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
}

/// منتج مخزون منخفض
class LowStockProduct {
  const LowStockProduct({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.alertLevel,
    required this.daysUntilOutOfStock,
  });

  factory LowStockProduct.fromMap(Map<String, dynamic> map) => LowStockProduct(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      currentStock: (map['currentStock'] as int?) ?? 0,
      minimumStock: (map['minimumStock'] as int?) ?? 0,
      alertLevel: AlertLevel.values.firstWhere(
        (AlertLevel e) => e.name == map['alertLevel'],
        orElse: () => AlertLevel.low,
      ),
      daysUntilOutOfStock: (map['daysUntilOutOfStock'] as int?) ?? 0,
    );

  final String productId;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final AlertLevel alertLevel;
  final int daysUntilOutOfStock;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'alertLevel': alertLevel.name,
      'daysUntilOutOfStock': daysUntilOutOfStock,
    };
}

/// منتج نافد
class OutOfStockProduct {
  const OutOfStockProduct({
    required this.productId,
    required this.productName,
    required this.lastStockDate,
    required this.daysOutOfStock,
    required this.estimatedRestockDate,
  });

  factory OutOfStockProduct.fromMap(Map<String, dynamic> map) => OutOfStockProduct(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      lastStockDate: DateTime.parse(map['lastStockDate'] as String),
      daysOutOfStock: (map['daysOutOfStock'] as int?) ?? 0,
      estimatedRestockDate: map['estimatedRestockDate'] != null
          ? DateTime.parse(map['estimatedRestockDate'] as String)
          : null,
    );

  final String productId;
  final String productName;
  final DateTime lastStockDate;
  final int daysOutOfStock;
  final DateTime? estimatedRestockDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'lastStockDate': lastStockDate.toIso8601String(),
      'daysOutOfStock': daysOutOfStock,
      'estimatedRestockDate': estimatedRestockDate?.toIso8601String(),
    };
}

/// منتج منتهي الصلاحية
class ExpiredProduct {
  const ExpiredProduct({
    required this.productId,
    required this.productName,
    required this.expiryDate,
    required this.daysExpired,
    required this.quantity,
    required this.value,
  });

  factory ExpiredProduct.fromMap(Map<String, dynamic> map) => ExpiredProduct(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      expiryDate: DateTime.parse(map['expiryDate'] as String),
      daysExpired: (map['daysExpired'] as int?) ?? 0,
      quantity: (map['quantity'] as int?) ?? 0,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
    );

  final String productId;
  final String productName;
  final DateTime expiryDate;
  final int daysExpired;
  final int quantity;
  final double value;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'expiryDate': expiryDate.toIso8601String(),
      'daysExpired': daysExpired,
      'quantity': quantity,
      'value': value,
    };
}

/// حركة المخزون
class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.quantity,
    required this.unitCost,
    required this.totalValue,
    required this.date,
    required this.employeeId,
    required this.notes,
  });

  factory InventoryMovement.fromMap(Map<String, dynamic> map) => InventoryMovement(
      id: (map['id'] as String?) ?? '',
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      movementType: MovementType.values.firstWhere(
        (MovementType e) => e.name == map['movementType'],
        orElse: () => MovementType.inStock,
      ),
      quantity: (map['quantity'] as int?) ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0.0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      employeeId: (map['employeeId'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
    );

  final String id;
  final String productId;
  final String productName;
  final MovementType movementType;
  final int quantity;
  final double unitCost;
  final double totalValue;
  final DateTime date;
  final String employeeId;
  final String notes;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'productId': productId,
      'productName': productName,
      'movementType': movementType.name,
      'quantity': quantity,
      'unitCost': unitCost,
      'totalValue': totalValue,
      'date': date.toIso8601String(),
      'employeeId': employeeId,
      'notes': notes,
    };
}

/// تحليل معدل الدوران
class TurnoverAnalysis {
  const TurnoverAnalysis({
    required this.overallTurnoverRate,
    required this.productTurnoverRates,
    required this.slowMovingProducts,
    required this.fastMovingProducts,
    required this.averageTurnoverRate,
  });

  factory TurnoverAnalysis.fromMap(Map<String, dynamic> map) => TurnoverAnalysis(
      overallTurnoverRate:
          (map['overallTurnoverRate'] as num?)?.toDouble() ?? 0.0,
      productTurnoverRates: List<ProductTurnoverRate>.from(
        (map['productTurnoverRates'] as List<dynamic>?)?.map((x) =>
                ProductTurnoverRate.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      slowMovingProducts: List<SlowMovingProduct>.from(
        (map['slowMovingProducts'] as List<dynamic>?)?.map(
                (x) => SlowMovingProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      fastMovingProducts: List<FastMovingProduct>.from(
        (map['fastMovingProducts'] as List<dynamic>?)?.map(
                (x) => FastMovingProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      averageTurnoverRate:
          (map['averageTurnoverRate'] as num?)?.toDouble() ?? 0.0,
    );

  final double overallTurnoverRate;
  final List<ProductTurnoverRate> productTurnoverRates;
  final List<SlowMovingProduct> slowMovingProducts;
  final List<FastMovingProduct> fastMovingProducts;
  final double averageTurnoverRate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'overallTurnoverRate': overallTurnoverRate,
      'productTurnoverRates':
          productTurnoverRates.map((ProductTurnoverRate x) => x.toMap()).toList(),
      'slowMovingProducts': slowMovingProducts.map((SlowMovingProduct x) => x.toMap()).toList(),
      'fastMovingProducts': fastMovingProducts.map((FastMovingProduct x) => x.toMap()).toList(),
      'averageTurnoverRate': averageTurnoverRate,
    };
}

/// معدل دوران المنتج
class ProductTurnoverRate {
  const ProductTurnoverRate({
    required this.productId,
    required this.productName,
    required this.turnoverRate,
    required this.rank,
  });

  factory ProductTurnoverRate.fromMap(Map<String, dynamic> map) => ProductTurnoverRate(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      turnoverRate: (map['turnoverRate'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as int?) ?? 0,
    );

  final String productId;
  final String productName;
  final double turnoverRate;
  final int rank;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'turnoverRate': turnoverRate,
      'rank': rank,
    };
}

/// منتج بطيء الحركة
class SlowMovingProduct {
  const SlowMovingProduct({
    required this.productId,
    required this.productName,
    required this.turnoverRate,
    required this.daysInStock,
  });

  factory SlowMovingProduct.fromMap(Map<String, dynamic> map) => SlowMovingProduct(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      turnoverRate: (map['turnoverRate'] as num?)?.toDouble() ?? 0.0,
      daysInStock: (map['daysInStock'] as int?) ?? 0,
    );

  final String productId;
  final String productName;
  final double turnoverRate;
  final int daysInStock;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'turnoverRate': turnoverRate,
      'daysInStock': daysInStock,
    };
}

/// منتج سريع الحركة
class FastMovingProduct {
  const FastMovingProduct({
    required this.productId,
    required this.productName,
    required this.turnoverRate,
    required this.rank,
  });

  factory FastMovingProduct.fromMap(Map<String, dynamic> map) => FastMovingProduct(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      turnoverRate: (map['turnoverRate'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as int?) ?? 0,
    );

  final String productId;
  final String productName;
  final double turnoverRate;
  final int rank;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'turnoverRate': turnoverRate,
      'rank': rank,
    };
}

/// تحليل ABC
class ABCAnalysis {
  const ABCAnalysis({
    required this.categoryA,
    required this.categoryB,
    required this.categoryC,
    required this.totalValue,
  });

  factory ABCAnalysis.fromMap(Map<String, dynamic> map) => ABCAnalysis(
      categoryA: List<ABCProduct>.from(
        (map['categoryA'] as List<dynamic>?)
                ?.map((x) => ABCProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      categoryB: List<ABCProduct>.from(
        (map['categoryB'] as List<dynamic>?)
                ?.map((x) => ABCProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      categoryC: List<ABCProduct>.from(
        (map['categoryC'] as List<dynamic>?)
                ?.map((x) => ABCProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
    );

  final List<ABCProduct> categoryA;
  final List<ABCProduct> categoryB;
  final List<ABCProduct> categoryC;
  final double totalValue;

  /// حساب نسبة الفئة A
  double get categoryAPercentage {
    if (totalValue == 0) return 0.0;
    final double categoryAValue =
        categoryA.fold(0.0, (double sum, ABCProduct product) => sum + product.value);
    return (categoryAValue / totalValue) * 100;
  }

  /// حساب نسبة الفئة B
  double get categoryBPercentage {
    if (totalValue == 0) return 0.0;
    final double categoryBValue =
        categoryB.fold(0.0, (double sum, ABCProduct product) => sum + product.value);
    return (categoryBValue / totalValue) * 100;
  }

  /// حساب نسبة الفئة C
  double get categoryCPercentage {
    if (totalValue == 0) return 0.0;
    final double categoryCValue =
        categoryC.fold(0.0, (double sum, ABCProduct product) => sum + product.value);
    return (categoryCValue / totalValue) * 100;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'categoryA': categoryA.map((ABCProduct x) => x.toMap()).toList(),
      'categoryB': categoryB.map((ABCProduct x) => x.toMap()).toList(),
      'categoryC': categoryC.map((ABCProduct x) => x.toMap()).toList(),
      'totalValue': totalValue,
    };
}

/// منتج تحليل ABC
class ABCProduct {
  const ABCProduct({
    required this.productId,
    required this.productName,
    required this.value,
    required this.percentage,
    required this.category,
  });

  factory ABCProduct.fromMap(Map<String, dynamic> map) => ABCProduct(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      category: ABCCategory.values.firstWhere(
        (ABCCategory e) => e.name == map['category'],
        orElse: () => ABCCategory.c,
      ),
    );

  final String productId;
  final String productName;
  final double value;
  final double percentage;
  final ABCCategory category;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'value': value,
      'percentage': percentage,
      'category': category.name,
    };
}

/// فترة التقرير
class ReportPeriod {
  const ReportPeriod({
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  factory ReportPeriod.fromMap(Map<String, dynamic> map) => ReportPeriod(
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      type: PeriodType.values.firstWhere(
        (PeriodType e) => e.name == map['type'],
        orElse: () => PeriodType.custom,
      ),
    );

  final DateTime startDate;
  final DateTime endDate;
  final PeriodType type;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.name,
    };
}

/// مستوى التنبيه
enum AlertLevel {
  low,
  critical,
  outOfStock,
}

/// نوع الحركة
enum MovementType {
  inStock,
  outStock,
  adjustment,
  transfer,
}

/// فئة ABC
enum ABCCategory {
  a,
  b,
  c,
}

/// نوع الفترة
enum PeriodType {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}
