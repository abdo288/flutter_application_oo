#!/bin/bash
# سكريبت تشغيل اختبارات End-to-End على Linux/macOS
# هذا السكريبت يشغل جميع اختبارات E2E مع Patrol

echo "========================================"
echo "   تشغيل اختبارات End-to-End مع Patrol"
echo "========================================"
echo

# التحقق من تثبيت Flutter
echo "[1/6] التحقق من Flutter..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter غير مثبت أو غير موجود في PATH"
    echo "يرجى تثبيت Flutter أولاً"
    exit 1
fi
echo "✅ Flutter مثبت"

# التحقق من تثبيت Firebase CLI
echo "[2/6] التحقق من Firebase CLI..."
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI غير مثبت"
    echo "يرجى تثبيت Firebase CLI أولاً: npm install -g firebase-tools"
    exit 1
fi
echo "✅ Firebase CLI مثبت"

# التحقق من تثبيت Patrol CLI
echo "[3/6] التحقق من Patrol CLI..."
if ! command -v patrol &> /dev/null; then
    echo "❌ Patrol CLI غير مثبت"
    echo "يتم تثبيت Patrol CLI..."
    dart pub global activate patrol_cli
    if [ $? -ne 0 ]; then
        echo "❌ فشل في تثبيت Patrol CLI"
        exit 1
    fi
fi
echo "✅ Patrol CLI مثبت"

# تثبيت التبعيات
echo "[4/6] تثبيت التبعيات..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ فشل في تثبيت تبعيات Flutter"
    exit 1
fi
echo "✅ تم تثبيت التبعيات"

# تشغيل Firebase Emulators
echo "[5/6] تشغيل Firebase Emulators..."
echo "يرجى الانتظار حتى يتم تشغيل Emulators..."
firebase emulators:start --only firestore,auth,storage &
FIREBASE_PID=$!
sleep 10
echo "✅ تم تشغيل Firebase Emulators"

# تشغيل اختبارات E2E
echo "[6/6] تشغيل اختبارات E2E..."
echo
echo "========================================"
echo "   بدء تشغيل الاختبارات..."
echo "========================================"
echo

# إنشاء مجلدات النتائج
mkdir -p test/e2e/screenshots
mkdir -p test/e2e/logs

# تشغيل الاختبارات الرئيسية
patrol test --target test/e2e/main_e2e_tests.dart --screenshots test/e2e/screenshots/ --log-file test/e2e/logs/main_tests.log

if [ $? -eq 0 ]; then
    echo
    echo "========================================"
    echo "   ✅ تم تشغيل جميع الاختبارات بنجاح!"
    echo "========================================"
    echo
    echo "📊 النتائج:"
    echo "   - لقطات الشاشة: test/e2e/screenshots/"
    echo "   - سجلات الاختبارات: test/e2e/logs/"
    echo
else
    echo
    echo "========================================"
    echo "   ❌ فشل في بعض الاختبارات"
    echo "========================================"
    echo
    echo "📊 النتائج:"
    echo "   - لقطات الشاشة: test/e2e/screenshots/"
    echo "   - سجلات الاختبارات: test/e2e/logs/"
    echo
    echo "يرجى مراجعة السجلات لمعرفة سبب الفشل"
fi

# إيقاف Firebase Emulators
echo "إيقاف Firebase Emulators..."
kill $FIREBASE_PID 2>/dev/null
pkill -f "firebase emulators" 2>/dev/null

echo
echo "انتهى التشغيل."
