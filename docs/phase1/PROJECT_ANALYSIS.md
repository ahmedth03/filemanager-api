# حرفي دار (HarfiDar) — تحليل المشروع الشامل
## المرحلة الأولى: التحليل والهندسة المعمارية

---

## 1. هوية المنصة

| العنصر | التفاصيل |
|---|---|
| **الاسم** | حرفي دار – HarfiDar |
| **الشعار المقترح** | حـد (أول حرف من حرفي + أول حرف من دار) |
| **الوصف التسويقي** | "ابحث عن حرفي محترف أو استأجر شقتك في ثوانٍ — كل ما تحتاجه في مكان واحد" |
| **الشعار الفرعي (FR)** | "Trouvez un artisan ou louez un appartement facilement en Algérie" |
| **الهدف** | ربط المستخدمين بالحرفيين وبمُلّاك العقارات في الجزائر |
| **السوق الأولي** | الجزائر (58 ولاية) |
| **التوسع المستقبلي** | المغرب، تونس، ليبيا، موريتانيا |

---

## 2. المتطلبات الوظيفية

### 2.1 إدارة المستخدمين
- [x] تسجيل بالبريد الإلكتروني وكلمة المرور
- [x] أنواع الحسابات: مستخدم عادي / حرفي / مالك عقار / مدير
- [x] تحديث الملف الشخصي
- [x] رفع صورة الملف الشخصي
- [x] تغيير كلمة المرور / استعادتها
- [x] إدارة الجلسات وتجديد الـ Token

### 2.2 منصة الحرفيين
- [x] إنشاء ملف حرفي احترافي
- [x] اختيار التخصص من قائمة موحدة (25+ تخصص)
- [x] تحديد الولاية والمدينة
- [x] رقم الهاتف + رقم واتساب
- [x] معرض الأعمال (portfolio) بالصور
- [x] البيو والخبرة بالسنوات
- [x] التوفر (متاح / غير متاح)
- [x] التقييمات والمراجعات من العملاء
- [x] حالة التحقق (pending / verified / rejected)

### 2.3 منصة العقارات
- [x] إضافة إعلان عقاري (شقة، منزل، استوديو، فيلا، تجاري)
- [x] صور متعددة مع تحديد صورة الغلاف
- [x] السعر + الفترة (شهري/سنوي/يومي)
- [x] الموقع (الولاية + المدينة + العنوان + GPS)
- [x] المواصفات: غرف، حمامات، مساحة، طابق، عدد الطوابق
- [x] المميزات: مفروش، مواقف، مصعد، شرفة
- [x] التواصل مع المالك

### 2.4 البحث والاستكشاف
- [x] البحث النصي في الحرفيين والعقارات
- [x] فلاتر متقدمة لكل قسم
- [x] ترتيب حسب التقييم، السعر، التاريخ
- [x] البحث حسب الولاية والمدينة
- [x] الحرفيون المميزون والعقارات المميزة

### 2.5 التفاعل الاجتماعي
- [x] المفضلة (حرفيون + عقارات)
- [x] الدردشة الداخلية (Real-time via Socket.io)
- [x] التقييمات والمراجعات
- [x] الإشعارات الفورية (FCM)

### 2.6 لوحة الإدارة
- [x] إدارة المستخدمين (تفعيل/إيقاف/حظر)
- [x] التحقق من الحرفيين
- [x] إدارة الإعلانات
- [x] إدارة البلاغات
- [x] إحصائيات المنصة

---

## 3. المتطلبات غير الوظيفية

| المتطلب | المعيار |
|---|---|
| **الأداء** | استجابة API < 200ms (P95) |
| **الأمان** | JWT + Refresh Token rotation, bcrypt(12), Rate limiting |
| **التوسعية** | Stateless API + Redis cache + Horizontal scaling |
| **التوفرية** | 99.5% uptime |
| **الدعم اللغوي** | العربية (RTL أولاً)، الفرنسية، الإنجليزية |
| **رفع الملفات** | صور حتى 10MB، Cloudinary CDN |
| **الاتصال الفوري** | Socket.io للدردشة |
| **التخزين المؤقت** | Redis لـ specialties, featured, user profiles |
| **التوثيق** | Swagger/OpenAPI كامل |
| **بدون دفع إلكتروني** | التواصل فقط (دردشة/هاتف/واتساب) |

---

## 4. الهندسة المعمارية

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (Mobile)                  │
│    Riverpod │ GoRouter │ Dio │ Socket.io Client          │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS / WSS
┌────────────────────────▼────────────────────────────────┐
│                   NestJS API (v1)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │   Auth   │ │Craftsmen │ │ Listings │ │   Chat    │  │
│  │  Module  │ │  Module  │ │  Module  │ │  Gateway  │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐  │
│  │ Reviews  │ │Favorites │ │  Notifs  │ │   Admin   │  │
│  │  Module  │ │  Module  │ │  Module  │ │   Module  │  │
│  └──────────┘ └──────────┘ └──────────┘ └───────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                 │
│  │  Users   │ │  Upload  │ │Specialty │                 │
│  │  Module  │ │  Module  │ │  Module  │                 │
│  └──────────┘ └──────────┘ └──────────┘                 │
├─────────────────────────────────────────────────────────┤
│               Shared Services Layer                      │
│    PrismaService │ RedisService │ CloudinaryService      │
└──────┬──────────────────┬──────────────────┬────────────┘
       │                  │                  │
┌──────▼──────┐  ┌────────▼──────┐  ┌───────▼───────────┐
│ PostgreSQL  │  │     Redis     │  │  Cloudinary CDN   │
│  (Prisma)  │  │    (Cache)    │  │  (Media Storage)  │
└────────────┘  └───────────────┘  └───────────────────┘
```

### معمارية Flutter (Clean Architecture)
```
lib/
├── core/           # البنية التحتية
│   ├── config/     # إعدادات البيئة
│   ├── error/      # معالجة الأخطاء
│   ├── network/    # Dio + interceptors
│   ├── router/     # GoRouter
│   ├── storage/    # SecureStorage + SharedPrefs
│   ├── theme/      # ألوان + خطوط + ستايلات
│   └── utils/      # validators, formatters
├── features/       # ميزات المنصة
│   ├── auth/       # Data → Domain → Presentation
│   ├── craftsmen/  # Data → Domain → Presentation
│   ├── listings/   # Data → Domain → Presentation
│   ├── chat/       # Data → Domain → Presentation
│   ├── reviews/    # Data → Domain → Presentation
│   ├── favorites/  # Data → Domain → Presentation
│   ├── profile/    # Data → Domain → Presentation
│   ├── home/       # Presentation
│   ├── navigation/ # Presentation
│   └── notifications/ # Data → Domain → Presentation
└── shared/
    └── widgets/    # مكونات مشتركة
```

---

## 5. قاعدة البيانات — ERD

### الجداول الرئيسية وعلاقاتها:

```
users (1) ──────── (1) craftsmen
users (1) ──────── (N) property_listings
users (1) ──────── (N) messages (sent)
users (1) ──────── (N) messages (received)
users (N) ──────── (N) chat_rooms (members)
users (1) ──────── (N) favorites
users (1) ──────── (N) reviews (given)
users (1) ──────── (N) reviews (received)
users (1) ──────── (N) notifications
users (1) ──────── (N) reports (by)
users (1) ──────── (N) user_sessions
users (1) ──────── (N) email_verifications
users (1) ──────── (N) password_resets

craftsmen (1) ───── (1) specialties
craftsmen (1) ───── (N) portfolio_items
craftsmen (1) ───── (N) reviews

property_listings (1) ─── (N) listing_images
property_listings (1) ─── (N) favorites
property_listings (1) ─── (N) reviews
property_listings (1) ─── (N) chat_rooms

chat_rooms (1) ──── (N) messages
wilayas (1) ──────── (N) cities
```

---

## 6. تخصصات الحرفيين (25+)

| AR | FR | EN |
|---|---|---|
| سباك | Plombier | Plumber |
| كهربائي | Électricien | Electrician |
| نقاش | Peintre | Painter |
| نجار | Menuisier | Carpenter |
| بناء | Maçon | Mason |
| فراش بلاط | Carreleur | Tiler |
| جابص | Plâtrier | Plasterer |
| حداد | Soudeur | Welder |
| ميكانيكي | Mécanicien | Mechanic |
| تقني تكييف | Technicien climatisation | AC Tech |
| حداد أبواب | Serrurier | Locksmith |
| خدمة تنظيف | Service nettoyage | Cleaning |
| خدمة نقل | Service déménagement | Moving |
| بستاني | Jardinier | Gardener |
| حداد ديكور | Ferronnerie déco | Iron Décor |
| ألومنيوم | Alumineur | Aluminium |
| رخام | Marbreur | Marble |
| طاقة شمسية | Énergie solaire | Solar Energy |
| كاميرات مراقبة | CCTV | CCTV |
| شبكات إنترنت | Réseaux internet | Internet Networks |
| أنتينا | Antenniste | Antenna |
| هدم | Démolition | Demolition |
| حفر | Excavation | Excavation |
| عزل مائي | Étanchéité | Waterproofing |
| ديكور داخلي | Décorateur intérieur | Interior Decorator |

---

## 7. الولايات الجزائرية (58)

كل ولايات الجزائر الـ 58 مُضمَّنة في:
- قاعدة البيانات: جدول `wilayas` + enum `WilayaCode`
- ملف البذر: `prisma/seed.ts`

---

## 8. مسارات API الكاملة

### Auth
| Method | Route | Description |
|---|---|---|
| POST | /api/v1/auth/register | تسجيل جديد |
| POST | /api/v1/auth/login | تسجيل الدخول |
| POST | /api/v1/auth/refresh | تجديد التوكن |
| POST | /api/v1/auth/logout | تسجيل الخروج |
| POST | /api/v1/auth/forgot-password | طلب إعادة كلمة المرور |
| POST | /api/v1/auth/reset-password | إعادة تعيين كلمة المرور |
| GET | /api/v1/auth/me | المستخدم الحالي |

### Users
| Method | Route | Description |
|---|---|---|
| GET | /api/v1/users/me | ملفي الشخصي |
| PUT | /api/v1/users/me | تعديل الملف |
| PUT | /api/v1/users/me/avatar | رفع الصورة |
| DELETE | /api/v1/users/me | حذف الحساب |
| GET | /api/v1/users/:id | ملف مستخدم آخر |

### Craftsmen
| Method | Route | Description |
|---|---|---|
| GET | /api/v1/craftsmen | البحث والفلترة |
| GET | /api/v1/craftsmen/featured | المميزون |
| GET | /api/v1/craftsmen/:id | تفاصيل الحرفي |
| GET | /api/v1/craftsmen/user/profile | ملفي كحرفي |
| POST | /api/v1/craftsmen | إنشاء ملف حرفي |
| PUT | /api/v1/craftsmen/profile | تعديل الملف |
| POST | /api/v1/craftsmen/portfolio | إضافة عمل |
| DELETE | /api/v1/craftsmen/portfolio/:id | حذف عمل |

### Listings
| Method | Route | Description |
|---|---|---|
| GET | /api/v1/listings | البحث والفلترة |
| GET | /api/v1/listings/featured | المميزة |
| GET | /api/v1/listings/my | إعلاناتي |
| GET | /api/v1/listings/:id | تفاصيل إعلان |
| POST | /api/v1/listings | إنشاء إعلان |
| PUT | /api/v1/listings/:id | تعديل إعلان |
| DELETE | /api/v1/listings/:id | حذف إعلان |
| POST | /api/v1/listings/:id/images | إضافة صور |
| DELETE | /api/v1/listings/images/:id | حذف صورة |

### Chat
| Method | Route | Description |
|---|---|---|
| POST | /api/v1/chat/rooms | إنشاء/الحصول على غرفة |
| GET | /api/v1/chat/rooms | قائمة المحادثات |
| GET | /api/v1/chat/rooms/:id/messages | رسائل الغرفة |
| POST | /api/v1/chat/rooms/:id/read | تعليم كمقروء |
| DELETE | /api/v1/chat/messages/:id | حذف رسالة |
| GET | /api/v1/chat/unread-count | عدد غير المقروء |

### WebSocket Events (Socket.io - /chat)
| Event (Emit) | Event (Listen) | Description |
|---|---|---|
| join:room | joined | الانضمام لغرفة |
| send:message | message:new | إرسال رسالة |
| mark:read | messages:read | تعليم مقروء |
| typing:start | user:typing | بدء الكتابة |
| typing:stop | user:stop-typing | إنهاء الكتابة |
| — | user:online | مستخدم متصل |
| — | user:offline | مستخدم غير متصل |

### Reviews, Favorites, Notifications, Admin
موثقة كاملاً في Swagger على: `GET /api/docs`

---

## 9. مخطط هيكل مجلدات Backend

```
backend/
├── prisma/
│   ├── schema.prisma          # 18 models
│   └── seed.ts                # 58 ولاية + 25 تخصص + admin
├── src/
│   ├── main.ts                # Bootstrap + Swagger + Security
│   ├── app.module.ts          # Root module
│   ├── config/
│   │   ├── configuration.ts
│   │   ├── database.config.ts
│   │   └── jwt.config.ts
│   ├── common/
│   │   ├── dto/
│   │   │   ├── pagination.dto.ts
│   │   │   └── api-response.dto.ts
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts
│   │   ├── interceptors/
│   │   │   ├── transform.interceptor.ts
│   │   │   └── logging.interceptor.ts
│   │   └── pipes/
│   │       └── validation.pipe.ts
│   ├── shared/
│   │   ├── prisma/            # PrismaService
│   │   ├── redis/             # RedisService
│   │   └── cloudinary/        # CloudinaryService
│   └── modules/
│       ├── auth/              # JWT + strategies + guards
│       ├── users/             # User CRUD
│       ├── craftsmen/         # Craftsmen + portfolio
│       ├── listings/          # Real estate listings
│       ├── chat/              # REST + WebSocket gateway
│       ├── reviews/           # Ratings system
│       ├── favorites/         # Wishlist
│       ├── notifications/     # Push notifications
│       ├── specialties/       # Trade categories
│       ├── upload/            # Cloudinary upload
│       └── admin/             # Admin panel
├── .env.example
├── package.json
├── tsconfig.json
└── nest-cli.json
```

---

## 10. مخطط هيكل مجلدات Flutter

```
frontend/
├── pubspec.yaml
├── lib/
│   ├── main.dart              # Entry + Firebase init
│   ├── app.dart               # MaterialApp.router
│   ├── core/
│   │   ├── config/            # AppConfig (dev/prod)
│   │   ├── error/             # Failures, Exceptions
│   │   ├── network/           # Dio + AuthInterceptor
│   │   ├── router/            # GoRouter + RouteNames
│   │   ├── storage/           # SecureStorage + Prefs
│   │   ├── theme/             # Colors, TextStyles, Theme
│   │   └── utils/             # Validators, Formatters
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/          # datasources + repositories
│   │   │   ├── domain/        # entities + usecases
│   │   │   └── presentation/  # screens + providers
│   │   ├── craftsmen/         # نفس البنية
│   │   ├── listings/          # نفس البنية
│   │   ├── chat/              # نفس البنية + Socket.io
│   │   ├── reviews/           # نفس البنية
│   │   ├── favorites/         # نفس البنية
│   │   ├── home/              # Presentation only
│   │   ├── navigation/        # Bottom nav shell
│   │   ├── profile/           # Presentation + providers
│   │   └── notifications/     # نفس البنية
│   └── shared/
│       └── widgets/           # 10+ مكونات مشتركة
└── assets/
    ├── images/
    ├── icons/
    ├── fonts/                 # Cairo (AR) + Poppins (EN)
    └── animations/            # Lottie files
```

---

## ✅ حالة المرحلة الأولى

| المخرج | الحالة |
|---|---|
| تحليل المتطلبات | ✅ مكتمل |
| الهوية التجارية والشعار | ✅ مكتمل |
| Software Architecture | ✅ مكتمل |
| ERD كامل | ✅ مكتمل |
| Prisma Schema (18 model) | ✅ مكتمل |
| هيكل مجلدات NestJS | ✅ مكتمل |
| هيكل مجلدات Flutter | ✅ مكتمل |
| Backend Modules (11 module) | ✅ مكتمل |
| Flutter Screens (20+ screen) | 🔄 قيد الإنشاء |
| Database Seed (58 ولاية) | 🔄 قيد الإنشاء |
| API Documentation (Swagger) | ✅ مدمج في main.ts |
