#!/bin/bash

# تشغيل اختبارات لوحة التحكم

echo "========================================"
echo " تشغيل اختبارات لوحة التحكم Dashboard"
echo "========================================"
echo ""

# التحقق من وجود Flutter
if ! command -v flutter &> /dev/null; then
    echo "خطأ: Flutter غير مثبت أو غير موجود في PATH"
    exit 1
fi

echo "جاري تشغيل الاختبارات..."
echo ""

# تشغيل الاختبارات
flutter test integration_test/dashboard_test.dart --reporter expanded

echo ""
echo "========================================"
echo " انتهت الاختبارات"
echo "========================================"

