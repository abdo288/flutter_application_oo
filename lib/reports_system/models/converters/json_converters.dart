import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// محول TimeOfDay للـ JSON
class TimeOfDayConverter
    implements JsonConverter<TimeOfDay?, Map<String, dynamic>?> {
  const TimeOfDayConverter();

  @override
  TimeOfDay? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TimeOfDay(
      hour: (json['hour'] as int?) ?? 0,
      minute: (json['minute'] as int?) ?? 0,
    );
  }

  @override
  Map<String, dynamic>? toJson(TimeOfDay? timeOfDay) {
    if (timeOfDay == null) return null;
    return <String, dynamic>{
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };
  }
}

/// محول DateTime للـ JSON
class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime dateTime) => dateTime.toIso8601String();
}

/// محول DateTime nullable للـ JSON
class DateTimeNullableConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeNullableConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.parse(json);
  }

  @override
  String? toJson(DateTime? dateTime) => dateTime?.toIso8601String();
}

/// محول Duration للـ JSON
class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration duration) => duration.inMilliseconds;
}

/// محول Duration nullable للـ JSON
class DurationNullableConverter implements JsonConverter<Duration?, int?> {
  const DurationNullableConverter();

  @override
  Duration? fromJson(int? json) {
    if (json == null) return null;
    return Duration(milliseconds: json);
  }

  @override
  int? toJson(Duration? duration) => duration?.inMilliseconds;
}

/// محول عام للـ Enums
class EnumConverter<T extends Enum> implements JsonConverter<T, String> {
  const EnumConverter(this.values);

  final List<T> values;

  @override
  T fromJson(String json) => values.firstWhere(
      (e) => e.name == json,
      orElse: () => values.first,
    );

  @override
  String toJson(T object) => object.name;
}

/// محول عام للـ Enums nullable
class EnumNullableConverter<T extends Enum>
    implements JsonConverter<T?, String?> {
  const EnumNullableConverter(this.values);

  final List<T> values;

  @override
  T? fromJson(String? json) {
    if (json == null) return null;
    return values.firstWhere(
      (e) => e.name == json,
      orElse: () => values.first,
    );
  }

  @override
  String? toJson(T? object) => object?.name;
}

/// محول List للـ Enums
class EnumListConverter<T extends Enum>
    implements JsonConverter<List<T>, List<String>> {
  const EnumListConverter(this.values);

  final List<T> values;

  @override
  List<T> fromJson(List<String> json) => json
        .map((String e) => values.firstWhere(
              (enumValue) => enumValue.name == e,
              orElse: () => values.first,
            ))
        .toList();

  @override
  List<String> toJson(List<T> object) => object.map((e) => e.name).toList();
}

/// محول List للـ Enums nullable
class EnumListNullableConverter<T extends Enum>
    implements JsonConverter<List<T>?, List<String>?> {
  const EnumListNullableConverter(this.values);

  final List<T> values;

  @override
  List<T>? fromJson(List<String>? json) {
    if (json == null) return null;
    return json
        .map((String e) => values.firstWhere(
              (enumValue) => enumValue.name == e,
              orElse: () => values.first,
            ))
        .toList();
  }

  @override
  List<String>? toJson(List<T>? object) => object?.map((e) => e.name).toList();
}
