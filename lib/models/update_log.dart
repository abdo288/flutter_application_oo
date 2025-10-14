import 'dart:convert';

/// نموذج سجل التحديثات الفورية
class UpdateLog {

  const UpdateLog({
    required this.id,
    required this.type,
    required this.action,
    required this.timestamp,
    required this.message,
    required this.isSuccessful,
    this.data,
    this.errorMessage,
    this.responseTime,
  });

  /// إنشاء سجل تحديث جديد
  factory UpdateLog.create({
    required String type,
    required String action,
    required String message,
    bool isSuccessful = true,
    Map<String, dynamic>? data,
    String? errorMessage,
    Duration? responseTime,
  }) => UpdateLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      action: action,
      timestamp: DateTime.now(),
      message: message,
      isSuccessful: isSuccessful,
      data: data,
      errorMessage: errorMessage,
      responseTime: responseTime,
    );

  /// إنشاء من Map
  factory UpdateLog.fromMap(Map<String, dynamic> map) => UpdateLog(
      id: map['id'] as String,
      type: map['type'] as String,
      action: map['action'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      message: map['message'] as String,
      isSuccessful: map['isSuccessful'] as bool,
      data: map['data'] as Map<String, dynamic>?,
      errorMessage: map['errorMessage'] as String?,
      responseTime: map['responseTime'] != null
          ? Duration(milliseconds: map['responseTime'] as int)
          : null,
    );

  /// إنشاء من JSON
  factory UpdateLog.fromJson(String source) =>
      UpdateLog.fromMap(json.decode(source) as Map<String, dynamic>);
  final String id;
  final String type; // 'product', 'inventory', 'sale'
  final String action; // 'create', 'update', 'delete', 'sync'
  final DateTime timestamp;
  final String message;
  final bool isSuccessful;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final Duration? responseTime;

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'type': type,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'message': message,
      'isSuccessful': isSuccessful,
      'data': data,
      'errorMessage': errorMessage,
      'responseTime': responseTime?.inMilliseconds,
    };

  /// تحويل إلى JSON
  String toJson() => json.encode(toMap());

  /// الحصول على لون الحالة
  String get statusColor {
    if (isSuccessful) {
      return 'green';
    } else {
      return 'red';
    }
  }

  /// الحصول على أيقونة الحالة
  String get statusIcon {
    if (isSuccessful) {
      return 'check_circle';
    } else {
      return 'error';
    }
  }

  /// تنسيق الوقت
  String get formattedTime {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  /// تنسيق وقت الاستجابة
  String get formattedResponseTime {
    if (responseTime == null) return 'غير محدد';

    if (responseTime!.inMilliseconds < 1000) {
      return '${responseTime!.inMilliseconds}ms';
    } else {
      return '${(responseTime!.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
  }

  /// نسخ مع تعديلات
  UpdateLog copyWith({
    String? id,
    String? type,
    String? action,
    DateTime? timestamp,
    String? message,
    bool? isSuccessful,
    Map<String, dynamic>? data,
    String? errorMessage,
    Duration? responseTime,
  }) => UpdateLog(
      id: id ?? this.id,
      type: type ?? this.type,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      responseTime: responseTime ?? this.responseTime,
    );

  @override
  String toString() => 'UpdateLog(id: $id, type: $type, action: $action, timestamp: $timestamp, message: $message, isSuccessful: $isSuccessful)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
