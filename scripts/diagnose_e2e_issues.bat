@echo off
chcp 65001 >nul
REM Diagnostic Script for E2E Testing Issues
REM This script helps diagnose and fix common issues

echo ========================================
echo    E2E Testing Diagnostic Tool
echo ========================================
echo.

echo [DIAGNOSTIC] Checking system environment...
echo.

REM Check if we're in the right directory
echo [1/8] Checking current directory...
echo Current directory: %CD%
if exist "pubspec.yaml" (
    echo [OK] Found pubspec.yaml - correct directory
) else (
    echo [ERROR] pubspec.yaml not found - wrong directory
    echo Please run this script from the Flutter project root
    pause
    exit /b 1
)

REM Check Flutter installation
echo [2/8] Checking Flutter installation...
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter not found in PATH
    echo Please add Flutter to your system PATH
    echo.
    echo To fix this:
    echo 1. Find your Flutter installation directory
    echo 2. Add it to Windows PATH environment variable
    echo 3. Restart your terminal
    pause
    exit /b 1
) else (
    echo [OK] Flutter found in PATH
)

REM Try to get Flutter version
echo [3/8] Getting Flutter version...
flutter --version
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get Flutter version
    echo This might indicate a Flutter installation issue
    pause
    exit /b 1
) else (
    echo [OK] Flutter version retrieved successfully
)

REM Check Dart installation
echo [4/8] Checking Dart installation...
where dart >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Dart not found in PATH
    echo Dart should be included with Flutter
    pause
    exit /b 1
) else (
    echo [OK] Dart found in PATH
)

REM Check Firebase CLI
echo [5/8] Checking Firebase CLI...
where firebase >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Firebase CLI not found
    echo Installing Firebase CLI...
    npm install -g firebase-tools
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install Firebase CLI
        echo Please install Node.js first: https://nodejs.org/
        pause
        exit /b 1
    )
) else (
    echo [OK] Firebase CLI found
)

REM Check if Firebase is logged in
echo [6/8] Checking Firebase authentication...
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Not logged in to Firebase
    echo Please run: firebase login
    echo.
    echo Starting Firebase login...
    firebase login
    if %errorlevel% neq 0 (
        echo [ERROR] Firebase login failed
        pause
        exit /b 1
    )
) else (
    echo [OK] Firebase authentication working
)

REM Check Flutter dependencies
echo [7/8] Checking Flutter dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get Flutter dependencies
    echo This might indicate a project configuration issue
    pause
    exit /b 1
) else (
    echo [OK] Flutter dependencies installed
)

REM Check if E2E test files exist
echo [8/8] Checking E2E test files...
if exist "test\e2e\main_e2e_tests.dart" (
    echo [OK] E2E test files found
) else (
    echo [ERROR] E2E test files not found
    echo Please make sure the E2E tests are properly set up
    pause
    exit /b 1
)

echo.
echo ========================================
echo    Diagnostic completed successfully!
echo ========================================
echo.

echo [INFO] All checks passed. You can now run E2E tests.
echo.
echo To run tests manually:
echo 1. Start Firebase Emulators: firebase emulators:start --only firestore,auth,storage
echo 2. Run tests: flutter test test/e2e/main_e2e_tests.dart
echo.

echo Press any key to continue...
pause >nul
