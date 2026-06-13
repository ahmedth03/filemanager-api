# HarfiDar — OpenAPI / Swagger Documentation Review

**Base URL:** `https://api.harfidar.dz`  
**API Version:** v1  
**Swagger UI:** `https://api.staging.harfidar.dz/api/docs` (staging only; disabled in production)  
**Total endpoints:** 67 across 11 modules

---

## API Structure Overview

```
/api/v1/
├── auth/           9 endpoints  — Authentication & session management
├── users/          6 endpoints  — User profile management
├── craftsmen/      8 endpoints  — Craftsman profiles & portfolio
├── listings/      11 endpoints  — Property listings & images
├── favorites/      8 endpoints  — Favorite craftsmen & listings
├── reviews/        4 endpoints  — Reviews for craftsmen & listings
├── chat/           7 endpoints  — Chat rooms & messages
├── notifications/  6 endpoints  — User notifications
├── reports/        2 endpoints  — Content reporting
├── upload/         3 endpoints  — Direct Cloudinary upload
└── admin/         11 endpoints  — Admin dashboard & moderation
```

---

## Module-by-Module Endpoint Review

### Auth (`/api/v1/auth`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| POST | `/register` | Public | ✅ | Returns user + tokens; email is fire-and-forget |
| POST | `/login` | Public | ✅ | Returns user profile + access + refresh tokens |
| POST | `/refresh` | Refresh token | ✅ | Requires `Authorization: Bearer <refresh_token>` + body `{refreshToken}` |
| POST | `/logout` | JWT | ✅ | Body `{refreshToken}` optional; omit to logout all devices |
| POST | `/verify-email` | Public | ✅ | Body `{token}` — UUID from verification email |
| POST | `/forgot-password` | Public | ✅ | Always returns 200 (prevents email enumeration) |
| POST | `/reset-password` | Public | ✅ | Body `{token, password}` |
| POST | `/change-password` | JWT | ✅ | Body `{currentPassword, newPassword}` |
| GET | `/me` | JWT | ✅ | Returns full profile including craftsman sub-profile |

**Documentation gaps:**
- `/refresh` should document that the Bearer token IS the refresh token (non-obvious)
- Response schemas should include token expiry timestamps

---

### Users (`/api/v1/users`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| GET | `/` | JWT | ✅ | Admin-only; paginated user list |
| GET | `/:id` | JWT | ✅ | Public profile (no sensitive fields) |
| GET | `/:id/stats` | JWT | ✅ | Listing/review/favorite counts |
| PATCH | `/:id` | JWT | ✅ | Owner or Admin only; partial update |
| POST | `/:id/avatar` | JWT | ✅ | Multipart upload; max 10 MB |
| PATCH | `/:id/status` | Admin | ✅ | ACTIVE/SUSPENDED/BANNED |

---

### Craftsmen (`/api/v1/craftsmen`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| GET | `/` | Public | ✅ | Search by wilaya, specialty, rating, availability |
| GET | `/featured` | Public | ✅ | Top 8 by rating; cached 30 min |
| GET | `/user/me` | JWT | ✅ | Own craftsman profile |
| GET | `/:id` | Public | ✅ | Full profile + portfolio + reviews |
| POST | `/` | JWT | ✅ | Creates profile + upgrades user role to CRAFTSMAN |
| PUT | `/profile` | JWT | ✅ | Partial update of own profile |
| POST | `/portfolio` | JWT | ✅ | Multipart; requires Cloudinary |
| DELETE | `/portfolio/:itemId` | JWT | ✅ | Also deletes from Cloudinary |

**Route ordering note:** `GET /user/me` must be declared before `GET /:id` in the controller — this is correctly implemented.

---

### Listings (`/api/v1/listings`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| GET | `/` | Public | ✅ | Full-text + filter search; paginated |
| GET | `/featured` | Public | ✅ | Top by views/rating; cached 30 min |
| GET | `/user/mine` | JWT | ✅ | Owner's own listings; all statuses |
| GET | `/:id` | Public | ✅ | Full detail + reviews + images; increments viewCount (throttled 1/h) |
| POST | `/` | JWT | ✅ | Creates in DRAFT status |
| PUT | `/:id` | JWT | ✅ | Owner only; status change triggers publishedAt |
| DELETE | `/:id` | JWT | ✅ | Soft-delete: sets status=ARCHIVED, isAvailable=false |
| POST | `/:id/images` | JWT | ✅ | Up to 10 files; first image auto-set as cover |
| DELETE | `/:id/images/:imageId` | JWT | ✅ | Deletes from Cloudinary; promotes next image as cover |
| PATCH | `/:id/images/:imageId/cover` | JWT | ✅ | Sets new cover image |

**Search filter parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `query` | string | Full-text across title, description, city, address |
| `wilaya` | WilayaCode (W01–W58) | Filter by Algerian province |
| `type` | PropertyType | APARTMENT, HOUSE, STUDIO, VILLA, COMMERCIAL |
| `transactionType` | TransactionType | RENT, SALE |
| `city` | string | Partial match (case-insensitive) |
| `minPrice` / `maxPrice` | number | Price range in DZD |
| `minRooms` / `maxRooms` | integer | Room count range |
| `isFurnished` / `hasParking` / `hasElevator` | boolean | Amenity filters |
| `sortBy` | price \| createdAt \| views \| rating | Sort field |
| `sortOrder` | asc \| desc | Sort direction |
| `page` / `limit` | integer | Pagination |

---

### Reviews (`/api/v1/reviews`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| POST | `/` | JWT | ✅ | Body: `{craftsmanId}` OR `{listingId}` + `rating` + `comment` |
| GET | `/craftsman/:craftsmanId` | Public | ✅ | Paginated; includes reviewer avatar |
| GET | `/listing/:listingId` | Public | ✅ | Paginated; includes reviewer avatar |
| DELETE | `/:id` | JWT | ✅ | Author or Admin only; triggers avgRating recalculation |

---

### Favorites (`/api/v1/favorites`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| GET | `/listings` | JWT | ✅ | Paginated; includes cover image |
| GET | `/craftsmen` | JWT | ✅ | Paginated; includes avatar |
| GET | `/listings/:listingId/check` | JWT | ✅ | Returns `{isFavorited: bool}` |
| GET | `/craftsmen/:craftsmanId/check` | JWT | ✅ | Returns `{isFavorited: bool}` |
| POST | `/listings/:listingId` | JWT | ✅ | Idempotent; 409 if already favorited |
| DELETE | `/listings/:listingId` | JWT | ✅ | |
| POST | `/craftsmen/:craftsmanId` | JWT | ✅ | |
| DELETE | `/craftsmen/:craftsmanId` | JWT | ✅ | |

---

### Chat (`/api/v1/chat`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| POST | `/rooms` | JWT | ✅ | Idempotent: returns existing room if already exists |
| GET | `/rooms` | JWT | ✅ | Paginated; includes last message preview |
| GET | `/rooms/:roomId` | JWT | ✅ | Room metadata + participants |
| GET | `/rooms/:roomId/messages` | JWT | ✅ | Paginated; marks received messages as READ |
| POST | `/rooms/:roomId/messages` | JWT | ✅ | HTTP fallback; prefer WebSocket for real-time |
| POST | `/rooms/:roomId/read` | JWT | ✅ | Marks all unread messages in room as READ |
| DELETE | `/messages/:messageId` | JWT | ✅ | Soft-delete (sets deletedAt timestamp) |

**WebSocket events (Socket.IO):**

| Event (client → server) | Payload | Description |
|--------------------------|---------|-------------|
| `join:room` | `{ roomId }` | Join a chat room |
| `leave:room` | `{ roomId }` | Leave a chat room |
| `send:message` | `{ roomId, content, mediaUrl? }` | Send real-time message |

| Event (server → client) | Payload | Description |
|--------------------------|---------|-------------|
| `new:message` | Message object | Broadcast to room members |

WebSocket auth: pass JWT as query param `?token=<accessToken>` or in handshake auth headers.

---

### Notifications (`/api/v1/notifications`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| GET | `/` | JWT | ✅ | Paginated; sorted by createdAt desc |
| GET | `/unread-count` | JWT | ✅ | Returns `{count: number}` |
| PATCH | `/:id/read` | JWT | ✅ | Marks single notification read |
| PATCH | `/read-all` | JWT | ✅ | Marks all as read |
| DELETE | `/all` | JWT | ✅ | Clears all notifications |
| DELETE | `/:id` | JWT | ✅ | Deletes single notification |

**Notification types:** `MESSAGE`, `REVIEW`, `LISTING_APPROVED`, `LISTING_REJECTED`, `CRAFTSMAN_VERIFIED`, `REPORT_RESOLVED`, `SYSTEM`

---

### Reports (`/api/v1/reports`)

| Method | Path | Auth | Status | Notes |
|--------|------|------|--------|-------|
| POST | `/` | JWT | ✅ | Body: `{type, targetId, reason}` |
| GET | `/mine` | JWT | ✅ | Paginated list of reports submitted by current user |

**Report types:** `LISTING`, `CRAFTSMAN`, `USER`, `MESSAGE`

---

### Admin (`/api/v1/admin`)

All endpoints require `Role.ADMIN`.

| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard` | Aggregated stats + recent activity |
| GET | `/stats` | Platform totals (users, listings, craftsmen, revenue) |
| GET | `/users` | Paginated user list with filters |
| PATCH | `/users/:id/status` | Change user account status |
| GET | `/craftsmen` | Paginated craftsmen with status filter |
| PUT | `/craftsmen/:id/verify` | Verify craftsman → VERIFIED status |
| PUT | `/craftsmen/:id/reject` | Reject craftsman → REJECTED status |
| GET | `/listings` | Paginated listings with status filter |
| PATCH | `/listings/:id/status` | Change listing status (archive, activate) |
| GET | `/reports` | Paginated reports with status filter |
| PATCH | `/reports/:id/resolve` | Resolve a report + optional action |

---

## Response Format

All responses follow the `TransformInterceptor` envelope:

```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2026-06-13T12:00:00.000Z"
}
```

Error responses via `AllExceptionsFilter`:
```json
{
  "success": false,
  "statusCode": 400,
  "message": "Validation failed",
  "errors": ["field must be a string"],
  "path": "/api/v1/...",
  "timestamp": "2026-06-13T12:00:00.000Z"
}
```

## Pagination Format

All paginated list endpoints return:
```json
{
  "data": [...],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "totalPages": 5,
    "hasNextPage": true,
    "hasPrevPage": false
  }
}
```

---

## Documentation Gaps & Recommendations

| Priority | Gap | Recommendation |
|----------|-----|----------------|
| High | Refresh token endpoint usage non-obvious | Add explicit note: Bearer token must be the refresh token, not the access token |
| Medium | WebSocket authentication not in Swagger | Add separate WebSocket docs section |
| Medium | WilayaCode enum (W01–W58) not described | Add enum values table in Swagger description |
| Low | Rate limit headers not documented | Document `X-RateLimit-Limit` / `X-RateLimit-Remaining` response headers |
| Low | Image upload size limits not in Swagger | Add `@ApiBody({ schema: { maxLength: ... } })` annotations |
| Low | Notification trigger events not documented | Document which actions create which notification types |
