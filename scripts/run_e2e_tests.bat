@echo off
REM سكريبت تشغيل اختبارات End-to-End على Windows
REM هذا السكريبت يشغل جميع اختبارات E2E مع Patrol

echo ========================================
echo    تشغيل اختبارات End-to-End مع Patrol
echo ========================================
echo.

REM التحقق من تثبيت Flutter
echo [1/6] التحقق من Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter غير مثبت أو غير موجود في PATH
    echo يرجى تثبيت Flutter أولاً
    pause
    exit /b 1
)
echo ✅ Flutter مثبت

REM التحقق من تثبيت Firebase CLI
echo [2/6] التحقق من Firebase CLI...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI غير مثبت
    echo يرجى تثبيت Firebase CLI أولاً: npm install -g firebase-tools
    pause
    exit /b 1
)
echo ✅ Firebase CLI مثبت

REM التحقق من تثبيت Patrol CLI
echo [3/6] التحقق من Patrol CLI...
patrol --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Patrol CLI غير مثبت
    echo يتم تثبيت Patrol CLI...
    dart pub global activate patrol_cli
    if %errorlevel% neq 0 (
        echo ❌ فشل في تثبيت Patrol CLI
        pause
        exit /b 1
    )
)
echo ✅ Patrol CLI مثبت

REM تثبيت التبعيات
echo [4/6] تثبيت التبعيات...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ فشل في تثبيت تبعيات Flutter
    pause
    exit /b 1
)
echo ✅ تم تثبيت التبعيات

REM تشغيل Firebase Emulators
echo [5/6] تشغيل Firebase Emulators...
echo يرجى الانتظار حتى يتم تشغيل Emulators...
start /B firebase emulators:start --only firestore,auth,storage
timeout /t 10 /nobreak >nul
echo ✅ تم تشغيل Firebase Emulators

REM تشغيل اختبارات E2E
echo [6/6] تشغيل اختبارات E2E...
echo.
echo ========================================
echo    بدء تشغيل الاختبارات...
echo ========================================
echo.

REM إنشاء مجلدات النتائج
if not exist "test\e2e\screenshots" mkdir "test\e2e\screenshots"
if not exist "test\e2e\logs" mkdir "test\e2e\logs"

REM تشغيل الاختبارات الرئيسية
patrol test --target test/e2e/main_e2e_tests.dart --screenshots test/e2e/screenshots/ --log-file test/e2e/logs/main_tests.log

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    ✅ تم تشغيل جميع الاختبارات بنجاح!
    echo ========================================
    echo.
    echo 📊 النتائج:
    echo    - لقطات الشاشة: test\e2e\screenshots\
    echo    - سجلات الاختبارات: test\e2e\logs\
    echo.
) else (
    echo.
    echo ========================================
    echo    ❌ فشل في بعض الاختبارات
    echo ========================================
    echo.
    echo 📊 النتائج:
    echo    - لقطات الشاشة: test\e2e\screenshots\
    echo    - سجلات الاختبارات: test\e2e\logs\
    echo.
    echo يرجى مراجعة السجلات لمعرفة سبب الفشل
)

REM إيقاف Firebase Emulators
echo إيقاف Firebase Emulators...
taskkill /F /IM firebase.exe >nul 2>&1
taskkill /F /IM java.exe /FI "WINDOWTITLE eq Firebase*" >nul 2>&1

echo.
echo انتهى التشغيل. اضغط أي مفتاح للخروج...
pause >nul
