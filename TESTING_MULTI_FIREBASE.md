# 🧪 دليل اختبار Multi-Firebase

## ✅ تم تحديث الإعدادات

تم تحديث `firebase_options_secondary.dart` بالإعدادات الصحيحة من ملفات `google-services.json`:

### المشاريع المكونة:

1. **المشروع الرئيسي**: `main-products-app`
   - Project ID: `main-products-app`
   - API Key: `AIzaSyDJKvdEOKU49rRF_jojzGlE97a9nJZZmp0`

2. **مشروع المبيعات**: `sales-analytics-app-48211`
   - Project ID: `sales-analytics-app-48211`
   - API Key: `AIzaSyB4qThN0QneGegVvC0X9yloxSMdgfEs6DA`

3. **مشروع المستخدمين**: `addprice-c2576`
   - Project ID: `addprice-c2576`
   - API Key: `AIzaSyB5Ec9d-dkUre52HdBg4RbRaGhBTVMy3vI`

## 🚀 خطوات الاختبار

### 1. تشغيل التطبيق
```bash
flutter clean
flutter pub get
flutter run
```

### 2. مراقبة السجلات
ابحث عن هذه الرسائل في Console:

```
✅ تم تهيئة Firebase الرئيسي بنجاح
✅ تم تهيئة مشروع المبيعات
✅ تم تهيئة مشروع المستخدمين
✅ تم تهيئة Multi-Firebase Manager
📊 بدء مراقبة حصة Firebase
```

### 3. اختبار المزامنة

#### أ. إضافة منتج جديد:
1. افتح التطبيق
2. اذهب إلى تبويب "إضافة منتج"
3. أضف منتج جديد
4. احفظ المنتج

#### ب. التحقق من Firebase Console:
1. افتح https://console.firebase.google.com
2. اختر مشروع `main-products-app`
3. انتقل إلى Firestore Database
4. تحقق من ظهور المنتج في مجموعة `products`

#### ج. اختبار مشروع المبيعات:
1. قم بعملية بيع في التطبيق
2. افتح مشروع `sales-analytics-app-48211`
3. تحقق من ظهور المبيعة في مجموعة `sales`

#### د. اختبار مشروع المستخدمين:
1. قم بتسجيل دخول أو إدارة المستخدمين
2. افتح مشروع `addprice-c2576`
3. تحقق من ظهور بيانات المستخدمين في مجموعة `users`

### 4. مراقبة التوزيع

في Console، يجب أن ترى:

```
🔄 مزامنة المنتجات إلى المشروع الرئيسي
✅ تمت مزامنة المنتجات

🔄 مزامنة المبيعات إلى مشروع المبيعات
✅ تمت مزامنة المبيعات

📊 حالة المشاريع: 3 متاح، 0 حرج
```

## 🔍 فحص الأخطاء

### إذا ظهر خطأ: "No Firebase App '[name]' has been created"

**الحل:**
1. تأكد من تشغيل `flutter clean && flutter pub get`
2. تحقق من صحة API Keys في `firebase_options_secondary.dart`

### إذا ظهر خطأ: "PERMISSION_DENIED"

**الحل:**
1. في Firebase Console، انتقل إلى Firestore Database > Rules
2. استبدل القواعد بـ:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

### إذا لم تظهر رسائل Multi-Firebase

**الحل:**
1. تحقق من أن `main_stream.dart` يحتوي على تهيئة المشاريع الإضافية
2. تأكد من استيراد `firebase_options_secondary.dart`

## 📊 مؤشرات النجاح

### ✅ المؤشرات الإيجابية:

1. **رسائل التهيئة:**
   ```
   ✅ تم تهيئة Multi-Firebase Manager
   📊 بدء مراقبة حصة Firebase
   ```

2. **رسائل المزامنة:**
   ```
   🔄 مزامنة المنتجات إلى المشروع الرئيسي
   🔄 مزامنة المبيعات إلى مشروع المبيعات
   ```

3. **البيانات في Firebase:**
   - المنتجات في `main-products-app`
   - المبيعات في `sales-analytics-app-48211`
   - المستخدمين في `addprice-c2576`

### ❌ المؤشرات السلبية:

1. **أخطاء التهيئة:**
   ```
   ❌ خطأ في تهيئة مشروع المبيعات
   ❌ خطأ في تهيئة مشروع المستخدمين
   ```

2. **أخطاء المزامنة:**
   ```
   ❌ خطأ في مزامنة المنتجات
   ❌ خطأ في مزامنة المبيعات
   ```

## 🎯 النتيجة المتوقعة

بعد الاختبار الناجح، يجب أن تحصل على:

- **زيادة السعة**: 150,000 قراءة/يوم (بدلاً من 50,000)
- **توزيع ذكي**: البيانات موزعة على 3 مشاريع
- **حماية من التجاوز**: مراقبة تلقائية للحصة
- **أداء محسن**: استجابة أسرع للتحديثات

## 🚨 استكشاف الأخطاء المتقدم

### فحص حالة المشاريع:
```dart
// في التطبيق، أضف هذا الكود للفحص
final monitor = FirebaseQuotaMonitor();
final stats = monitor.getQuotaReport();
print('إحصائيات الحصة: $stats');
```

### فحص المشاريع المتاحة:
```dart
final manager = MultiFirebaseManager();
final available = manager.getAvailableProjects();
print('المشاريع المتاحة: $available');
```

## 🎉 الخلاصة

إذا ظهرت جميع الرسائل الإيجابية وتم توزيع البيانات على المشاريع الثلاثة، فإن نظام Multi-Firebase يعمل بنجاح!

**النتيجة**: زيادة السعة 300% مع حماية من تجاوز الحصة! 🚀
