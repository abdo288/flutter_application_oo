# معالجات العمليات في تبويب المخزون

هذا المجلد يحتوي على معالجات العمليات المختلفة في تبويب المخزون (عرض قائمة المخزون)، مقسمة حسب الوظيفة لسهولة الصيانة والتنظيم.

## هيكل الملفات

### الملفات الرئيسية
- **`action_handlers.dart`** - الملف الرئيسي الذي يجمع جميع المعالجات
- **`edit_handler.dart`** - معالج عمليات التعديل
- **`delete_handler.dart`** - معالج عمليات الحذف
- **`print_handler.dart`** - معالج عمليات الطباعة

### الملفات المساعدة
- **`delete_dialog.dart`** - نافذة تأكيد الحذف
- **`print_options_dialog.dart`** - نافذة خيارات الطباعة
- **`print_utils.dart`** - أدوات مساعدة للطباعة

## الوظائف

### EditHandler
- `showEditDialog()` - عرض نافذة التعديل

### DeleteHandler
- `confirmAndDeleteItem()` - تأكيد وحذف العنصر

### PrintHandler
- `printBarcode()` - طباعة الباركود

## الاستخدام

```dart
// التعديل
await EditHandler.showEditDialog(context, item);

// الحذف
await DeleteHandler.confirmAndDeleteItem(context, ref, item);

// الطباعة
await PrintHandler.printBarcode(context, item);
```

## المميزات

- **تنظيم واضح**: كل معالج في ملف منفصل
- **سهولة الصيانة**: تعديل وظيفة واحدة دون التأثير على الأخرى
- **إعادة الاستخدام**: يمكن استخدام المعالجات في أماكن أخرى
- **اختبار منفصل**: يمكن اختبار كل معالج بشكل منفصل
