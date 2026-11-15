#!/bin/bash
# ============================================================
# 🚀 ره‌آورد (rahavard) - استارت کامل
# ============================================================
# بک‌اند: 8001 | فرانت‌اند: 3001 | DB: 5434 | Redis: 6380
# ============================================================

set -e
cd "$(dirname "$0")"

echo ""
echo "============================================"
echo "🚀 ره‌آورد (rahavard) - شروع"
echo "============================================"
echo ""

# ============================================
# 1. چک کردن Colima
# ============================================
echo "🔍 چک کردن Colima..."
if ! colima status > /dev/null 2>&1; then
    echo "⚠️  Colima در حال اجرا نیست. در حال استارت..."
    colima start
else
    echo "✅ Colima در حال اجراست."
fi

# ============================================
# 2. استارت بک‌اند + دیتابیس‌ها
# ============================================
echo ""
echo "📦 استارت بک‌اند (Django + PostgreSQL + Redis + Neo4j)..."
docker compose up -d

# صبر برای آماده شدن بک‌اند
echo "⏳ صبر برای آماده شدن بک‌اند..."
for i in {1..30}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/admin/ 2>/dev/null | grep -q "200\|302"; then
        echo "✅ بک‌اند آماده است."
        break
    fi
    sleep 1
done

# ============================================
# 3. بکاپ دیتابیس
# ============================================
echo ""
echo "💾 گرفتن بکاپ دیتابیس..."
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/rahavard_backup_$(date +%Y%m%d_%H%M%S).sql"

if docker compose exec -T db pg_dump -U rahavard_user rahavard_db > "$BACKUP_FILE" 2>/dev/null; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "✅ بکاپ ذخیره شد: $BACKUP_FILE ($SIZE)"
    # حذف بکاپ‌های قدیمی‌تر از 30 روز
    find "$BACKUP_DIR" -name "*.sql" -type f -mtime +30 -delete 2>/dev/null || true
else
    echo "⚠️  بکاپ ناموفق بود، ادامه می‌دهیم..."
    rm -f "$BACKUP_FILE" 2>/dev/null || true
fi

# ============================================
# 4. پاکسازی پورت 3001
# ============================================
echo ""
echo "🧹 پاکسازی پورت 3001..."
lsof -ti:3001 | xargs kill -9 2>/dev/null || echo "✅ پورت 3001 آزاد است"

# ============================================
# 5. پاکسازی کش فرانت‌اند
# ============================================
echo "🧹 پاکسازی کش فرانت‌اند..."
if [ -d "frontend" ]; then
    cd frontend
    rm -rf .next .turbo node_modules/.cache 2>/dev/null || true

    # اگه node_modules نبود، نصب کن
    if [ ! -d "node_modules" ]; then
        echo "📥 نصب پکیج‌های npm (اولین بار)..."
        npm install
    fi

    # ============================================
    # 6. استارت فرانت‌اند روی پورت 3001
    # ============================================
    echo ""
    echo "🎨 استارت فرانت‌اند (Next.js) روی پورت 3001..."
    npm run dev -- -p 3001 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > /tmp/rahavard-frontend.pid
    cd ..
else
    echo "⚠️  پوشه frontend/ هنوز ساخته نشده — فقط بک‌اند بالا آمد."
    echo "   (بعداً با کپی frontend و npm install، این مرحله هم انجام می‌شه)"
fi

# ============================================
# 7. نمایش اطلاعات
# ============================================
echo ""
echo "============================================"
echo "✅ ره‌آورد با موفقیت بالا آمد! 🎉"
echo "============================================"
echo "📍 Frontend:  http://localhost:3001"
echo "📍 Backend:   http://localhost:8001"
echo "📍 Swagger:   http://localhost:8001/api/docs/"
echo "📍 Admin:     http://localhost:8001/admin/"
echo "📍 Neo4j:     http://localhost:7475"
echo "📁 Backup:    $BACKUP_FILE"
echo ""
echo "📋 برای توقف کامل: ./stop.sh"
echo "📋 برای مشاهده لاگ‌ها: ./logs.sh"
echo "============================================"
