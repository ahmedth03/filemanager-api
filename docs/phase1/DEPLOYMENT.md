# HarfiDar — دليل النشر والتشغيل

## المتطلبات الأساسية

```bash
# Node.js 20+
node --version

# PostgreSQL 15+
psql --version

# Redis 7+
redis-server --version

# Flutter 3.16+
flutter --version
```

## 1. إعداد Backend

```bash
cd backend

# نسخ ملف البيئة
cp .env.example .env
# عدّل القيم في .env

# تثبيت المكتبات
npm install

# توليد Prisma Client
npm run prisma:generate

# تطبيق الـ migrations
npm run prisma:migrate

# بذر قاعدة البيانات (58 ولاية + تخصصات + admin)
npm run prisma:seed

# تشغيل في وضع التطوير
npm run start:dev

# تشغيل في الإنتاج
npm run build
npm run start:prod
```

## 2. إعداد Frontend Flutter

```bash
cd frontend

# تثبيت packages
flutter pub get

# تشغيل على محاكي Android
flutter run

# بناء APK
flutter build apk --release

# بناء AAB للنشر على Google Play
flutter build appbundle --release

# بناء iOS
flutter build ipa --release
```

## 3. متغيرات البيئة المطلوبة

```env
DATABASE_URL=postgresql://user:password@localhost:5432/harfidar_db
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=<super-secret-key>
JWT_REFRESH_SECRET=<super-secret-refresh-key>
CLOUDINARY_CLOUD_NAME=<your-cloudinary-name>
CLOUDINARY_API_KEY=<your-cloudinary-key>
CLOUDINARY_API_SECRET=<your-cloudinary-secret>
```

## 4. حساب الإدارة الافتراضي

```
Email: admin@harfidar.dz
Password: Admin@123456
```
**تغيير كلمة المرور فور الدخول الأول!**

## 5. رابط Swagger

```
http://localhost:3000/api/docs
```

## 6. WebSocket الاتصال

```javascript
// Socket.io client connection
const socket = io('http://localhost:3000/chat', {
  auth: { token: 'YOUR_JWT_TOKEN' }
});

socket.emit('join:room', { roomId: 'ROOM_ID' });
socket.on('message:new', (message) => { /* handle */ });
```
