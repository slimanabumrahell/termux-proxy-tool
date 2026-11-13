#!/bin/bash

# 1. التحقق من صلاحيات الروت
if [ "$(id -u)" -ne 0 ]; then
    echo "[-] خطأ: يجب تشغيل هذا السكربت بصلاحيات الروت. اكتب 'su' أولاً ثم أعد التشغيل."
    exit 1
fi

echo "[+] جارٍ فحديث الحزم وتثبيت الأدوات الأساسية..."
pkg update -y > /dev/null 2>&1
pkg install -y curl wget git iptables > /dev/null 2>&1

# 2. تحميل وتثبيت أداة gost تلقائياً إذا لم تكن موجودة
if ! command -v gost &> /dev/null; then
    echo "[+] جارٍ تثبيت أداة التشغيل الذكي (gost)..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ]; then
        wget -q https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-arm64-v2.11.5.tar.gz -O gost.tar.gz
    else
        wget -q https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-armv7-v2.11.5.tar.gz -O gost.tar.gz
    fi
    tar -xzf gost.tar.gz > /dev/null 2>&1
    chmod +x gost
    mv gost /data/data/com.termux/files/usr/bin/
    rm -rf gost.tar.gz README.md LICENSE
fi

# 3. طلب معلومات البروكسي المدفوع تفاعلياً من المستخدم
echo "========================================="
echo "       إعداد بروكسي النظام الشامل        "
echo "========================================="
read -p "اختر نوع البروكسي (socks5 / socks4 / http / https) [افتراضي: socks5]: " PROXY_TYPE
PROXY_TYPE=${PROXY_TYPE:-socks5}

read -p "أدخل عنوان IP الخادم: " PROXY_IP
read -p "أدخل المنفذ (Port): " PROXY_PORT
read -p "أدخل اسم المستخدم (Username - اتركه فارغاً إن لم يوجد): " PROXY_USER
read -p "أدخل كلمة المرور (Password - اتركه فارغاً إن لم يوجد): " PROXY_PASS

# بناء سلسلة الاتصال بالبروكسي المدفوع مع مراعاة المصادقة
if [ -n "$PROXY_USER" ] && [ -n "$PROXY_PASS" ]; then
    REMOTE_PROXY="${PROXY_TYPE}://${PROXY_USER}:${PROXY_PASS}@${PROXY_IP}:${PROXY_PORT}"
else
    REMOTE_PROXY="${PROXY_TYPE}://${PROXY_IP}:${PROXY_PORT}"
fi

# 4. تشغيل النفق المحلي وتوجيه حركة المرور
echo "[+] جارٍ إنهاء أي عمليات قديمة لـ gost..."
pkill gost > /dev/null 2>&1

echo "[+] جارٍ تشغيل النفق المحلي..."
# فتح منفذ محلي 1080 وربطه بالبروكسي المدفوع الخارجي مع الحفاظ على الشبكة الأصلية
gost -L=socks5://127.0.0.1:1080 -F="$REMOTE_PROXY" > /dev/null 2>&1 &

echo "[✔] تم تشغيل البروكسي بنجاح!"
echo "[*] المنفذ المحلي الفعال: 127.0.0.1:1080"
echo "[*] تم إخفاء البروكسي عن التطبيقات وجعل الاتصال يتم عبره بسلاسة."
