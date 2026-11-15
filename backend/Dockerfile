# از ایمیج ساخته‌شده V1 استفاده می‌کنیم (بدون نیاز به pull)
FROM asset-dashboard-backend:latest

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# فقط کد رو جایگزین می‌کنیم (پکیج‌ها از قبل نصب‌شدن)
COPY . .

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
