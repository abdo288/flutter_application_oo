@echo off
chcp 65001 >nul
REM Enhanced E2E Testing Script for Windows
REM This script runs all E2E tests with Patrol

echo ========================================
echo    E2E Testing with Patrol
echo ========================================
echo.

REM Check Flutter installation
echo [1/6] Checking Flutter...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo Please install Flutter first
    pause
    exit /b 1
)
echo [SUCCESS] Flutter is installed

REM Check Firebase CLI installation
echo [2/6] Checking Firebase CLI...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Firebase CLI is not installed
    echo Please install Firebase CLI first: npm install -g firebase-tools
    pause
    exit /b 1
)
echo [SUCCESS] Firebase CLI is installed

REM Check Patrol CLI installation
echo [3/6] Checking Patrol CLI...
patrol --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Patrol CLI is not installed
    echo Installing Patrol CLI...
    dart pub global activate patrol_cli
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install Patrol CLI
        pause
        exit /b 1
    )
)
echo [SUCCESS] Patrol CLI is installed

REM Install dependencies
echo [4/6] Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Flutter dependencies
    pause
    exit /b 1
)
echo [SUCCESS] Dependencies installed

REM Start Firebase Emulators
echo [5/6] Starting Firebase Emulators...
echo Please wait while Emulators are starting...
start /B firebase emulators:start --only firestore,auth,storage
timeout /t 15 /nobreak >nul
echo [SUCCESS] Firebase Emulators started

REM Create result directories
if not exist "test\e2e\screenshots" mkdir "test\e2e\screenshots"
if not exist "test\e2e\logs" mkdir "test\e2e\logs"

REM Run E2E tests
echo [6/6] Running E2E tests...
echo.
echo ========================================
echo    Starting test execution...
echo ========================================
echo.

REM Try different test approaches
echo [INFO] Attempting to run tests with flutter test...
flutter test test/e2e/main_e2e_tests.dart --reporter=expanded

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    [SUCCESS] All tests completed successfully!
    echo ========================================
    echo.
    echo Results:
    echo    - Screenshots: test\e2e\screenshots\
    echo    - Test logs: test\e2e\logs\
    echo.
) else (
    echo.
    echo ========================================
    echo    [WARNING] Some tests may have failed
    echo ========================================
    echo.
    echo Results:
    echo    - Screenshots: test\e2e\screenshots\
    echo    - Test logs: test\e2e\logs\
    echo.
    echo Please check the logs for details
)

REM Stop Firebase Emulators
echo Stopping Firebase Emulators...
taskkill /F /IM firebase.exe >nul 2>&1
taskkill /F /IM java.exe /FI "WINDOWTITLE eq Firebase*" >nul 2>&1

echo.
echo Test execution completed. Press any key to exit...
pause >nul
