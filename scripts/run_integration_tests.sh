#!/bin/bash

# Script لتشغيل اختبارات التكامل مع Firebase Emulators
# للاستخدام على macOS/Linux

echo "========================================"
echo "   Firebase Integration Tests Runner"
echo "========================================"
echo ""

# التحقق من وجود Flutter
if ! command -v flutter &> /dev/null; then
    echo "[ERROR] Flutter غير مثبت أو غير موجود في PATH"
    exit 1
fi

# التحقق من وجود Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "[ERROR] Firebase CLI غير مثبت أو غير موجود في PATH"
    echo ""
    echo "يرجى تثبيت Firebase CLI أولاً:"
    echo "  npm install -g firebase-tools"
    exit 1
fi

echo "[1/4] التحقق من Emulators..."
echo ""

# التحقق من تشغيل Emulators
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "[OK] Emulators تعمل بالفعل"
else
    echo "[WARNING] Emulators لا تعمل"
    echo ""
    echo "يرجى تشغيل Emulators في Terminal منفصل أولاً:"
    echo "  firebase emulators:start --only firestore,auth,storage"
    echo ""
    read -p "هل تريد تشغيل Emulators الآن؟ (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[INFO] جاري تشغيل Emulators..."
        firebase emulators:start --only firestore,auth,storage > /dev/null 2>&1 &
        EMULATOR_PID=$!
        echo "[INFO] انتظر 10 ثوانٍ حتى تبدأ Emulators..."
        sleep 10
        echo "[INFO] Emulators بدأت (PID: $EMULATOR_PID)"
    else
        echo "تم الإلغاء"
        exit 1
    fi
fi

echo ""
echo "[2/4] جاري تشغيل تبعيات المشروع..."
echo ""
flutter pub get

echo ""
echo "[3/4] جاري تشغيل اختبارات التكامل..."
echo ""
flutter test test/integration/

EXIT_CODE=$?

echo ""
echo "[4/4] الاختبارات اكتملت!"
echo ""
echo "========================================"
echo ""

# سؤال المستخدم عن عرض Emulator UI
read -p "هل تريد فتح Firebase Emulator UI؟ (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open http://localhost:4000
    else
        # Linux
        xdg-open http://localhost:4000 2>/dev/null || \
        sensible-browser http://localhost:4000 2>/dev/null || \
        echo "يرجى فتح http://localhost:4000 في المتصفح يدوياً"
    fi
fi

echo ""
echo "انتهى!"
exit $EXIT_CODE
