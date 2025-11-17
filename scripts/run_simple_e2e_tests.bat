@echo off
chcp 65001 >nul
REM Simple E2E Testing Script
REM This script runs basic E2E tests

echo ========================================
echo    Simple E2E Testing
echo ========================================
echo.

REM Check Flutter
echo [1/4] Checking Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter not found
    pause
    exit /b 1
)
echo [OK] Flutter found

REM Install dependencies
echo [2/4] Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies installed

REM Start Firebase Emulators
echo [3/4] Starting Firebase Emulators...
start /B firebase emulators:start --only firestore,auth,storage
timeout /t 10 /nobreak >nul
echo [OK] Emulators started

REM Run tests
echo [4/4] Running tests...
echo.
echo ========================================
echo    Running E2E Tests...
echo ========================================
echo.

REM Create directories
if not exist "test\e2e\screenshots" mkdir "test\e2e\screenshots"
if not exist "test\e2e\logs" mkdir "test\e2e\logs"

REM Run tests with flutter test
flutter test test/e2e/main_e2e_tests.dart --reporter=expanded

echo.
echo ========================================
echo    Test execution completed
echo ========================================
echo.

REM Stop emulators
echo Stopping emulators...
taskkill /F /IM firebase.exe >nul 2>&1

echo Press any key to exit...
pause >nul
