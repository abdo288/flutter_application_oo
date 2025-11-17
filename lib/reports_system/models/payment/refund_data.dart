import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/payment_enums.dart';

part 'refund_data.freezed.dart';
part 'refund_data.g.dart';

/// بيانات المبالغ المستردة
@freezed
class RefundData with _$RefundData {
  const factory RefundData({
    required String id,
    required String originalTransactionId,
    required double amount,
    required String reason,
    required DateTime date,
    required String employeeId,
    required RefundStatus status,
  }) = _RefundData;

  factory RefundData.fromJson(Map<String, dynamic> json) =>
      _$RefundDataFromJson(json);
}
