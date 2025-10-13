import 'package:flutter_test/flutter_test.dart';

/// تكوين الاختبارات العامة
class TestConfig {
  // مهلة زمنية للاختبارات (بالثواني)
  static const Duration testTimeout = Duration(seconds: 30);
  
  // مهلة زمنية للعمليات غير المتصلة (بالثواني)
  static const Duration offlineTimeout = Duration(seconds: 5);
  
  // مهلة زمنية للعمليات المتصلة (بالثواني)
  static const Duration onlineTimeout = Duration(seconds: 10);
  
  // عدد المحاولات للعمليات التي قد تفشل
  static const int maxRetries = 3;
  
  // تأخير بين المحاولات (بالميلي ثانية)
  static const Duration retryDelay = Duration(milliseconds: 500);
  
  /// إعداد مهلة زمنية للاختبار
  static void setupTestTimeout() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }
  
  /// انتظار مع مهلة زمنية
  static Future<void> waitWithTimeout(
    Future<void> Function() operation, {
    Duration? timeout,
  }) async {
    await operation().timeout(timeout ?? testTimeout);
  }
  
  /// تنفيذ عملية مع إعادة المحاولة
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int? maxRetries,
    Duration? retryDelay,
  }) async {
    int attempts = 0;
    final int retries = maxRetries ?? TestConfig.maxRetries;
    final Duration delay = retryDelay ?? TestConfig.retryDelay;
    
    while (attempts < retries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= retries) {
          rethrow;
        }
        await Future<void>.delayed(delay);
      }
    }
    
    throw Exception('فشل في تنفيذ العملية بعد $retries محاولات');
  }
  
  /// التحقق من أن الاختبار يعمل في بيئة الاختبار
  static bool isTestEnvironment() => true;
  
  /// تنظيف البيانات بعد الاختبار
  static Future<void> cleanupAfterTest() async {
    // إضافة أي عمليات تنظيف مطلوبة هنا
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
