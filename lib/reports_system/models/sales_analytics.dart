/// نموذج تحليلات المبيعات
class SalesAnalytics {
  const SalesAnalytics({
    required this.trendAnalysis,
    required this.hourlySales,
    required this.dailySales,
    required this.weeklySales,
    required this.monthlySales,
    required this.paymentDistribution,
    required this.topProducts,
    required this.customerAnalytics,
    required this.employeePerformance,
    required this.seasonalityAnalysis,
  });

  factory SalesAnalytics.fromMap(Map<String, dynamic> map) => SalesAnalytics(
      trendAnalysis:
          TrendAnalysis.fromMap(map['trendAnalysis'] as Map<String, dynamic>),
      hourlySales: List<HourlySale>.from(
        (map['hourlySales'] as List<dynamic>?)
                ?.map((x) => HourlySale.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      dailySales: List<DailySale>.from(
        (map['dailySales'] as List<dynamic>?)
                ?.map((x) => DailySale.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      weeklySales: List<WeeklySale>.from(
        (map['weeklySales'] as List<dynamic>?)
                ?.map((x) => WeeklySale.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      monthlySales: List<MonthlySale>.from(
        (map['monthlySales'] as List<dynamic>?)
                ?.map((x) => MonthlySale.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      paymentDistribution: PaymentDistribution.fromMap(
          map['paymentDistribution'] as Map<String, dynamic>),
      topProducts: List<ProductAnalytics>.from(
        (map['topProducts'] as List<dynamic>?)?.map(
                (x) => ProductAnalytics.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      customerAnalytics: CustomerAnalytics.fromMap(
          map['customerAnalytics'] as Map<String, dynamic>),
      employeePerformance: List<EmployeePerformance>.from(
        (map['employeePerformance'] as List<dynamic>?)?.map((x) =>
                EmployeePerformance.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      seasonalityAnalysis: SeasonalityAnalysis.fromMap(
          map['seasonalityAnalysis'] as Map<String, dynamic>),
    );

  final TrendAnalysis trendAnalysis;
  final List<HourlySale> hourlySales;
  final List<DailySale> dailySales;
  final List<WeeklySale> weeklySales;
  final List<MonthlySale> monthlySales;
  final PaymentDistribution paymentDistribution;
  final List<ProductAnalytics> topProducts;
  final CustomerAnalytics customerAnalytics;
  final List<EmployeePerformance> employeePerformance;
  final SeasonalityAnalysis seasonalityAnalysis;

  /// حساب إجمالي المبيعات للفترة
  double get totalSales => dailySales.fold(0.0, (double sum, DailySale sale) => sum + sale.totalAmount);

  /// حساب متوسط المبيعات اليومية
  double get averageDailySales {
    if (dailySales.isEmpty) return 0.0;
    return totalSales / dailySales.length;
  }

  /// حساب أفضل يوم مبيعات
  DailySale? get bestDay {
    if (dailySales.isEmpty) return null;
    return dailySales.reduce((DailySale a, DailySale b) => a.totalAmount > b.totalAmount ? a : b);
  }

  /// حساب أسوأ يوم مبيعات
  DailySale? get worstDay {
    if (dailySales.isEmpty) return null;
    return dailySales.reduce((DailySale a, DailySale b) => a.totalAmount < b.totalAmount ? a : b);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'trendAnalysis': trendAnalysis.toMap(),
      'hourlySales': hourlySales.map((HourlySale x) => x.toMap()).toList(),
      'dailySales': dailySales.map((DailySale x) => x.toMap()).toList(),
      'weeklySales': weeklySales.map((WeeklySale x) => x.toMap()).toList(),
      'monthlySales': monthlySales.map((MonthlySale x) => x.toMap()).toList(),
      'paymentDistribution': paymentDistribution.toMap(),
      'topProducts': topProducts.map((ProductAnalytics x) => x.toMap()).toList(),
      'customerAnalytics': customerAnalytics.toMap(),
      'employeePerformance': employeePerformance.map((EmployeePerformance x) => x.toMap()).toList(),
      'seasonalityAnalysis': seasonalityAnalysis.toMap(),
    };
}

/// تحليل الاتجاهات
class TrendAnalysis {
  const TrendAnalysis({
    required this.trend,
    required this.growthRate,
    required this.volatility,
    required this.peakValue,
    required this.peakDate,
    required this.lowValue,
    required this.lowDate,
  });

  factory TrendAnalysis.fromMap(Map<String, dynamic> map) => TrendAnalysis(
      trend: TrendDirection.values.firstWhere(
        (TrendDirection e) => e.name == map['trend'],
        orElse: () => TrendDirection.stable,
      ),
      growthRate: (map['growthRate'] as num?)?.toDouble() ?? 0.0,
      volatility: (map['volatility'] as num?)?.toDouble() ?? 0.0,
      peakValue: (map['peakValue'] as num?)?.toDouble() ?? 0.0,
      peakDate: DateTime.parse(map['peakDate'] as String),
      lowValue: (map['lowValue'] as num?)?.toDouble() ?? 0.0,
      lowDate: DateTime.parse(map['lowDate'] as String),
    );

  final TrendDirection trend;
  final double growthRate;
  final double volatility;
  final double peakValue;
  final DateTime peakDate;
  final double lowValue;
  final DateTime lowDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'trend': trend.name,
      'growthRate': growthRate,
      'volatility': volatility,
      'peakValue': peakValue,
      'peakDate': peakDate.toIso8601String(),
      'lowValue': lowValue,
      'lowDate': lowDate.toIso8601String(),
    };
}

/// مبيعات ساعية
class HourlySale {
  const HourlySale({
    required this.hour,
    required this.totalAmount,
    required this.transactionCount,
    required this.averageValue,
  });

  factory HourlySale.fromMap(Map<String, dynamic> map) => HourlySale(
      hour: (map['hour'] as int?) ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      averageValue: (map['averageValue'] as num?)?.toDouble() ?? 0.0,
    );

  final int hour;
  final double totalAmount;
  final int transactionCount;
  final double averageValue;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'hour': hour,
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'averageValue': averageValue,
    };
}

/// مبيعات يومية
class DailySale {
  const DailySale({
    required this.date,
    required this.totalAmount,
    required this.transactionCount,
    required this.customerCount,
    required this.averageValue,
    required this.profit,
  });

  factory DailySale.fromMap(Map<String, dynamic> map) => DailySale(
      date: DateTime.parse(map['date'] as String),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      customerCount: (map['customerCount'] as int?) ?? 0,
      averageValue: (map['averageValue'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
    );

  final DateTime date;
  final double totalAmount;
  final int transactionCount;
  final int customerCount;
  final double averageValue;
  final double profit;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'customerCount': customerCount,
      'averageValue': averageValue,
      'profit': profit,
    };
}

/// مبيعات أسبوعية
class WeeklySale {
  const WeeklySale({
    required this.weekStart,
    required this.weekEnd,
    required this.totalAmount,
    required this.transactionCount,
    required this.averageDailyAmount,
  });

  factory WeeklySale.fromMap(Map<String, dynamic> map) => WeeklySale(
      weekStart: DateTime.parse(map['weekStart'] as String),
      weekEnd: DateTime.parse(map['weekEnd'] as String),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      averageDailyAmount:
          (map['averageDailyAmount'] as num?)?.toDouble() ?? 0.0,
    );

  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalAmount;
  final int transactionCount;
  final double averageDailyAmount;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'averageDailyAmount': averageDailyAmount,
    };
}

/// مبيعات شهرية
class MonthlySale {
  const MonthlySale({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.transactionCount,
    required this.averageDailyAmount,
  });

  factory MonthlySale.fromMap(Map<String, dynamic> map) => MonthlySale(
      month: (map['month'] as int?) ?? 0,
      year: (map['year'] as int?) ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      averageDailyAmount:
          (map['averageDailyAmount'] as num?)?.toDouble() ?? 0.0,
    );

  final int month;
  final int year;
  final double totalAmount;
  final int transactionCount;
  final double averageDailyAmount;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'month': month,
      'year': year,
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'averageDailyAmount': averageDailyAmount,
    };
}

/// توزيع طرق الدفع
class PaymentDistribution {
  const PaymentDistribution({
    required this.cashAmount,
    required this.cardAmount,
    required this.otherAmount,
    required this.cashPercentage,
    required this.cardPercentage,
    required this.otherPercentage,
  });

  factory PaymentDistribution.fromMap(Map<String, dynamic> map) => PaymentDistribution(
      cashAmount: (map['cashAmount'] as num?)?.toDouble() ?? 0.0,
      cardAmount: (map['cardAmount'] as num?)?.toDouble() ?? 0.0,
      otherAmount: (map['otherAmount'] as num?)?.toDouble() ?? 0.0,
      cashPercentage: (map['cashPercentage'] as num?)?.toDouble() ?? 0.0,
      cardPercentage: (map['cardPercentage'] as num?)?.toDouble() ?? 0.0,
      otherPercentage: (map['otherPercentage'] as num?)?.toDouble() ?? 0.0,
    );

  final double cashAmount;
  final double cardAmount;
  final double otherAmount;
  final double cashPercentage;
  final double cardPercentage;
  final double otherPercentage;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'cashAmount': cashAmount,
      'cardAmount': cardAmount,
      'otherAmount': otherAmount,
      'cashPercentage': cashPercentage,
      'cardPercentage': cardPercentage,
      'otherPercentage': otherPercentage,
    };
}

/// تحليلات المنتج
class ProductAnalytics {
  const ProductAnalytics({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.totalValue,
    required this.profit,
    required this.rank,
    required this.growthRate,
  });

  factory ProductAnalytics.fromMap(Map<String, dynamic> map) => ProductAnalytics(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      quantitySold: (map['quantitySold'] as int?) ?? 0,
      totalValue: (map['totalValue'] as num?)?.toDouble() ?? 0.0,
      profit: (map['profit'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as int?) ?? 0,
      growthRate: (map['growthRate'] as num?)?.toDouble() ?? 0.0,
    );

  final String productId;
  final String productName;
  final int quantitySold;
  final double totalValue;
  final double profit;
  final int rank;
  final double growthRate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'productId': productId,
      'productName': productName,
      'quantitySold': quantitySold,
      'totalValue': totalValue,
      'profit': profit,
      'rank': rank,
      'growthRate': growthRate,
    };
}

/// تحليلات العملاء
class CustomerAnalytics {
  const CustomerAnalytics({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.averageOrderValue,
    required this.customerRetentionRate,
  });

  factory CustomerAnalytics.fromMap(Map<String, dynamic> map) => CustomerAnalytics(
      totalCustomers: (map['totalCustomers'] as int?) ?? 0,
      newCustomers: (map['newCustomers'] as int?) ?? 0,
      returningCustomers: (map['returningCustomers'] as int?) ?? 0,
      averageOrderValue: (map['averageOrderValue'] as num?)?.toDouble() ?? 0.0,
      customerRetentionRate:
          (map['customerRetentionRate'] as num?)?.toDouble() ?? 0.0,
    );

  final int totalCustomers;
  final int newCustomers;
  final int returningCustomers;
  final double averageOrderValue;
  final double customerRetentionRate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'totalCustomers': totalCustomers,
      'newCustomers': newCustomers,
      'returningCustomers': returningCustomers,
      'averageOrderValue': averageOrderValue,
      'customerRetentionRate': customerRetentionRate,
    };
}

/// أداء الموظف
class EmployeePerformance {
  const EmployeePerformance({
    required this.employeeId,
    required this.employeeName,
    required this.totalSales,
    required this.transactionCount,
    required this.averageSaleValue,
    required this.rank,
  });

  factory EmployeePerformance.fromMap(Map<String, dynamic> map) => EmployeePerformance(
      employeeId: (map['employeeId'] as String?) ?? '',
      employeeName: (map['employeeName'] as String?) ?? '',
      totalSales: (map['totalSales'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      averageSaleValue: (map['averageSaleValue'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as int?) ?? 0,
    );

  final String employeeId;
  final String employeeName;
  final double totalSales;
  final int transactionCount;
  final double averageSaleValue;
  final int rank;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'employeeId': employeeId,
      'employeeName': employeeName,
      'totalSales': totalSales,
      'transactionCount': transactionCount,
      'averageSaleValue': averageSaleValue,
      'rank': rank,
    };
}

/// تحليل الموسمية
class SeasonalityAnalysis {
  const SeasonalityAnalysis({
    required this.seasonalPattern,
    required this.peakMonths,
    required this.lowMonths,
    required this.seasonalIndex,
  });

  factory SeasonalityAnalysis.fromMap(Map<String, dynamic> map) => SeasonalityAnalysis(
      seasonalPattern:
          List<double>.from(map['seasonalPattern'] as List<dynamic>? ?? <dynamic>[]),
      peakMonths: List<int>.from(map['peakMonths'] as List<dynamic>? ?? <dynamic>[]),
      lowMonths: List<int>.from(map['lowMonths'] as List<dynamic>? ?? <dynamic>[]),
      seasonalIndex: (map['seasonalIndex'] as num?)?.toDouble() ?? 0.0,
    );

  final List<double> seasonalPattern;
  final List<int> peakMonths;
  final List<int> lowMonths;
  final double seasonalIndex;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'seasonalPattern': seasonalPattern,
      'peakMonths': peakMonths,
      'lowMonths': lowMonths,
      'seasonalIndex': seasonalIndex,
    };
}

/// اتجاه الاتجاه
enum TrendDirection {
  increasing,
  decreasing,
  stable,
  volatile,
}
