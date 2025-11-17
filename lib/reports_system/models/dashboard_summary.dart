/// نموذج ملخص لوحة التحكم
class DashboardSummary {
  const DashboardSummary({
    required this.totalSalesToday,
    required this.totalSalesYesterday,
    required this.totalCustomersToday,
    required this.totalCustomersYesterday,
    required this.topProducts,
    required this.lowStockAlerts,
    required this.syncStatus,
    required this.lastSyncTime,
    required this.totalTransactionsToday,
    required this.averageSaleValue,
    required this.totalProfitToday,
    required this.totalProfitYesterday,
  });

  /// إنشاء من Map
  factory DashboardSummary.fromMap(Map<String, dynamic> map) => DashboardSummary(
      totalSalesToday: (map['totalSalesToday'] as num?)?.toDouble() ?? 0.0,
      totalSalesYesterday:
          (map['totalSalesYesterday'] as num?)?.toDouble() ?? 0.0,
      totalCustomersToday: (map['totalCustomersToday'] as int?) ?? 0,
      totalCustomersYesterday: (map['totalCustomersYesterday'] as int?) ?? 0,
      topProducts: List<TopProductSummary>.from(
        (map['topProducts'] as List<dynamic>?)?.map(
                (x) => TopProductSummary.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      lowStockAlerts: List<LowStockAlert>.from(
        (map['lowStockAlerts'] as List<dynamic>?)?.map(
                (x) => LowStockAlert.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      syncStatus: SyncStatus.values.firstWhere(
        (SyncStatus e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.unknown,
      ),
      lastSyncTime: map['lastSyncTime'] != null
          ? DateTime.parse(map['lastSyncTime'] as String)
          : null,
      totalTransactionsToday: (map['totalTransactionsToday'] as int?) ?? 0,
      averageSaleValue: (map['averageSaleValue'] as num?)?.toDouble() ?? 0.0,
      totalProfitToday: (map['totalProfitToday'] as num?)?.toDouble() ?? 0.0,
      totalProfitYesterday:
          (map['totalProfitYesterday'] as num?)?.toDouble() ?? 0.0,
    );

  final double totalSalesToday;
  final double totalSalesYesterday;
  final int totalCustomersToday;
  final int totalCustomersYesterday;
  final List<TopProductSummary> topProducts;
  final List<LowStockAlert> lowStockAlerts;
  final SyncStatus syncStatus;
  final DateTime? lastSyncTime;
  final int totalTransactionsToday;
  final double averageSaleValue;
  final double totalProfitToday;
  final double totalProfitYesterday;

  /// حساب نسبة التغيير في المبيعات
  double get salesChangePercentage {
    if (totalSalesYesterday == 0) return 0.0;
    return ((totalSalesToday - totalSalesYesterday) / totalSalesYesterday) *
        100;
  }

  /// حساب نسبة التغيير في العملاء
  double get customersChangePercentage {
    if (totalCustomersYesterday == 0) return 0.0;
    return ((totalCustomersToday - totalCustomersYesterday) /
            totalCustomersYesterday) *
        100;
  }

  /// حساب نسبة التغيير في الأرباح
  double get profitChangePercentage {
    if (totalProfitYesterday == 0) return 0.0;
    return ((totalProfitToday - totalProfitYesterday) / totalProfitYesterday) *
        100;
  }

  /// التحقق من وجود تنبيهات مخزون
  bool get hasLowStockAlerts => lowStockAlerts.isNotEmpty;

  /// التحقق من حالة المزامنة
  bool get isSynced => syncStatus == SyncStatus.synced;

  /// إنشاء نسخة من الملخص مع تحديث القيم المحددة
  DashboardSummary copyWith({
    double? totalSalesToday,
    double? totalSalesYesterday,
    int? totalCustomersToday,
    int? totalCustomersYesterday,
    List<TopProductSummary>? topProducts,
    List<LowStockAlert>? lowStockAlerts,
    SyncStatus? syncStatus,
    DateTime? lastSyncTime,
    int? totalTransactionsToday,
    double? averageSaleValue,
    double? totalProfitToday,
    double? totalProfitYesterday,
  }) => DashboardSummary(
      totalSalesToday: totalSalesToday ?? this.totalSalesToday,
      totalSalesYesterday: totalSalesYesterday ?? this.totalSalesYesterday,
      totalCustomersToday: totalCustomersToday ?? this.totalCustomersToday,
      totalCustomersYesterday:
          totalCustomersYesterday ?? this.totalCustomersYesterday,
      topProducts: topProducts ?? this.topProducts,
      lowStockAlerts: lowStockAlerts ?? this.lowStockAlerts,
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      totalTransactionsToday:
          totalTransactionsToday ?? this.totalTransactionsToday,
      averageSaleValue: averageSaleValue ?? this.averageSaleValue,
      totalProfitToday: totalProfitToday ?? this.totalProfitToday,
      totalProfitYesterday: totalProfitYesterday ?? this.totalProfitYesterday,
    );

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => <String, dynamic>{
      'totalSalesToday': totalSalesToday,
      'totalSalesYesterday': totalSalesYesterday,
      'totalCustomersToday': totalCustomersToday,
      'totalCustomersYesterday': totalCustomersYesterday,
      'topProducts': topProducts.map((TopProductSummary x) => x.toMap()).toList(),
      'lowStockAlerts': lowStockAlerts.map((LowStockAlert x) => x.toMap()).toList(),
      'syncStatus': syncStatus.name,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'totalTransactionsToday': totalTransactionsToday,
      'averageSaleValue': averageSaleValue,
      'totalProfitToday': totalProfitToday,
      'totalProfitYesterday': totalProfitYesterday,
    };

  @override
  String toString() => 'DashboardSummary(totalSalesToday: $totalSalesToday, totalSalesYesterday: $totalSalesYesterday, totalCustomersToday: $totalCustomersToday, totalCustomersYesterday: $totalCustomersYesterday, topProducts: $topProducts, lowStockAlerts: $lowStockAlerts, syncStatus: $syncStatus, lastSyncTime: $lastSyncTime, totalTransactionsToday: $totalTransactionsToday, averageSaleValue: $averageSaleValue, totalProfitToday: $totalProfitToday, totalProfitYesterday: $totalProfitYesterday)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardSummary &&
        other.totalSalesToday == totalSalesToday &&
        other.totalSalesYesterday == totalSalesYesterday &&
        other.totalCustomersToday == totalCustomersToday &&
        other.totalCustomersYesterday == totalCustomersYesterday &&
        other.topProducts == topProducts &&
        other.lowStockAlerts == lowStockAlerts &&
        other.syncStatus == syncStatus &&
        other.lastSyncTime == lastSyncTime &&
        other.totalTransactionsToday == totalTransactionsToday &&
        other.averageSaleValue == averageSaleValue &&
        other.totalProfitToday == totalProfitToday &&
        other.totalProfitYesterday == totalProfitYesterday;
  }

  @override
  int get hashCode => totalSalesToday.hashCode ^
        totalSalesYesterday.hashCode ^
        totalCustomersToday.hashCode ^
        totalCustomersYesterday.hashCode ^
        topProducts.hashCode ^
        lowStockAlerts.hashCode ^
        syncStatus.hashCode ^
        lastSyncTime.hashCode ^
        totalTransactionsToday.hashCode ^
        averageSaleValue.hashCode ^
        totalProfitToday.hashCode ^
        totalProfitYesterday.hashCode;
}

/// ملخص أفضل منتج
class TopProductSummary {
  const TopProductSummary({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalValue,
    required this.rank,
  });

  factory TopProductSummary.fromMap(Map<String, dynamic> map) => TopProductSummary(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      quantitySold: (map['quantitySold'] as int?) ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as int?) ?? 0,
    );

  final String productId;
  final String productName;
  final int quantitySold;
  final double totalValue;
  final int rank;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'quantitySold': quantitySold,
      'totalValue': totalValue,
      'rank': rank,
    };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopProductSummary &&
        other.productId == productId &&
        other.productName == productName &&
        other.quantitySold == quantitySold &&
        other.totalValue == totalValue &&
        other.rank == rank;
  }

  @override
  int get hashCode => productId.hashCode ^
        productName.hashCode ^
        quantitySold.hashCode ^
        totalValue.hashCode ^
        rank.hashCode;
}

/// تنبيه مخزون منخفض
class LowStockAlert {
  const LowStockAlert({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.alertLevel,
  });

  factory LowStockAlert.fromMap(Map<String, dynamic> map) => LowStockAlert(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      currentStock: (map['currentStock'] as int?) ?? 0,
      minimumStock: (map['minimumStock'] as int?) ?? 0,
      alertLevel: AlertLevel.values.firstWhere(
        (AlertLevel e) => e.name == map['alertLevel'],
        orElse: () => AlertLevel.low,
      ),
    );

  final String productId;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final AlertLevel alertLevel;

  /// حساب نسبة المخزون المتبقي
  double get stockPercentage {
    if (minimumStock == 0) return 0.0;
    return (currentStock / minimumStock) * 100;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'alertLevel': alertLevel.name,
    };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LowStockAlert &&
        other.productId == productId &&
        other.productName == productName &&
        other.currentStock == currentStock &&
        other.minimumStock == minimumStock &&
        other.alertLevel == alertLevel;
  }

  @override
  int get hashCode => productId.hashCode ^
        productName.hashCode ^
        currentStock.hashCode ^
        minimumStock.hashCode ^
        alertLevel.hashCode;
}

/// حالة المزامنة
enum SyncStatus {
  synced,
  syncing,
  failed,
  unknown,
}

/// مستوى التنبيه
enum AlertLevel {
  low,
  critical,
  outOfStock,
}
