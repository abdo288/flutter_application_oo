# 🚀 Auto Update GitHub Gists Script

Script احترافي لتحديث 12 GitHub Gists تلقائياً من مشروع Flutter

## 📋 المتطلبات

- Python 3.7+
- GitHub Personal Access Token مع صلاحية `gist`

## 🛠️ التثبيت

### 1. إنشاء المجلد
```bash
mkdir -p scripts
```

### 2. تثبيت المتطلبات
```bash
pip install -r requirements.txt
```

### 3. إعداد GitHub Token

#### Linux/Mac:
```bash
export GITHUB_GIST_TOKEN='ghp_your_token_here'
```

#### Windows (PowerShell):
```powershell
$env:GITHUB_GIST_TOKEN='ghp_your_token_here'
```

#### Windows (CMD):
```cmd
set GITHUB_GIST_TOKEN=ghp_your_token_here
```

## 🚀 الاستخدام

### تشغيل Script:
```bash
python scripts/update_gists.py
```

### تشغيل من مجلد المشروع:
```bash
cd flutter_application_oo
python scripts/update_gists.py
```

## 📊 الميزات

### ✨ الميزات الرئيسية:
- **تحديث 12 Gist** تلقائياً
- **دمج المجلدات** - يجمع كل ملفات `.dart` في مجلد واحد
- **إدارة الحجم** - اقتطاع تلقائي للملفات الكبيرة (900 KB)
- **واجهة ملونة** - رسائل واضحة مع الألوان والرموز
- **إحصائيات مفصلة** - تتبع النجاح والفشل
- **معالجة الأخطاء** - معالجة شاملة للأخطاء

### 📁 Gists المحدثة:
1. **Services** - `lib/services` → `services.dart`
2. **Screens** - `lib/screens` → `screens.dart`
3. **Repositories** - `lib/repositories` → `repositories.dart`
4. **Providers** - `lib/providers` → `providers.dart`
5. **Models** - `lib/models` → `models.dart`
6. **Localization** - `lib/l10n` → `l10n.dart`
7. **Theme** - `lib/theme` → `theme.dart`
8. **Utils** - `lib/utils` → `utils.dart`
9. **Widgets** - `lib/widgets` → `widgets.dart`
10. **Main** - `lib/main.dart` → `main.dart`
11. **Database** - `lib/database` → `database.dart`
12. **Dialogs** - `lib/dialogs` → `dialogs.dart`

## 🔧 التكوين

### تعديل Gist IDs:
عدل القائمة في `main()` function:

```python
gists = [
    ("your_gist_id", "lib/services", "services.dart", "Flutter Services"),
    # ... إضافة المزيد
]
```

### تغيير حد الحجم:
```python
class GistUpdater:
    MAX_SIZE = 900 * 1024  # 900 KB
```

## 📈 مثال على المخرجات

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🚀 Auto Update 12 GitHub Gists
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 التاريخ: 2025-01-13 15:30:45

✅ تم العثور على Token

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔄 بدء التحديث
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/12] 📌 معالجة lib/services...
✅ تم تحديث services.dart

[2/12] 📌 معالجة lib/screens...
✅ تم تحديث screens.dart

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 الإحصائيات النهائية
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

المجموع:    12
نجح:       12
فشل:        0
مقتطع:      0

✨ نجاح كامل! 100%

✨ تم التحديث بنجاح!
```

## 🐛 استكشاف الأخطاء

### خطأ: Token غير صحيح
```
❌ GITHUB_GIST_TOKEN غير موجود في متغيرات البيئة
```
**الحل:** تأكد من تعيين متغير البيئة بشكل صحيح

### خطأ: فشل في الاتصال
```
❌ خطأ في الاتصال: Connection timeout
```
**الحل:** تحقق من اتصال الإنترنت

### خطأ: الملف غير موجود
```
❌ الملف غير موجود: lib/services
```
**الحل:** تأكد من وجود المجلدات في المشروع

## 📝 ملاحظات

- **الحد الأقصى للحجم:** 900 KB لكل Gist
- **الملفات المقتطعة:** تُضاف رسالة تنبيه في نهاية الملف
- **الترميز:** UTF-8 لضمان دعم العربية
- **Timeout:** 30 ثانية لكل طلب API

## 🤝 المساهمة

لإضافة Gist جديد:
1. أضف معرف Gist في قائمة `gists`
2. حدد المسار والاسم والوصف
3. اختبر التحديث

## 🔐 Firebase Authentication Scripts

### تفعيل Anonymous Authentication

هذه السكريبتات تساعد في تفعيل Anonymous Authentication في Firebase Console.

#### للأنظمة Windows:
```bash
scripts\enable_auth.bat
```

#### للأنظمة Unix/Linux/macOS:
```bash
./scripts/enable_auth.sh
```

#### تشغيل مباشر:
```bash
cd scripts
pip install -r requirements.txt
python enable_anonymous_auth.py
```

### المتطلبات

- Python 3.6+
- pip
- Firebase Admin SDK (يتم تثبيته تلقائياً)

### ملاحظات مهمة

1. **Anonymous Authentication** يجب تفعيله يدوياً في Firebase Console
2. السكريبت يعطي تعليمات واضحة لتفعيل Anonymous Authentication
3. بعد التفعيل، أعد تشغيل التطبيق للتحقق من الحل

### استكشاف الأخطاء

إذا فشل السكريبت:

1. تأكد من تثبيت Python 3.6+
2. تأكد من تثبيت pip
3. تحقق من اتصال الإنترنت
4. راجع ملف `FIREBASE_AUTH_FIX_INSTRUCTIONS.md` للحل اليدوي

## 📄 الترخيص

هذا المشروع مفتوح المصدر ومتاح للاستخدام العام.

---

**المطور:** abdo288  
**التاريخ:** 2025-01-13  
**الإصدار:** 2.0.0
