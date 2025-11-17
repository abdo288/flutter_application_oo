import 'package:flutter_riverpod/flutter_riverpod.dart';

/// مزود لإدارة التبويب الفرعي النشط في تبويب التقارير الرئيسي
/// هذا المزود البسيط يدير التبويب الفرعي النشط حالياً
final StateNotifierProvider<MainReportsTabNotifier, int> mainReportsTabControllerProvider =
    StateNotifierProvider<MainReportsTabNotifier, int>((StateNotifierProviderRef<MainReportsTabNotifier, int> ref) => MainReportsTabNotifier());

/// Notifier لإدارة حالة التبويبات الفرعية
class MainReportsTabNotifier extends StateNotifier<int> {
  MainReportsTabNotifier() : super(0); // ابدأ بالتبويب الأول

  /// تعيين التبويب النشط
  void setTab(int index) {
    state = index;
  }
}
