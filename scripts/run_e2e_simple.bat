@echo off
REM Ultra Simple E2E Test Runner
REM This script runs E2E tests with minimal checks

echo Starting E2E Tests...
echo.

REM Create directories if they don't exist
if not exist "test\e2e\screenshots" mkdir "test\e2e\screenshots"
if not exist "test\e2e\logs" mkdir "test\e2e\logs"

REM Start Firebase Emulators in background
echo Starting Firebase Emulators...
start /B firebase emulators:start --only firestore,auth,storage

REM Wait for emulators to start
echo Waiting for emulators to start...
timeout /t 15 /nobreak >nul

REM Run the tests
echo Running E2E tests...
flutter test test/e2e/main_e2e_tests.dart --reporter=expanded

REM Stop emulators
echo Stopping emulators...
taskkill /F /IM firebase.exe >nul 2>&1

echo.
echo Tests completed!
pause
