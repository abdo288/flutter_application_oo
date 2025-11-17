@echo off
echo 🚀 تفعيل Anonymous Authentication في Firebase
echo ================================================

REM التحقق من وجود Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python غير مثبت أو غير موجود في PATH
    echo 📥 يرجى تثبيت Python من https://python.org
    pause
    exit /b 1
)

REM التحقق من وجود pip
pip --version >nul 2>&1
if errorlevel 1 (
    echo ❌ pip غير متوفر
    echo 📥 يرجى تثبيت pip
    pause
    exit /b 1
)

echo ✅ Python متوفر

REM تثبيت المتطلبات
echo 📦 تثبيت المتطلبات...
pip install -r requirements.txt

if errorlevel 1 (
    echo ❌ فشل في تثبيت المتطلبات
    pause
    exit /b 1
)

echo ✅ تم تثبيت المتطلبات

REM تشغيل السكريبت
echo 🔄 تشغيل سكريبت تفعيل Anonymous Authentication...
python enable_anonymous_auth.py

if errorlevel 1 (
    echo ❌ فشل في تشغيل السكريبت
    pause
    exit /b 1
)

echo ✅ تم تشغيل السكريبت بنجاح
echo.
echo 📋 الخطوات التالية:
echo 1. اذهب إلى Firebase Console
echo 2. فعّل Anonymous Authentication
echo 3. أعد تشغيل التطبيق
echo.
pause
