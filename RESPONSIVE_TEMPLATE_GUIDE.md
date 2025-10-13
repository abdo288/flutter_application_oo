# دليل قوالب التصميم المتجاوب

## نظرة عامة
هذا الدليل يحتوي على قوالب جاهزة لإصلاح مشاكل pixel overflow في جميع أنواع الملفات.

---

## 1. قالب Dialog

### A. الهيكل الأساسي
```dart
import '../utils/responsive_helper.dart';

@override
Widget build(BuildContext context) => Dialog(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
  ),
  elevation: 8,
  child: ConstrainedBox(
    constraints: context.dialogConstraints,
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(
            child: SingleChildScrollView(
              physics: context.responsiveScrollPhysics,
              child: _buildContent(context),
            ),
          ),
          _buildActions(context),
        ],
      ),
    ),
  ),
);
```

### B. Header
```dart
Widget _buildHeader(BuildContext context) => Container(
  padding: context.responsivePadding,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue[600]!, Colors.blue[400]!],
    ),
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(AppConstants.borderRadius * 2),
      topRight: Radius.circular(AppConstants.borderRadius * 2),
    ),
  ),
  child: Row(
    children: [
      Container(
        padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          Icons.your_icon,
          color: Colors.white,
          size: context.isSmallScreen ? 20 : 24,
        ),
      ),
      SizedBox(width: context.responsiveSpacing),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Title',
              style: TextStyle(
                color: Colors.white,
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Subtitle',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: context.responsiveFontSize(12),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close, color: Colors.white),
        padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
        constraints: const BoxConstraints(),
      ),
    ],
  ),
);
```

### C. Content
```dart
Widget _buildContent(BuildContext context) => Padding(
  padding: context.responsivePadding,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Your content here
      // Use SizedBox(height: context.responsiveSpacing) for spacing
    ],
  ),
);
```

### D. Actions
```dart
Widget _buildActions(BuildContext context) => Container(
  padding: context.responsivePadding,
  decoration: BoxDecoration(
    color: Colors.grey[50],
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(AppConstants.borderRadius * 2),
      bottomRight: Radius.circular(AppConstants.borderRadius * 2),
    ),
  ),
  child: context.shouldUseVerticalLayout
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: _onConfirm,
              icon: const Icon(Icons.check, size: 18),
              label: Text(
                'Confirm',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing),
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel, size: 18),
              label: Text(
                'Cancel',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing),
              ),
            ),
          ],
        )
      : Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.cancel, size: 18),
                label: Text(
                  'Cancel',
                  style: TextStyle(fontSize: context.responsiveFontSize(14)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing),
                ),
              ),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _onConfirm,
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  'Confirm',
                  style: TextStyle(fontSize: context.responsiveFontSize(14)),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing),
                ),
              ),
            ),
          ],
        ),
);
```

---

## 2. قالب Screen/Tab

### A. الهيكل الأساسي
```dart
import '../utils/responsive_helper.dart';

@override
Widget build(BuildContext context) => Scaffold(
  appBar: AppBar(
    title: const Text('Screen Title'),
    toolbarHeight: context.appBarHeight,
  ),
  body: SafeArea(
    child: RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: context.responsiveScrollPhysics,
        slivers: [
          SliverPadding(
            padding: context.responsivePadding,
            sliver: SliverToBoxAdapter(
              child: _buildHeader(context),
            ),
          ),
          SliverPadding(
            padding: context.responsivePadding,
            sliver: _buildContent(context),
          ),
        ],
      ),
    ),
  ),
);
```

### B. Grid Layout
```dart
Widget _buildGrid(BuildContext context) => SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: context.responsiveGridColumns,
    crossAxisSpacing: context.responsiveSpacing,
    mainAxisSpacing: context.responsiveSpacing,
    childAspectRatio: context.responsiveAspectRatio,
  ),
  delegate: SliverChildBuilderDelegate(
    (context, index) => _buildGridItem(context, items[index]),
    childCount: items.length,
  ),
);
```

---

## 3. قالب Widget

### A. Card Widget
```dart
Widget _buildCard(BuildContext context, Item item) => Card(
  margin: EdgeInsets.all(context.responsiveSpacing),
  elevation: context.isSmallScreen ? 2 : 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(context.isSmallScreen ? 8 : 12),
  ),
  child: Padding(
    padding: context.responsivePadding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: context.responsiveFontSize(16),
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: context.responsiveSpacing * 0.5),
        Text(
          item.description,
          style: TextStyle(
            fontSize: context.responsiveFontSize(14),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  ),
);
```

### B. Row/Column Layout
```dart
Widget _buildLayout(BuildContext context) => context.shouldUseVerticalLayout
    ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWidget1(context),
          SizedBox(height: context.responsiveSpacing),
          _buildWidget2(context),
        ],
      )
    : Row(
        children: [
          Expanded(child: _buildWidget1(context)),
          SizedBox(width: context.responsiveSpacing),
          Expanded(child: _buildWidget2(context)),
        ],
      );
```

---

## 4. قالب Filter Widget

### A. الهيكل الأساسي
```dart
Widget build(BuildContext context) => Container(
  margin: EdgeInsets.symmetric(
    horizontal: context.responsiveSpacing,
    vertical: context.responsiveSpacing * 0.5,
  ),
  padding: context.responsivePadding,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: AppConstants.primaryColor.withOpacity(0.2),
    ),
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Filters',
        style: TextStyle(
          fontSize: context.responsiveFontSize(16),
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
      SizedBox(height: context.responsiveSpacing),
      _buildFilterOptions(context),
    ],
  ),
);
```

### B. Filter Chips
```dart
Widget _buildFilterChips(BuildContext context) => context.shouldUseWrap
    ? Wrap(
        spacing: context.responsiveSpacing * 0.5,
        runSpacing: context.responsiveSpacing * 0.5,
        children: _buildChips(context),
      )
    : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _buildChips(context),
        ),
      );

List<Widget> _buildChips(BuildContext context) => options.map((option) => 
  FilterChip(
    label: Text(
      option,
      style: TextStyle(fontSize: context.responsiveFontSize(12)),
    ),
    selected: selectedOption == option,
    onSelected: (selected) => _onOptionSelected(option),
  ),
).toList();
```

---

## 5. قالب Input Field

```dart
Widget _buildTextField({
  required BuildContext context,
  required TextEditingController controller,
  required String label,
  IconData? icon,
  String? Function(String?)? validator,
}) => Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
    border: Border.all(color: Colors.grey.withOpacity(0.3)),
  ),
  child: TextFormField(
    controller: controller,
    style: TextStyle(fontSize: context.responsiveFontSize(14)),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
      prefixIcon: icon != null
          ? Icon(icon, size: context.isSmallScreen ? 20 : 24)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        borderSide: BorderSide.none,
      ),
      filled: true,
      contentPadding: context.responsivePadding,
      isDense: context.isSmallScreen,
    ),
    validator: validator,
  ),
);
```

---

## 6. قالب Navigation

### A. BottomNavigationBar
```dart
BottomNavigationBar(
  currentIndex: _currentIndex,
  onTap: _onTabTapped,
  type: context.isSmallScreen 
      ? BottomNavigationBarType.shifting 
      : BottomNavigationBarType.fixed,
  selectedFontSize: context.responsiveFontSize(12),
  unselectedFontSize: context.responsiveFontSize(10),
  iconSize: context.isSmallScreen ? 22 : 24,
  items: items,
)
```

### B. TabBar
```dart
TabBar(
  controller: _tabController,
  isScrollable: context.shouldUseScrollableTabBar,
  labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
  unselectedLabelStyle: TextStyle(fontSize: context.responsiveFontSize(12)),
  tabs: tabs,
)
```

---

## ✅ Checklist للإصلاح

عند إصلاح أي ملف، تأكد من:

- [ ] إضافة `import '../utils/responsive_helper.dart';`
- [ ] تمرير `BuildContext context` لجميع build methods
- [ ] استبدال hard-coded values بـ responsive helpers
- [ ] استخدام `mainAxisSize: MainAxisSize.min` في Columns داخل Dialogs
- [ ] إضافة `Flexible` أو `Expanded` للـ widgets داخل Rows
- [ ] إضافة `maxLines` و `overflow` لجميع النصوص الطويلة
- [ ] استخدام vertical layout للشاشات الصغيرة
- [ ] اختبار على شاشات مختلفة

---

## 🎯 أمثلة سريعة

### قبل ❌
```dart
Container(
  width: 500,
  padding: EdgeInsets.all(16),
  child: Text('Title', style: TextStyle(fontSize: 18)),
)
```

### بعد ✅
```dart
ConstrainedBox(
  constraints: context.dialogConstraints,
  child: Padding(
    padding: context.responsivePadding,
    child: Text(
      'Title',
      style: TextStyle(fontSize: context.responsiveFontSize(18)),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  ),
)
```

---

*استخدم هذه القوالب لضمان consistency عبر التطبيق*

