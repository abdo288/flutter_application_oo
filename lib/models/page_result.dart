import 'package:cloud_firestore/cloud_firestore.dart';

/// نتيجة صفحة عامة لعمليات التحميل التدريجي
class PageResult<T> {
  PageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}
