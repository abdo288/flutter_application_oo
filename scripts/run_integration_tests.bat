@echo off
REM Script لتشغيل اختبارات التكامل مع Firebase Emulators
REM للاستخدام على Windows

echo ========================================
echo    Firebase Integration Tests Runner
echo ========================================
echo.

REM التحقق من وجود Flutter
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Flutter غير مثبت أو غير موجود في PATH
    pause
    exit /b 1
)

REM التحقق من وجود Firebase CLI
where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Firebase CLI غير مثبت أو غير موجود في PATH
    echo. 
    echo يرجى تثبيت Firebase CLI أولاً:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

echo [1/4] التحقق من Emulators...
echo.

REM التحقق من تشغيل Emulators
curl -s http://localhost:8080 >nul 2>nul
if %errorlevel% equ 0 (
    echo [OK] Emulators تعمل بالفعل
) else (
    echo [WARNING] Emulators لا تعمل
    echo.
    echo يرجى تشغيل Emulators في Terminal منفصل أولاً:
    echo   firebase emulators:start --only firestore,auth,storage
    echo.
    echo أو اضغط Y لتشغيلها الآن...
    choice /c YN /n /m "تشغيل Emulators الآن (Y/N)? "
    if errorlevel 2 (
        echo تم الإلغاء
        pause
        exit /b 1
    )
    if errorlevel 1 (
        echo [INFO] جاري تشغيل Emulators...
        start "Firebase Emulators" cmd /k "firebase emulators:start --only firestore,auth,storage"
        echo.
        echo [INFO] انتظر 10 ثوانٍ حتى تبدأ Emulators...
        timeout /t 10 /nobreak >nul
    )
)

echo.
echo [2/4] جاري تشغيل تبعيات المشروع...
echo.
call flutter pub get

echo.
echo [3/4] جاري تشغيل اختبارات التكامل...
echo.
call flutter test test/integration/

echo.
echo [4/4] الاختبارات اكتملت!
echo.
echo ========================================
echo.

REM سؤال المستخدم عن عرض النتائج
choice /c YN /n /m "هل تريد فتح Firebase Emulator UI (Y/N)? "
if errorlevel 1 (
    start http://localhost:4000
)

echo.
echo انتهى!
pause
