import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/test_end_of_day_widget.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        title: 'اختبار نظام إنهاء اليوم',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const TestEndOfDayWidget(),
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
