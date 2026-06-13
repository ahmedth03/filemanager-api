/**
 * HarfiDar API — End-to-End Test Suite
 *
 * Covers the three most critical feature groups:
 *   1. Auth  (/api/v1/auth)
 *   2. Listings  (/api/v1/listings)
 *   3. Craftsmen  (/api/v1/craftsmen)
 *
 * All external services (Prisma, Redis, Email, Firebase) are replaced with
 * in-memory Jest mocks so no real database or network connection is required.
 */

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import * as request from 'supertest';
import { JwtService } from '@nestjs/jwt';

import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/shared/prisma/prisma.service';
import { RedisService } from '../src/shared/redis/redis.service';
import { EmailService } from '../src/shared/email/email.service';
import { FirebaseService } from '../src/shared/firebase/firebase.service';
import { AllExceptionsFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { LoggingInterceptor } from '../src/common/interceptors/logging.interceptor';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

const MOCK_USER_ID = 'user-uuid-001';
const MOCK_USER_EMAIL = 'test@harfidar.dz';
const MOCK_USER_FIRST_NAME = 'Ahmed';
const MOCK_LISTING_ID = 'listing-uuid-001';
const MOCK_CRAFTSMAN_ID = 'craftsman-uuid-001';

const mockUser = {
  id: MOCK_USER_ID,
  email: MOCK_USER_EMAIL,
  firstName: MOCK_USER_FIRST_NAME,
  lastName: 'Benali',
  passwordHash: '$2a$12$somehashedpassword', // bcrypt of 'ValidPass@1'
  role: 'USER',
  status: 'ACTIVE',
  avatarUrl: null,
  isEmailVerified: false,
  isPhoneVerified: false,
  phone: null,
  fcmToken: null,
  lastSeenAt: new Date(),
  craftsman: null,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockListing = {
  id: MOCK_LISTING_ID,
  ownerId: MOCK_USER_ID,
  title: 'شقة للإيجار في الجزائر العاصمة',
  description: 'شقة رائعة في المنطقة المركزية',
  type: 'APARTMENT',
  transactionType: 'RENT',
  price: 50000,
  pricePeriod: 'monthly',
  wilaya: 'ALGER',
  city: 'الجزائر',
  status: 'ACTIVE',
  isAvailable: true,
  viewCount: 0,
  avgRating: 0,
  totalReviews: 0,
  rooms: 3,
  bathrooms: 1,
  area: 80,
  owner: {
    id: MOCK_USER_ID,
    firstName: 'Ahmed',
    lastName: 'Benali',
    avatarUrl: null,
    phone: null,
  },
  images: [],
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockCraftsman = {
  id: MOCK_CRAFTSMAN_ID,
  userId: MOCK_USER_ID,
  specialtyId: 'specialty-001',
  bio: 'حرفي محترف بخبرة 10 سنوات',
  yearsExperience: 10,
  wilaya: 'ALGER',
  city: 'الجزائر',
  status: 'VERIFIED',
  isAvailable: true,
  avgRating: 4.5,
  totalReviews: 20,
  user: {
    id: MOCK_USER_ID,
    firstName: 'Ahmed',
    lastName: 'Benali',
    avatarUrl: null,
    phone: null,
  },
  specialty: {
    id: 'specialty-001',
    nameAr: 'سباكة',
    nameFr: 'Plomberie',
    icon: 'plumbing',
  },
  portfolio: [],
  reviews: [],
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockPaginatedListings = {
  data: [mockListing],
  meta: { total: 1, page: 1, limit: 20, totalPages: 1 },
};

const mockPaginatedCraftsmen = {
  data: [mockCraftsman],
  meta: { total: 1, page: 1, limit: 20, totalPages: 1 },
};

// ---------------------------------------------------------------------------
// Mock factories
// ---------------------------------------------------------------------------

function buildPrismaMock() {
  return {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
    emailVerification: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    passwordReset: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
    userSession: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      deleteMany: jest.fn(),
    },
    propertyListing: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    craftsman: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    $transaction: jest.fn(),
    $connect: jest.fn().mockResolvedValue(undefined),
    $disconnect: jest.fn().mockResolvedValue(undefined),
  };
}

function buildRedisMock() {
  return {
    get: jest.fn().mockResolvedValue(null),
    set: jest.fn().mockResolvedValue(undefined),
    del: jest.fn().mockResolvedValue(undefined),
    exists: jest.fn().mockResolvedValue(false),
    invalidatePattern: jest.fn().mockResolvedValue(undefined),
    keys: jest.fn().mockResolvedValue([]),
    onModuleInit: jest.fn().mockResolvedValue(undefined),
    onModuleDestroy: jest.fn().mockResolvedValue(undefined),
  };
}

function buildEmailMock() {
  return {
    sendVerificationEmail: jest.fn().mockResolvedValue(undefined),
    sendPasswordResetEmail: jest.fn().mockResolvedValue(undefined),
    sendWelcomeEmail: jest.fn().mockResolvedValue(undefined),
  };
}

function buildFirebaseMock() {
  return {
    sendPushNotification: jest.fn().mockResolvedValue(undefined),
    sendMulticast: jest.fn().mockResolvedValue(undefined),
    onModuleInit: jest.fn(),
  };
}

// ---------------------------------------------------------------------------
// Test setup helper
// ---------------------------------------------------------------------------

async function buildApp(): Promise<{
  app: INestApplication;
  prismaMock: ReturnType<typeof buildPrismaMock>;
  jwtService: JwtService;
}> {
  const prismaMock = buildPrismaMock();
  const redisMock = buildRedisMock();
  const emailMock = buildEmailMock();
  const firebaseMock = buildFirebaseMock();

  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  })
    .overrideProvider(PrismaService)
    .useValue(prismaMock)
    .overrideProvider(RedisService)
    .useValue(redisMock)
    .overrideProvider(EmailService)
    .useValue(emailMock)
    .overrideProvider(FirebaseService)
    .useValue(firebaseMock)
    .compile();

  const app = moduleFixture.createNestApplication();

  // Mirror main.ts setup exactly
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new LoggingInterceptor(), new TransformInterceptor());

  await app.init();

  const jwtService = moduleFixture.get<JwtService>(JwtService);

  return { app, prismaMock, jwtService };
}

/** Sign a JWT that passes the JwtStrategy validation. */
function signToken(jwtService: JwtService, overrides: Partial<typeof mockUser> = {}): string {
  const user = { ...mockUser, ...overrides };
  return jwtService.sign(
    { sub: user.id, email: user.email, role: user.role },
    { secret: 'fallback-secret', expiresIn: '15m' },
  );
}

// ===========================================================================
// 1. AUTH FLOW
// ===========================================================================

describe('Auth flow (/api/v1/auth)', () => {
  let app: INestApplication;
  let prisma: ReturnType<typeof buildPrismaMock>;
  let jwtService: JwtService;

  beforeAll(async () => {
    ({ app, prismaMock: prisma, jwtService } = await buildApp());
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── Register ───────────────────────────────────────────────────────────────

  describe('POST /api/v1/auth/register', () => {
    const validPayload = {
      email: 'newuser@harfidar.dz',
      firstName: 'Karim',
      lastName: 'Amari',
      password: 'SecurePass@1',
    };

    it('201 — creates a new user and returns tokens', async () => {
      prisma.user.findUnique.mockResolvedValue(null); // no existing user
      prisma.emailVerification.create.mockResolvedValue({ id: 'ev-001' });
      prisma.userSession.create.mockResolvedValue({ id: 'session-001' });
      prisma.user.create.mockResolvedValue({
        id: 'new-user-001',
        email: validPayload.email.toLowerCase(),
        firstName: validPayload.firstName,
        lastName: validPayload.lastName,
        role: 'USER',
        status: 'ACTIVE',
        createdAt: new Date(),
      });

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send(validPayload)
        .expect(201);

      expect(res.body).toHaveProperty('data');
      const data = res.body.data;
      expect(data).toHaveProperty('user');
      expect(data).toHaveProperty('accessToken');
      expect(data).toHaveProperty('refreshToken');
      expect(data.user.email).toBe(validPayload.email.toLowerCase());
    });

    it('409 — conflicts when email already exists', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);

      await request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send(validPayload)
        .expect(409);
    });

    it('400 — validation error on missing required fields', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/auth/register')
        .send({ email: 'bad' })
        .expect(400);
    });
  });

  // ── Login ─────────────────────────────────────────────────────────────────

  describe('POST /api/v1/auth/login', () => {
    const loginPayload = { email: MOCK_USER_EMAIL, password: 'ValidPass@1' };

    it('200 — returns user and tokens on correct credentials', async () => {
      // bcrypt.compare will be called with the stored hash — we mock the user
      // with a real bcrypt hash so the comparison works.
      const bcrypt = require('bcryptjs');
      const hash = await bcrypt.hash('ValidPass@1', 1);
      prisma.user.findUnique.mockResolvedValue({ ...mockUser, passwordHash: hash });
      prisma.user.update.mockResolvedValue(mockUser);
      prisma.userSession.create.mockResolvedValue({ id: 'session-001' });

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send(loginPayload)
        .expect(200);

      expect(res.body.data).toHaveProperty('accessToken');
      expect(res.body.data).toHaveProperty('refreshToken');
      expect(res.body.data.user.email).toBe(MOCK_USER_EMAIL);
    });

    it('401 — wrong password returns Unauthorized', async () => {
      const bcrypt = require('bcryptjs');
      const hash = await bcrypt.hash('OtherPass@9', 1);
      prisma.user.findUnique.mockResolvedValue({ ...mockUser, passwordHash: hash });

      await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email: MOCK_USER_EMAIL, password: 'WrongPass@1' })
        .expect(401);
    });

    it('401 — unknown email returns Unauthorized', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await request(app.getHttpServer())
        .post('/api/v1/auth/login')
        .send({ email: 'unknown@example.com', password: 'SomePass@1' })
        .expect(401);
    });
  });

  // ── Forgot Password ────────────────────────────────────────────────────────

  describe('POST /api/v1/auth/forgot-password', () => {
    it('200 — always returns success even if email does not exist', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/forgot-password')
        .send({ email: 'nonexistent@example.com' })
        .expect(200);

      expect(res.body.data).toHaveProperty('message');
    });

    it('200 — sends reset email when user exists', async () => {
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.passwordReset.updateMany.mockResolvedValue({ count: 0 });
      prisma.passwordReset.create.mockResolvedValue({ id: 'pr-001', token: 'some-token' });

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/forgot-password')
        .send({ email: MOCK_USER_EMAIL })
        .expect(200);

      expect(res.body.data).toHaveProperty('message');
    });
  });

  // ── Verify Email ──────────────────────────────────────────────────────────

  describe('POST /api/v1/auth/verify-email', () => {
    it('200 — verifies email with a valid token', async () => {
      const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000);
      prisma.emailVerification.findUnique.mockResolvedValue({
        id: 'ev-001',
        userId: MOCK_USER_ID,
        token: 'valid-token',
        usedAt: null,
        expiresAt: futureDate,
      });
      prisma.$transaction.mockResolvedValue([
        { email: MOCK_USER_EMAIL, firstName: MOCK_USER_FIRST_NAME },
        {},
      ]);

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/verify-email')
        .send({ token: 'valid-token' })
        .expect(200);

      expect(res.body.data).toHaveProperty('message');
    });

    it('400 — returns error for invalid token', async () => {
      prisma.emailVerification.findUnique.mockResolvedValue(null);

      await request(app.getHttpServer())
        .post('/api/v1/auth/verify-email')
        .send({ token: 'invalid-token' })
        .expect(400);
    });

    it('400 — returns error for expired token', async () => {
      const pastDate = new Date(Date.now() - 1000);
      prisma.emailVerification.findUnique.mockResolvedValue({
        id: 'ev-001',
        userId: MOCK_USER_ID,
        token: 'expired-token',
        usedAt: null,
        expiresAt: pastDate,
      });

      await request(app.getHttpServer())
        .post('/api/v1/auth/verify-email')
        .send({ token: 'expired-token' })
        .expect(400);
    });
  });

  // ── Logout ────────────────────────────────────────────────────────────────

  describe('POST /api/v1/auth/logout', () => {
    it('200 — logs out an authenticated user', async () => {
      const token = signToken(jwtService);
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.userSession.deleteMany.mockResolvedValue({ count: 1 });

      const res = await request(app.getHttpServer())
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(res.body.data).toHaveProperty('message');
    });

    it('401 — returns Unauthorized without token', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/auth/logout')
        .expect(401);
    });
  });

  // ── Get Me ────────────────────────────────────────────────────────────────

  describe('GET /api/v1/auth/me', () => {
    it('200 — returns the authenticated user profile', async () => {
      const token = signToken(jwtService);
      const profileUser = {
        ...mockUser,
        craftsman: null,
      };
      prisma.user.findUnique.mockResolvedValue(profileUser);

      const res = await request(app.getHttpServer())
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(res.body.data).toHaveProperty('id', MOCK_USER_ID);
      expect(res.body.data).toHaveProperty('email', MOCK_USER_EMAIL);
    });

    it('401 — returns Unauthorized without token', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/auth/me')
        .expect(401);
    });
  });
});

// ===========================================================================
// 2. LISTINGS FLOW
// ===========================================================================

describe('Listings flow (/api/v1/listings)', () => {
  let app: INestApplication;
  let prisma: ReturnType<typeof buildPrismaMock>;
  let jwtService: JwtService;

  beforeAll(async () => {
    ({ app, prismaMock: prisma, jwtService } = await buildApp());
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
    // Default Redis returns null (no cache)
  });

  // ── GET / ─────────────────────────────────────────────────────────────────

  describe('GET /api/v1/listings', () => {
    it('200 — returns paginated listings', async () => {
      prisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const res = await request(app.getHttpServer())
        .get('/api/v1/listings')
        .expect(200);

      expect(res.body.data).toHaveProperty('data');
      expect(res.body.data).toHaveProperty('meta');
      expect(Array.isArray(res.body.data.data)).toBe(true);
    });
  });

  // ── GET /:id ─────────────────────────────────────────────────────────────

  describe('GET /api/v1/listings/:id', () => {
    it('200 — returns a single listing', async () => {
      const listingWithExtra = {
        ...mockListing,
        reviews: [],
        _count: { favorites: 0 },
      };
      prisma.propertyListing.findUnique.mockResolvedValue(listingWithExtra);
      prisma.propertyListing.update.mockResolvedValue(listingWithExtra); // view count

      const res = await request(app.getHttpServer())
        .get(`/api/v1/listings/${MOCK_LISTING_ID}`)
        .expect(200);

      expect(res.body.data).toHaveProperty('id', MOCK_LISTING_ID);
      expect(res.body.data).toHaveProperty('title');
    });

    it('404 — unknown listing id returns Not Found', async () => {
      prisma.propertyListing.findUnique.mockResolvedValue(null);

      await request(app.getHttpServer())
        .get('/api/v1/listings/nonexistent-id')
        .expect(404);
    });
  });

  // ── POST / ────────────────────────────────────────────────────────────────

  describe('POST /api/v1/listings', () => {
    const createPayload = {
      title: 'شقة للإيجار',
      description: 'شقة جميلة في وسط المدينة',
      type: 'APARTMENT',
      transactionType: 'RENT',
      price: 40000,
      wilaya: 'ALGER',
      city: 'الجزائر',
      rooms: 2,
      area: 60,
    };

    it('201 — creates a listing for an authenticated user', async () => {
      const token = signToken(jwtService);
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.propertyListing.create.mockResolvedValue({
        ...mockListing,
        ...createPayload,
        status: 'DRAFT',
      });

      const res = await request(app.getHttpServer())
        .post('/api/v1/listings')
        .set('Authorization', `Bearer ${token}`)
        .send(createPayload)
        .expect(201);

      expect(res.body.data).toHaveProperty('id');
      expect(res.body.data).toHaveProperty('status', 'DRAFT');
    });

    it('401 — returns Unauthorized without token', async () => {
      await request(app.getHttpServer())
        .post('/api/v1/listings')
        .send(createPayload)
        .expect(401);
    });
  });

  // ── PUT /:id ─────────────────────────────────────────────────────────────

  describe('PUT /api/v1/listings/:id', () => {
    it('200 — updates a listing when requester is the owner', async () => {
      const token = signToken(jwtService);
      prisma.user.findUnique.mockResolvedValue(mockUser);
      // findUnique for ownership check
      prisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      prisma.propertyListing.update.mockResolvedValue({
        ...mockListing,
        title: 'عنوان محدّث',
      });

      const res = await request(app.getHttpServer())
        .put(`/api/v1/listings/${MOCK_LISTING_ID}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ title: 'عنوان محدّث' })
        .expect(200);

      expect(res.body.data).toHaveProperty('title', 'عنوان محدّث');
    });

    it('403 — returns Forbidden when requester is not the owner', async () => {
      const otherUserId = 'other-user-001';
      const token = signToken(jwtService, { id: otherUserId, email: 'other@harfidar.dz' });
      prisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        id: otherUserId,
        email: 'other@harfidar.dz',
      });
      // Listing belongs to MOCK_USER_ID, not otherUserId
      prisma.propertyListing.findUnique.mockResolvedValue(mockListing);

      await request(app.getHttpServer())
        .put(`/api/v1/listings/${MOCK_LISTING_ID}`)
        .set('Authorization', `Bearer ${token}`)
        .send({ title: 'محاولة تعديل' })
        .expect(403);
    });
  });

  // ── DELETE /:id ───────────────────────────────────────────────────────────

  describe('DELETE /api/v1/listings/:id', () => {
    it('200 — archives a listing when requester is the owner', async () => {
      const token = signToken(jwtService);
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      prisma.propertyListing.update.mockResolvedValue({
        ...mockListing,
        status: 'ARCHIVED',
        isAvailable: false,
      });

      const res = await request(app.getHttpServer())
        .delete(`/api/v1/listings/${MOCK_LISTING_ID}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(res.body.data).toHaveProperty('message');
    });

    it('403 — returns Forbidden when requester is not the owner', async () => {
      const otherUserId = 'other-user-002';
      const token = signToken(jwtService, { id: otherUserId, email: 'other2@harfidar.dz' });
      prisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        id: otherUserId,
        email: 'other2@harfidar.dz',
      });
      // Listing belongs to MOCK_USER_ID
      prisma.propertyListing.findUnique.mockResolvedValue(mockListing);

      await request(app.getHttpServer())
        .delete(`/api/v1/listings/${MOCK_LISTING_ID}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
    });

    it('404 — returns Not Found for unknown listing', async () => {
      const token = signToken(jwtService);
      prisma.user.findUnique.mockResolvedValue(mockUser);
      prisma.propertyListing.findUnique.mockResolvedValue(null);

      await request(app.getHttpServer())
        .delete('/api/v1/listings/nonexistent-id')
        .set('Authorization', `Bearer ${token}`)
        .expect(404);
    });
  });
});

// ===========================================================================
// 3. CRAFTSMEN FLOW
// ===========================================================================

describe('Craftsmen flow (/api/v1/craftsmen)', () => {
  let app: INestApplication;
  let prisma: ReturnType<typeof buildPrismaMock>;

  beforeAll(async () => {
    ({ app, prismaMock: prisma } = await buildApp());
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // ── GET / ─────────────────────────────────────────────────────────────────

  describe('GET /api/v1/craftsmen', () => {
    it('200 — returns paginated craftsmen', async () => {
      prisma.$transaction.mockResolvedValue([[mockCraftsman], 1]);

      const res = await request(app.getHttpServer())
        .get('/api/v1/craftsmen')
        .expect(200);

      expect(res.body.data).toHaveProperty('data');
      expect(res.body.data).toHaveProperty('meta');
      expect(Array.isArray(res.body.data.data)).toBe(true);
    });

    it('200 — supports query params for filtering', async () => {
      prisma.$transaction.mockResolvedValue([[], 0]);

      const res = await request(app.getHttpServer())
        .get('/api/v1/craftsmen?wilaya=ALGER&page=1&limit=10')
        .expect(200);

      expect(res.body.data.meta).toHaveProperty('total', 0);
    });
  });

  // ── GET /:id ─────────────────────────────────────────────────────────────

  describe('GET /api/v1/craftsmen/:id', () => {
    it('200 — returns a single craftsman profile', async () => {
      prisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);

      const res = await request(app.getHttpServer())
        .get(`/api/v1/craftsmen/${MOCK_CRAFTSMAN_ID}`)
        .expect(200);

      expect(res.body.data).toHaveProperty('id', MOCK_CRAFTSMAN_ID);
      expect(res.body.data).toHaveProperty('status', 'VERIFIED');
    });

    it('404 — returns Not Found for unknown craftsman id', async () => {
      prisma.craftsman.findUnique.mockResolvedValue(null);

      await request(app.getHttpServer())
        .get('/api/v1/craftsmen/nonexistent-craftsman-id')
        .expect(404);
    });
  });
});
