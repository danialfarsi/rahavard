#!/bin/bash
# ============================================================
# 🛑 ره‌آورد (rahavard) - توقف کامل
# ============================================================
cd "$(dirname "$0")"

echo ""
echo "============================================"
echo "🛑 توقف ره‌آورد"
echo "============================================"
echo ""

# 1. توقف فرانت‌اند
if [ -f /tmp/rahavard-frontend.pid ]; then
    PID=$(cat /tmp/rahavard-frontend.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "🎨 توقف فرانت‌اند (PID: $PID)..."
        kill $PID 2>/dev/null || true
    fi
    rm -f /tmp/rahavard-frontend.pid
fi

# پاکسازی هر پروسس Next.js روی پورت 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# 2. توقف Docker
echo "🐳 توقف Docker Compose..."
docker compose down

echo ""
echo "============================================"
echo "✅ همه سرویس‌ها متوقف شدند."
echo "============================================"
echo ""
echo "💡 برای حذف کامل داده‌ها (دیتابیس/ولوم‌ها):"
echo "   docker compose down -v"
echo ""
