import 'cleanup_stats.dart';

/// نتيجة عملية التنظيف
class CleanupResult {
  CleanupResult({
    required this.success,
    required this.message,
    this.stats,
  });

  final bool success;
  final String message;
  final CleanupStats? stats;
}
