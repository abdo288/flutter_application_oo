import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_initializer.dart';
import 'app/app_widget.dart';

void main() async {
  // ضمان تهيئة Flutter قبل أي شيء آخر
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الخدمات الأساسية قبل تشغيل التطبيق
  await initializeCoreServices();

  // تشغيل التطبيق بعد اكتمال التهيئة الأساسية
  runApp(
    const ProviderScope(
      child: StreamProfitCalculatorApp(),
    ),
  );
}
