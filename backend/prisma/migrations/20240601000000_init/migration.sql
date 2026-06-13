-- CreateEnum
CREATE TYPE "Role" AS ENUM ('USER', 'CRAFTSMAN', 'OWNER', 'ADMIN');

-- CreateEnum
CREATE TYPE "AccountStatus" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'BANNED');

-- CreateEnum
CREATE TYPE "PropertyType" AS ENUM ('APARTMENT', 'HOUSE', 'STUDIO', 'VILLA', 'COMMERCIAL');

-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('RENT', 'SALE');

-- CreateEnum
CREATE TYPE "ListingStatus" AS ENUM ('DRAFT', 'ACTIVE', 'RENTED', 'SOLD', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "CraftsmanStatus" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "MessageStatus" AS ENUM ('SENT', 'DELIVERED', 'READ');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('MESSAGE', 'REVIEW', 'LISTING_APPROVED', 'LISTING_REJECTED', 'CRAFTSMAN_VERIFIED', 'REPORT_RESOLVED', 'SYSTEM');

-- CreateEnum
CREATE TYPE "ReportType" AS ENUM ('USER', 'LISTING', 'CRAFTSMAN', 'MESSAGE');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'REVIEWED', 'RESOLVED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "WilayaCode" AS ENUM (
  'W01', 'W02', 'W03', 'W04', 'W05', 'W06', 'W07', 'W08', 'W09', 'W10',
  'W11', 'W12', 'W13', 'W14', 'W15', 'W16', 'W17', 'W18', 'W19', 'W20',
  'W21', 'W22', 'W23', 'W24', 'W25', 'W26', 'W27', 'W28', 'W29', 'W30',
  'W31', 'W32', 'W33', 'W34', 'W35', 'W36', 'W37', 'W38', 'W39', 'W40',
  'W41', 'W42', 'W43', 'W44', 'W45', 'W46', 'W47', 'W48', 'W49', 'W50',
  'W51', 'W52', 'W53', 'W54', 'W55', 'W56', 'W57', 'W58'
);

-- CreateTable: users
CREATE TABLE "users" (
  "id"              TEXT PRIMARY KEY,
  "email"           TEXT NOT NULL UNIQUE,
  "phone"           TEXT UNIQUE,
  "passwordHash"    TEXT NOT NULL,
  "firstName"       TEXT NOT NULL,
  "lastName"        TEXT NOT NULL,
  "avatarUrl"       TEXT,
  "role"            "Role" NOT NULL DEFAULT 'USER',
  "status"          "AccountStatus" NOT NULL DEFAULT 'PENDING',
  "isEmailVerified" BOOLEAN NOT NULL DEFAULT false,
  "isPhoneVerified" BOOLEAN NOT NULL DEFAULT false,
  "fcmToken"        TEXT,
  "refreshToken"    TEXT,
  "lastSeenAt"      TIMESTAMP(3),
  "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"       TIMESTAMP(3) NOT NULL
);

-- CreateTable: user_sessions
CREATE TABLE "user_sessions" (
  "id"           TEXT PRIMARY KEY,
  "userId"       TEXT NOT NULL,
  "refreshToken" TEXT NOT NULL UNIQUE,
  "deviceInfo"   JSONB,
  "ipAddress"    TEXT,
  "expiresAt"    TIMESTAMP(3) NOT NULL,
  "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "user_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

-- CreateTable: email_verifications
CREATE TABLE "email_verifications" (
  "id"        TEXT PRIMARY KEY,
  "userId"    TEXT NOT NULL,
  "token"     TEXT NOT NULL UNIQUE,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "usedAt"    TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "email_verifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

-- CreateTable: password_resets
CREATE TABLE "password_resets" (
  "id"        TEXT PRIMARY KEY,
  "userId"    TEXT NOT NULL,
  "token"     TEXT NOT NULL UNIQUE,
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "usedAt"    TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "password_resets_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

-- CreateTable: specialties
CREATE TABLE "specialties" (
  "id"        TEXT PRIMARY KEY,
  "nameAr"    TEXT NOT NULL,
  "nameFr"    TEXT NOT NULL,
  "nameEn"    TEXT NOT NULL,
  "icon"      TEXT,
  "isActive"  BOOLEAN NOT NULL DEFAULT true,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable: craftsmen
CREATE TABLE "craftsmen" (
  "id"              TEXT PRIMARY KEY,
  "userId"          TEXT NOT NULL UNIQUE,
  "specialtyId"     TEXT NOT NULL,
  "bio"             TEXT,
  "yearsExperience" INTEGER NOT NULL DEFAULT 0,
  "wilaya"          "WilayaCode" NOT NULL,
  "city"            TEXT NOT NULL,
  "address"         TEXT,
  "whatsappNumber"  TEXT,
  "businessPhone"   TEXT,
  "businessName"    TEXT,
  "status"          "CraftsmanStatus" NOT NULL DEFAULT 'PENDING',
  "isAvailable"     BOOLEAN NOT NULL DEFAULT true,
  "avgRating"       DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalReviews"    INTEGER NOT NULL DEFAULT 0,
  "totalJobs"       INTEGER NOT NULL DEFAULT 0,
  "verifiedAt"      TIMESTAMP(3),
  "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"       TIMESTAMP(3) NOT NULL,
  CONSTRAINT "craftsmen_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "craftsmen_specialtyId_fkey" FOREIGN KEY ("specialtyId") REFERENCES "specialties"("id")
);

CREATE INDEX "craftsmen_wilaya_specialtyId_idx" ON "craftsmen"("wilaya", "specialtyId");
CREATE INDEX "craftsmen_status_isAvailable_idx" ON "craftsmen"("status", "isAvailable");

-- CreateTable: portfolio_items
CREATE TABLE "portfolio_items" (
  "id"          TEXT PRIMARY KEY,
  "craftsmanId" TEXT NOT NULL,
  "title"       TEXT NOT NULL,
  "description" TEXT,
  "imageUrl"    TEXT NOT NULL,
  "publicId"    TEXT NOT NULL,
  "order"       INTEGER NOT NULL DEFAULT 0,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "portfolio_items_craftsmanId_fkey" FOREIGN KEY ("craftsmanId") REFERENCES "craftsmen"("id") ON DELETE CASCADE
);

-- CreateTable: property_listings
CREATE TABLE "property_listings" (
  "id"              TEXT PRIMARY KEY,
  "ownerId"         TEXT NOT NULL,
  "title"           TEXT NOT NULL,
  "description"     TEXT NOT NULL,
  "type"            "PropertyType" NOT NULL,
  "transactionType" "TransactionType" NOT NULL DEFAULT 'RENT',
  "status"          "ListingStatus" NOT NULL DEFAULT 'DRAFT',
  "price"           DECIMAL(10,2) NOT NULL,
  "pricePeriod"     TEXT NOT NULL DEFAULT 'monthly',
  "wilaya"          "WilayaCode" NOT NULL,
  "city"            TEXT NOT NULL,
  "address"         TEXT,
  "latitude"        DOUBLE PRECISION,
  "longitude"       DOUBLE PRECISION,
  "rooms"           INTEGER NOT NULL,
  "bathrooms"       INTEGER NOT NULL DEFAULT 1,
  "area"            DOUBLE PRECISION,
  "floor"           INTEGER,
  "totalFloors"     INTEGER,
  "hasParking"      BOOLEAN NOT NULL DEFAULT false,
  "hasElevator"     BOOLEAN NOT NULL DEFAULT false,
  "hasBalcony"      BOOLEAN NOT NULL DEFAULT false,
  "isFurnished"     BOOLEAN NOT NULL DEFAULT false,
  "isAvailable"     BOOLEAN NOT NULL DEFAULT true,
  "viewCount"       INTEGER NOT NULL DEFAULT 0,
  "avgRating"       DOUBLE PRECISION NOT NULL DEFAULT 0,
  "totalReviews"    INTEGER NOT NULL DEFAULT 0,
  "publishedAt"     TIMESTAMP(3),
  "expiresAt"       TIMESTAMP(3),
  "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"       TIMESTAMP(3) NOT NULL,
  CONSTRAINT "property_listings_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE INDEX "property_listings_wilaya_type_status_idx" ON "property_listings"("wilaya", "type", "status");
CREATE INDEX "property_listings_status_isAvailable_idx" ON "property_listings"("status", "isAvailable");

-- CreateTable: listing_images
CREATE TABLE "listing_images" (
  "id"        TEXT PRIMARY KEY,
  "listingId" TEXT NOT NULL,
  "url"       TEXT NOT NULL,
  "publicId"  TEXT NOT NULL,
  "isCover"   BOOLEAN NOT NULL DEFAULT false,
  "order"     INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "listing_images_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "property_listings"("id") ON DELETE CASCADE
);

-- CreateTable: favorites
CREATE TABLE "favorites" (
  "id"          TEXT PRIMARY KEY,
  "userId"      TEXT NOT NULL,
  "listingId"   TEXT,
  "craftsmanId" TEXT,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "favorites_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "favorites_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "property_listings"("id") ON DELETE CASCADE,
  CONSTRAINT "favorites_userId_listingId_key" UNIQUE ("userId", "listingId"),
  CONSTRAINT "favorites_userId_craftsmanId_key" UNIQUE ("userId", "craftsmanId")
);

-- CreateTable: reviews
CREATE TABLE "reviews" (
  "id"          TEXT PRIMARY KEY,
  "reviewerId"  TEXT NOT NULL,
  "revieweeId"  TEXT,
  "craftsmanId" TEXT,
  "listingId"   TEXT,
  "rating"      INTEGER NOT NULL,
  "comment"     TEXT,
  "isVerified"  BOOLEAN NOT NULL DEFAULT false,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL,
  CONSTRAINT "reviews_reviewerId_fkey" FOREIGN KEY ("reviewerId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "reviews_revieweeId_fkey" FOREIGN KEY ("revieweeId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "reviews_craftsmanId_fkey" FOREIGN KEY ("craftsmanId") REFERENCES "craftsmen"("id") ON DELETE CASCADE,
  CONSTRAINT "reviews_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "property_listings"("id") ON DELETE CASCADE
);

CREATE INDEX "reviews_craftsmanId_rating_idx" ON "reviews"("craftsmanId", "rating");
CREATE INDEX "reviews_listingId_rating_idx" ON "reviews"("listingId", "rating");

-- CreateTable: chat_rooms
CREATE TABLE "chat_rooms" (
  "id"            TEXT PRIMARY KEY,
  "listingId"     TEXT,
  "isGroup"       BOOLEAN NOT NULL DEFAULT false,
  "lastMessage"   TEXT,
  "lastMessageAt" TIMESTAMP(3),
  "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"     TIMESTAMP(3) NOT NULL,
  CONSTRAINT "chat_rooms_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "property_listings"("id") ON DELETE SET NULL
);

-- CreateTable: _ChatRoomMembers (many-to-many join table for ChatRoom <-> User)
CREATE TABLE "_ChatRoomMembers" (
  "A" TEXT NOT NULL,
  "B" TEXT NOT NULL,
  CONSTRAINT "_ChatRoomMembers_A_fkey" FOREIGN KEY ("A") REFERENCES "chat_rooms"("id") ON DELETE CASCADE,
  CONSTRAINT "_ChatRoomMembers_B_fkey" FOREIGN KEY ("B") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "_ChatRoomMembers_AB_unique" ON "_ChatRoomMembers"("A", "B");
CREATE INDEX "_ChatRoomMembers_B_index" ON "_ChatRoomMembers"("B");

-- CreateTable: messages
CREATE TABLE "messages" (
  "id"         TEXT PRIMARY KEY,
  "roomId"     TEXT NOT NULL,
  "senderId"   TEXT NOT NULL,
  "receiverId" TEXT,
  "content"    TEXT NOT NULL,
  "mediaUrl"   TEXT,
  "status"     "MessageStatus" NOT NULL DEFAULT 'SENT',
  "readAt"     TIMESTAMP(3),
  "deletedAt"  TIMESTAMP(3),
  "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "messages_roomId_fkey" FOREIGN KEY ("roomId") REFERENCES "chat_rooms"("id") ON DELETE CASCADE,
  CONSTRAINT "messages_senderId_fkey" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "messages_receiverId_fkey" FOREIGN KEY ("receiverId") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE INDEX "messages_roomId_createdAt_idx" ON "messages"("roomId", "createdAt");

-- CreateTable: notifications
CREATE TABLE "notifications" (
  "id"        TEXT PRIMARY KEY,
  "userId"    TEXT NOT NULL,
  "type"      "NotificationType" NOT NULL,
  "title"     TEXT NOT NULL,
  "body"      TEXT NOT NULL,
  "data"      JSONB,
  "isRead"    BOOLEAN NOT NULL DEFAULT false,
  "readAt"    TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "notifications_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
);

CREATE INDEX "notifications_userId_isRead_idx" ON "notifications"("userId", "isRead");

-- CreateTable: reports
CREATE TABLE "reports" (
  "id"             TEXT PRIMARY KEY,
  "reportedById"   TEXT NOT NULL,
  "reportedUserId" TEXT,
  "targetId"       TEXT NOT NULL,
  "type"           "ReportType" NOT NULL,
  "reason"         TEXT NOT NULL,
  "description"    TEXT,
  "status"         "ReportStatus" NOT NULL DEFAULT 'PENDING',
  "adminNote"      TEXT,
  "resolvedAt"     TIMESTAMP(3),
  "createdAt"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "reports_reportedById_fkey" FOREIGN KEY ("reportedById") REFERENCES "users"("id") ON DELETE CASCADE,
  CONSTRAINT "reports_reportedUserId_fkey" FOREIGN KEY ("reportedUserId") REFERENCES "users"("id") ON DELETE SET NULL
);

-- CreateTable: wilayas
CREATE TABLE "wilayas" (
  "id"     INTEGER PRIMARY KEY,
  "code"   TEXT NOT NULL UNIQUE,
  "nameAr" TEXT NOT NULL,
  "nameFr" TEXT NOT NULL
);

-- CreateTable: cities
CREATE TABLE "cities" (
  "id"       SERIAL PRIMARY KEY,
  "nameAr"   TEXT NOT NULL,
  "nameFr"   TEXT NOT NULL,
  "wilayaId" INTEGER NOT NULL,
  CONSTRAINT "cities_wilayaId_fkey" FOREIGN KEY ("wilayaId") REFERENCES "wilayas"("id")
);

-- CreateTable: admin_logs
CREATE TABLE "admin_logs" (
  "id"         TEXT PRIMARY KEY,
  "adminId"    TEXT NOT NULL,
  "action"     TEXT NOT NULL,
  "targetType" TEXT NOT NULL,
  "targetId"   TEXT NOT NULL,
  "metadata"   JSONB,
  "createdAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable: app_config
CREATE TABLE "app_config" (
  "key"       TEXT PRIMARY KEY,
  "value"     TEXT NOT NULL,
  "updatedAt" TIMESTAMP(3) NOT NULL
);

-- CreateTable: _prisma_migrations (Prisma internal tracking table)
CREATE TABLE "_prisma_migrations" (
  "id"                  VARCHAR(36) PRIMARY KEY,
  "checksum"            VARCHAR(64) NOT NULL,
  "finished_at"         TIMESTAMPTZ,
  "migration_name"      VARCHAR(255) NOT NULL,
  "logs"                TEXT,
  "rolled_back_at"      TIMESTAMPTZ,
  "started_at"          TIMESTAMPTZ NOT NULL DEFAULT now(),
  "applied_steps_count" INTEGER NOT NULL DEFAULT 0
);
