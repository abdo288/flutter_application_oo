#!/bin/bash

echo "🚀 تفعيل Anonymous Authentication في Firebase"
echo "================================================"

# التحقق من وجود Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 غير مثبت أو غير موجود في PATH"
    echo "📥 يرجى تثبيت Python3"
    exit 1
fi

echo "✅ Python3 متوفر"

# التحقق من وجود pip
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 غير متوفر"
    echo "📥 يرجى تثبيت pip3"
    exit 1
fi

echo "✅ pip3 متوفر"

# تثبيت المتطلبات
echo "📦 تثبيت المتطلبات..."
pip3 install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ فشل في تثبيت المتطلبات"
    exit 1
fi

echo "✅ تم تثبيت المتطلبات"

# تشغيل السكريبت
echo "🔄 تشغيل سكريبت تفعيل Anonymous Authentication..."
python3 enable_anonymous_auth.py

if [ $? -ne 0 ]; then
    echo "❌ فشل في تشغيل السكريبت"
    exit 1
fi

echo "✅ تم تشغيل السكريبت بنجاح"
echo ""
echo "📋 الخطوات التالية:"
echo "1. اذهب إلى Firebase Console"
echo "2. فعّل Anonymous Authentication"
echo "3. أعد تشغيل التطبيق"
echo ""
