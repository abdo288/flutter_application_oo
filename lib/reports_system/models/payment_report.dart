/// نموذج تقرير المدفوعات
class PaymentReport {
  const PaymentReport({
    required this.paymentMethods,
    required this.refunds,
    required this.debts,
    required this.paymentTrends,
    required this.period,
    required this.totalAmount,
    required this.totalTransactions,
  });

  factory PaymentReport.fromMap(Map<String, dynamic> map) => PaymentReport(
      paymentMethods: List<PaymentMethodData>.from(
        (map['paymentMethods'] as List<dynamic>?)?.map(
                (x) => PaymentMethodData.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      refunds: List<RefundData>.from(
        (map['refunds'] as List<dynamic>?)
                ?.map((x) => RefundData.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      debts: List<DebtData>.from(
        (map['debts'] as List<dynamic>?)
                ?.map((x) => DebtData.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      paymentTrends:
          PaymentTrends.fromMap(map['paymentTrends'] as Map<String, dynamic>),
      period: ReportPeriod.fromMap(map['period'] as Map<String, dynamic>),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (map['totalTransactions'] as int?) ?? 0,
    );

  final List<PaymentMethodData> paymentMethods;
  final List<RefundData> refunds;
  final List<DebtData> debts;
  final PaymentTrends paymentTrends;
  final ReportPeriod period;
  final double totalAmount;
  final int totalTransactions;

  /// حساب إجمالي المبالغ المستردة
  double get totalRefunds => refunds.fold(0.0, (double sum, RefundData refund) => sum + refund.amount);

  /// حساب إجمالي الديون
  double get totalDebts => debts.fold(0.0, (double sum, DebtData debt) => sum + debt.amount);

  /// حساب صافي المدفوعات
  double get netPayments => totalAmount - totalRefunds;

  /// حساب نسبة المبالغ المستردة
  double get refundPercentage {
    if (totalAmount == 0) return 0.0;
    return (totalRefunds / totalAmount) * 100;
  }

  /// حساب نسبة الديون
  double get debtPercentage {
    if (totalAmount == 0) return 0.0;
    return (totalDebts / totalAmount) * 100;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'paymentMethods': paymentMethods.map((PaymentMethodData x) => x.toMap()).toList(),
      'refunds': refunds.map((RefundData x) => x.toMap()).toList(),
      'debts': debts.map((DebtData x) => x.toMap()).toList(),
      'paymentTrends': paymentTrends.toMap(),
      'period': period.toMap(),
      'totalAmount': totalAmount,
      'totalTransactions': totalTransactions,
    };
}

/// بيانات طريقة الدفع
class PaymentMethodData {
  const PaymentMethodData({
    required this.method,
    required this.amount,
    required this.transactionCount,
    required this.percentage,
    required this.averageValue,
    required this.growthRate,
  });

  factory PaymentMethodData.fromMap(Map<String, dynamic> map) => PaymentMethodData(
      method: PaymentMethod.values.firstWhere(
        (PaymentMethod e) => e.name == map['method'],
        orElse: () => PaymentMethod.cash,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (map['transactionCount'] as int?) ?? 0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      averageValue: (map['averageValue'] as num?)?.toDouble() ?? 0.0,
      growthRate: (map['growthRate'] as num?)?.toDouble() ?? 0.0,
    );

  final PaymentMethod method;
  final double amount;
  final int transactionCount;
  final double percentage;
  final double averageValue;
  final double growthRate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'method': method.name,
      'amount': amount,
      'transactionCount': transactionCount,
      'percentage': percentage,
      'averageValue': averageValue,
      'growthRate': growthRate,
    };
}

/// بيانات المبالغ المستردة
class RefundData {
  const RefundData({
    required this.id,
    required this.originalTransactionId,
    required this.amount,
    required this.reason,
    required this.date,
    required this.employeeId,
    required this.status,
  });

  factory RefundData.fromMap(Map<String, dynamic> map) => RefundData(
      id: (map['id'] as String?) ?? '',
      originalTransactionId: (map['originalTransactionId'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      reason: (map['reason'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
      employeeId: (map['employeeId'] as String?) ?? '',
      status: RefundStatus.values.firstWhere(
        (RefundStatus e) => e.name == map['status'],
        orElse: () => RefundStatus.pending,
      ),
    );

  final String id;
  final String originalTransactionId;
  final double amount;
  final String reason;
  final DateTime date;
  final String employeeId;
  final RefundStatus status;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'originalTransactionId': originalTransactionId,
      'amount': amount,
      'reason': reason,
      'date': date.toIso8601String(),
      'employeeId': employeeId,
      'status': status.name,
    };
}

/// بيانات الديون
class DebtData {
  const DebtData({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.originalAmount,
    required this.date,
    required this.dueDate,
    required this.status,
    required this.notes,
  });

  factory DebtData.fromMap(Map<String, dynamic> map) => DebtData(
      id: (map['id'] as String?) ?? '',
      customerId: (map['customerId'] as String?) ?? '',
      customerName: (map['customerName'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      originalAmount: (map['originalAmount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      dueDate: DateTime.parse(map['dueDate'] as String),
      status: DebtStatus.values.firstWhere(
        (DebtStatus e) => e.name == map['status'],
        orElse: () => DebtStatus.pending,
      ),
      notes: (map['notes'] as String?) ?? '',
    );

  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final double originalAmount;
  final DateTime date;
  final DateTime dueDate;
  final DebtStatus status;
  final String notes;

  /// حساب المبلغ المدفوع
  double get paidAmount => originalAmount - amount;

  /// حساب نسبة السداد
  double get paymentPercentage {
    if (originalAmount == 0) return 0.0;
    return (paidAmount / originalAmount) * 100;
  }

  /// التحقق من انتهاء مدة السداد
  bool get isOverdue => DateTime.now().isAfter(dueDate) && status != DebtStatus.paid;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'originalAmount': originalAmount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
}

/// اتجاهات المدفوعات
class PaymentTrends {
  const PaymentTrends({
    required this.dailyTrends,
    required this.weeklyTrends,
    required this.monthlyTrends,
    required this.cashTrend,
    required this.cardTrend,
    required this.otherTrends,
  });

  factory PaymentTrends.fromMap(Map<String, dynamic> map) => PaymentTrends(
      dailyTrends: List<DailyPaymentTrend>.from(
        (map['dailyTrends'] as List<dynamic>?)?.map(
                (x) => DailyPaymentTrend.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      weeklyTrends: List<WeeklyPaymentTrend>.from(
        (map['weeklyTrends'] as List<dynamic>?)?.map(
                (x) => WeeklyPaymentTrend.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      monthlyTrends: List<MonthlyPaymentTrend>.from(
        (map['monthlyTrends'] as List<dynamic>?)?.map((x) =>
                MonthlyPaymentTrend.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      cashTrend:
          PaymentMethodTrend.fromMap(map['cashTrend'] as Map<String, dynamic>),
      cardTrend:
          PaymentMethodTrend.fromMap(map['cardTrend'] as Map<String, dynamic>),
      otherTrends: PaymentMethodTrend.fromMap(
          map['otherTrends'] as Map<String, dynamic>),
    );

  final List<DailyPaymentTrend> dailyTrends;
  final List<WeeklyPaymentTrend> weeklyTrends;
  final List<MonthlyPaymentTrend> monthlyTrends;
  final PaymentMethodTrend cashTrend;
  final PaymentMethodTrend cardTrend;
  final PaymentMethodTrend otherTrends;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'dailyTrends': dailyTrends.map((DailyPaymentTrend x) => x.toMap()).toList(),
      'weeklyTrends': weeklyTrends.map((WeeklyPaymentTrend x) => x.toMap()).toList(),
      'monthlyTrends': monthlyTrends.map((MonthlyPaymentTrend x) => x.toMap()).toList(),
      'cashTrend': cashTrend.toMap(),
      'cardTrend': cardTrend.toMap(),
      'otherTrends': otherTrends.toMap(),
    };
}

/// اتجاه المدفوعات اليومية
class DailyPaymentTrend {
  const DailyPaymentTrend({
    required this.date,
    required this.totalAmount,
    required this.cashAmount,
    required this.cardAmount,
    required this.otherAmount,
  });

  factory DailyPaymentTrend.fromMap(Map<String, dynamic> map) => DailyPaymentTrend(
      date: DateTime.parse(map['date'] as String),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      cashAmount: (map['cashAmount'] as num?)?.toDouble() ?? 0.0,
      cardAmount: (map['cardAmount'] as num?)?.toDouble() ?? 0.0,
      otherAmount: (map['otherAmount'] as num?)?.toDouble() ?? 0.0,
    );

  final DateTime date;
  final double totalAmount;
  final double cashAmount;
  final double cardAmount;
  final double otherAmount;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'cashAmount': cashAmount,
      'cardAmount': cardAmount,
      'otherAmount': otherAmount,
    };
}

/// اتجاه المدفوعات الأسبوعية
class WeeklyPaymentTrend {
  const WeeklyPaymentTrend({
    required this.weekStart,
    required this.weekEnd,
    required this.totalAmount,
    required this.averageDailyAmount,
  });

  factory WeeklyPaymentTrend.fromMap(Map<String, dynamic> map) => WeeklyPaymentTrend(
      weekStart: DateTime.parse(map['weekStart'] as String),
      weekEnd: DateTime.parse(map['weekEnd'] as String),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      averageDailyAmount:
          (map['averageDailyAmount'] as num?)?.toDouble() ?? 0.0,
    );

  final DateTime weekStart;
  final DateTime weekEnd;
  final double totalAmount;
  final double averageDailyAmount;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'totalAmount': totalAmount,
      'averageDailyAmount': averageDailyAmount,
    };
}

/// اتجاه المدفوعات الشهرية
class MonthlyPaymentTrend {
  const MonthlyPaymentTrend({
    required this.month,
    required this.year,
    required this.totalAmount,
    required this.averageDailyAmount,
  });

  factory MonthlyPaymentTrend.fromMap(Map<String, dynamic> map) => MonthlyPaymentTrend(
      month: (map['month'] as int?) ?? 0,
      year: (map['year'] as int?) ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      averageDailyAmount:
          (map['averageDailyAmount'] as num?)?.toDouble() ?? 0.0,
    );

  final int month;
  final int year;
  final double totalAmount;
  final double averageDailyAmount;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'month': month,
      'year': year,
      'totalAmount': totalAmount,
      'averageDailyAmount': averageDailyAmount,
    };
}

/// اتجاه طريقة الدفع
class PaymentMethodTrend {
  const PaymentMethodTrend({
    required this.method,
    required this.growthRate,
    required this.volatility,
    required this.peakValue,
    required this.peakDate,
  });

  factory PaymentMethodTrend.fromMap(Map<String, dynamic> map) => PaymentMethodTrend(
      method: PaymentMethod.values.firstWhere(
        (PaymentMethod e) => e.name == map['method'],
        orElse: () => PaymentMethod.cash,
      ),
      growthRate: (map['growthRate'] as num?)?.toDouble() ?? 0.0,
      volatility: (map['volatility'] as num?)?.toDouble() ?? 0.0,
      peakValue: (map['peakValue'] as num?)?.toDouble() ?? 0.0,
      peakDate: DateTime.parse(map['peakDate'] as String),
    );

  final PaymentMethod method;
  final double growthRate;
  final double volatility;
  final double peakValue;
  final DateTime peakDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'method': method.name,
      'growthRate': growthRate,
      'volatility': volatility,
      'peakValue': peakValue,
      'peakDate': peakDate.toIso8601String(),
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

  /// حساب عدد الأيام
  int get daysCount => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type.name,
    };
}

/// طريقة الدفع
enum PaymentMethod {
  cash,
  card,
  bankTransfer,
  check,
  other,
}

/// حالة المبلغ المسترد
enum RefundStatus {
  pending,
  approved,
  rejected,
  processed,
}

/// حالة الدين
enum DebtStatus {
  pending,
  partiallyPaid,
  paid,
  overdue,
  cancelled,
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
