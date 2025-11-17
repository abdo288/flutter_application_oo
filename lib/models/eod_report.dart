/// نموذج تقرير نهاية اليوم
class EODReport {
  const EODReport({
    required this.id,
    required this.reportNumber,
    required this.date,
    required this.generatedAt,
    required this.totalSales,
    required this.totalProfit,
    required this.totalItemsSold,
    required this.uniqueProducts,
    required this.topProducts,
    required this.lowStockProducts,
    required this.totalProductsInStock,
    required this.employeeId,
    required this.employeeName,
    this.isSynced = false,
    this.syncedAt,
  });

  factory EODReport.fromMap(Map<String, dynamic> map) => EODReport(
      id: (map['id'] as String?) ?? '',
      reportNumber: (map['reportNumber'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
      generatedAt: DateTime.parse(map['generatedAt'] as String),
      totalSales: (map['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['totalProfit'] as num?)?.toDouble() ?? 0.0,
      totalItemsSold: (map['totalItemsSold'] as int?) ?? 0,
      uniqueProducts: (map['uniqueProducts'] as int?) ?? 0,
      topProducts: List<TopProduct>.from(
        (map['topProducts'] as List<dynamic>?)
                ?.map((x) => TopProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      lowStockProducts: List<LowStockProduct>.from(
        (map['lowStockProducts'] as List<dynamic>?)?.map(
                (x) => LowStockProduct.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      totalProductsInStock: (map['totalProductsInStock'] as int?) ?? 0,
      employeeId: (map['employeeId'] as String?) ?? '',
      employeeName: (map['employeeName'] as String?) ?? '',
      isSynced: (map['isSynced'] as bool?) ?? false,
      syncedAt: map['syncedAt'] != null
          ? DateTime.parse(map['syncedAt'] as String)
          : null,
    );

  final String id;
  final String reportNumber; // "EOD-2025-01-19-001"
  final DateTime date;
  final DateTime generatedAt;

  // المبيعات
  final double totalSales;
  final double totalProfit;
  final int totalItemsSold;
  final int uniqueProducts;

  // أفضل المنتجات
  final List<TopProduct> topProducts;

  // المخزون
  final List<LowStockProduct> lowStockProducts;
  final int totalProductsInStock;

  // معلومات إضافية
  final String employeeId;
  final String employeeName;
  final bool isSynced;
  final DateTime? syncedAt;

  EODReport copyWith({
    String? id,
    String? reportNumber,
    DateTime? date,
    DateTime? generatedAt,
    double? totalSales,
    double? totalProfit,
    int? totalItemsSold,
    int? uniqueProducts,
    List<TopProduct>? topProducts,
    List<LowStockProduct>? lowStockProducts,
    int? totalProductsInStock,
    String? employeeId,
    String? employeeName,
    bool? isSynced,
    DateTime? syncedAt,
  }) => EODReport(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      date: date ?? this.date,
      generatedAt: generatedAt ?? this.generatedAt,
      totalSales: totalSales ?? this.totalSales,
      totalProfit: totalProfit ?? this.totalProfit,
      totalItemsSold: totalItemsSold ?? this.totalItemsSold,
      uniqueProducts: uniqueProducts ?? this.uniqueProducts,
      topProducts: topProducts ?? this.topProducts,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      totalProductsInStock: totalProductsInStock ?? this.totalProductsInStock,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
    );

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'reportNumber': reportNumber,
      'date': date.toIso8601String(),
      'generatedAt': generatedAt.toIso8601String(),
      'totalSales': totalSales,
      'totalProfit': totalProfit,
      'totalItemsSold': totalItemsSold,
      'uniqueProducts': uniqueProducts,
      'topProducts': topProducts.map((TopProduct x) => x.toMap()).toList(),
      'lowStockProducts': lowStockProducts.map((LowStockProduct x) => x.toMap()).toList(),
      'totalProductsInStock': totalProductsInStock,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'isSynced': isSynced,
      'syncedAt': syncedAt?.toIso8601String(),
    };

  @override
  String toString() => 'EODReport(id: $id, reportNumber: $reportNumber, date: $date, totalSales: $totalSales)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EODReport && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// نموذج أفضل المنتجات مبيعاً
class TopProduct {
  const TopProduct({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.totalValue,
    required this.profit,
  });

  factory TopProduct.fromMap(Map<String, dynamic> map) => TopProduct(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
    );

  final String productId;
  final String name;
  final int quantity;
  final double totalValue;
  final double profit;

  TopProduct copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? totalValue,
    double? profit,
  }) => TopProduct(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      totalValue: totalValue ?? this.totalValue,
      profit: profit ?? this.profit,
    );

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'totalValue': totalValue,
      'profit': profit,
    };

  @override
  String toString() => 'TopProduct(productId: $productId, name: $name, quantity: $quantity)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopProduct && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}

/// نموذج المنتجات ذات المخزون المنخفض
class LowStockProduct {
  const LowStockProduct({
    required this.productId,
    required this.name,
    required this.currentStock,
    required this.minStock,
  });

  factory LowStockProduct.fromMap(Map<String, dynamic> map) => LowStockProduct(
      productId: (map['productId'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      currentStock: (map['currentStock'] as int?) ?? 0,
      minStock: (map['minStock'] as int?) ?? 0,
    );

  final String productId;
  final String name;
  final int currentStock;
  final int minStock;

  LowStockProduct copyWith({
    String? productId,
    String? name,
    int? currentStock,
    int? minStock,
  }) => LowStockProduct(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
    );

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'name': name,
      'currentStock': currentStock,
      'minStock': minStock,
    };

  @override
  String toString() => 'LowStockProduct(productId: $productId, name: $name, currentStock: $currentStock)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LowStockProduct && other.productId == productId;
  }

  @override
  int get hashCode => productId.hashCode;
}
