@echo off
REM تشغيل اختبارات لوحة التحكم
echo ========================================
echo  تشغيل اختبارات لوحة التحكم Dashboard
echo ========================================
echo.

REM التحقق من وجود Flutter
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo خطأ: Flutter غير مثبت أو غير موجود في PATH
    pause
    exit /b 1
)

echo جاري تشغيل الاختبارات...
echo.

REM تشغيل الاختبارات
flutter test integration_test/dashboard_test.dart --reporter expanded

echo.
echo ========================================
echo  انتهت الاختبارات
echo ========================================
pause

