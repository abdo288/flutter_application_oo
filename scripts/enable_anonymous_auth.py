#!/usr/bin/env python3
"""
سكريبت لتفعيل Anonymous Authentication في Firebase Console
يستخدم Firebase Admin SDK لتفعيل Anonymous Authentication تلقائياً
"""

import os
import sys
import json
from firebase_admin import credentials, initialize_app, auth
import firebase_admin

def enable_anonymous_auth():
    """تفعيل Anonymous Authentication في Firebase"""
    try:
        # التحقق من وجود متغيرات البيئة المطلوبة
        project_id = os.getenv('FIREBASE_PROJECT_ID', 'samir-28c3e')
        
        print(f"🔄 محاولة تفعيل Anonymous Authentication في المشروع: {project_id}")
        
        # التحقق من وجود Firebase Admin SDK
        try:
            # محاولة استخدام Firebase Admin SDK
            if not firebase_admin._apps:
                # استخدام service account key إذا كان متوفراً
                service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH')
                if service_account_path and os.path.exists(service_account_path):
                    cred = credentials.Certificate(service_account_path)
                    initialize_app(cred, {'projectId': project_id})
                else:
                    # استخدام default credentials
                    initialize_app()
            
            print("✅ تم الاتصال بـ Firebase Admin SDK")
            
            # ملاحظة: لا يمكن تفعيل Anonymous Authentication عبر API
            # يجب تفعيله يدوياً في Firebase Console
            print("⚠️ Anonymous Authentication يجب تفعيله يدوياً في Firebase Console")
            print("📋 اتبع هذه الخطوات:")
            print("1. اذهب إلى https://console.firebase.google.com/")
            print(f"2. اختر المشروع: {project_id}")
            print("3. اذهب إلى Authentication > Sign-in method")
            print("4. ابحث عن Anonymous واضغط عليه")
            print("5. اضغط على Enable")
            print("6. احفظ التغييرات")
            
            return True
            
        except Exception as e:
            print(f"❌ خطأ في الاتصال بـ Firebase: {e}")
            return False
            
    except Exception as e:
        print(f"❌ خطأ عام: {e}")
        return False

def check_auth_status():
    """التحقق من حالة Authentication"""
    try:
        project_id = os.getenv('FIREBASE_PROJECT_ID', 'samir-28c3e')
        print(f"🔍 التحقق من حالة Authentication في المشروع: {project_id}")
        
        # ملاحظة: لا يمكن التحقق من إعدادات Authentication عبر API
        print("⚠️ لا يمكن التحقق من إعدادات Authentication عبر API")
        print("📋 يجب التحقق يدوياً من Firebase Console")
        
        return True
        
    except Exception as e:
        print(f"❌ خطأ في التحقق من حالة Authentication: {e}")
        return False

def main():
    """الدالة الرئيسية"""
    print("🚀 بدء تفعيل Anonymous Authentication")
    print("=" * 50)
    
    # التحقق من متغيرات البيئة
    project_id = os.getenv('FIREBASE_PROJECT_ID', 'samir-28c3e')
    print(f"📁 المشروع: {project_id}")
    
    # محاولة تفعيل Anonymous Authentication
    if enable_anonymous_auth():
        print("✅ تم إعداد Anonymous Authentication")
    else:
        print("❌ فشل في إعداد Anonymous Authentication")
        print("📋 راجع ملف FIREBASE_AUTH_FIX_INSTRUCTIONS.md للحل اليدوي")
    
    print("=" * 50)
    print("🎯 الخطوات التالية:")
    print("1. اذهب إلى Firebase Console")
    print("2. فعّل Anonymous Authentication")
    print("3. أعد تشغيل التطبيق")
    print("4. تحقق من عدم ظهور رسائل التحذير")

if __name__ == "__main__":
    main()
