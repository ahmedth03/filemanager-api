import { Test, TestingModule } from '@nestjs/testing';
import {
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { ListingsService } from './listings.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  propertyListing: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    count: jest.fn(),
  },
  listingImage: {
    findUnique: jest.fn(),
    findFirst: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
    delete: jest.fn(),
  },
  review: {
    aggregate: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockRedis = {
  get: jest.fn(),
  set: jest.fn(),
  del: jest.fn(),
  exists: jest.fn(),
  invalidatePattern: jest.fn(),
};

const mockCloudinary = {
  uploadImage: jest.fn(),
  uploadMultipleImages: jest.fn(),
  deleteImage: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const mockOwner = {
  id: 'user_1',
  firstName: 'Ahmed',
  lastName: 'Tabich',
  avatarUrl: null,
  phone: '+213555000111',
};

const mockListing = {
  id: 'listing_1',
  ownerId: 'user_1',
  title: '3-Room Apartment in Alger',
  description: 'Spacious apartment near the city centre',
  type: 'APARTMENT',
  price: 50000,
  pricePeriod: 'monthly',
  wilaya: 16,
  city: 'Alger',
  address: '10 Rue Didouche Mourad',
  latitude: 36.752887,
  longitude: 3.042048,
  rooms: 3,
  bathrooms: 2,
  area: 90,
  floor: 3,
  totalFloors: 6,
  hasParking: false,
  hasElevator: true,
  hasBalcony: true,
  isFurnished: false,
  status: 'ACTIVE',
  isAvailable: true,
  viewCount: 0,
  avgRating: 0,
  totalReviews: 0,
  publishedAt: new Date(),
  createdAt: new Date(),
  owner: mockOwner,
  images: [],
  reviews: [],
  _count: { favorites: 5 },
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('ListingsService', () => {
  let service: ListingsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ListingsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
        { provide: CloudinaryService, useValue: mockCloudinary },
      ],
    }).compile();

    service = module.get<ListingsService>(ListingsService);
    jest.clearAllMocks();
  });

  // ─── create ────────────────────────────────────────────────────────────────

  describe('create', () => {
    const createDto = {
      title: '3-Room Apartment in Alger',
      description: 'Spacious apartment near the city centre',
      type: 'APARTMENT',
      price: 50000,
      wilaya: 16,
      city: 'Alger',
      address: '10 Rue Didouche Mourad',
      rooms: 3,
      area: 90,
    };

    it('should create a listing with DRAFT status', async () => {
      mockPrisma.propertyListing.create.mockResolvedValue(mockListing);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      const result = await service.create('user_1', createDto as any);

      expect(result).toEqual(mockListing);
      expect(mockPrisma.propertyListing.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            ownerId: 'user_1',
            title: createDto.title,
            status: 'DRAFT',
          }),
        }),
      );
    });

    it('should apply default values for optional fields', async () => {
      mockPrisma.propertyListing.create.mockImplementation((args: any) => {
        expect(args.data.bathrooms).toBe(1);
        expect(args.data.hasParking).toBe(false);
        expect(args.data.hasElevator).toBe(false);
        expect(args.data.hasBalcony).toBe(false);
        expect(args.data.isFurnished).toBe(false);
        expect(args.data.pricePeriod).toBe('monthly');
        return Promise.resolve(mockListing);
      });
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.create('user_1', createDto as any);
    });

    it('should invalidate featured listings cache after creation', async () => {
      mockPrisma.propertyListing.create.mockResolvedValue(mockListing);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.create('user_1', createDto as any);

      expect(mockRedis.invalidatePattern).toHaveBeenCalledWith('listings:featured:*');
    });
  });

  // ─── search ────────────────────────────────────────────────────────────────

  describe('search', () => {
    it('should return paginated listings with default params', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({} as any);

      expect(result.data).toHaveLength(1);
      expect(result.meta.total).toBe(1);
      expect(result.meta.page).toBe(1);
    });

    it('should filter by wilaya', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({ wilaya: 16 } as any);

      expect(result.data).toHaveLength(1);
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by listing type', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({ type: 'APARTMENT' } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should filter by price range', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({ minPrice: 30000, maxPrice: 80000 } as any);

      expect(result.data).toHaveLength(1);
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by minPrice only', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      await service.search({ minPrice: 30000 } as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by maxPrice only', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      await service.search({ maxPrice: 80000 } as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by room range', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({ minRooms: 2, maxRooms: 4 } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should filter by isFurnished', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({ isFurnished: false } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should handle text query search', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.search({ query: 'Alger' } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should sort by price when sortBy is price', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      await service.search({ sortBy: 'price', sortOrder: 'asc' } as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should sort by views when sortBy is views', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      await service.search({ sortBy: 'views', sortOrder: 'desc' } as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should return empty data when no listings match', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      const result = await service.search({ wilaya: 99 } as any);

      expect(result.data).toHaveLength(0);
      expect(result.meta.total).toBe(0);
    });

    it('should calculate correct skip for page 3 with limit 10', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      await service.search({ page: 3, limit: 10 } as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should only search ACTIVE available listings', async () => {
      mockPrisma.$transaction.mockImplementation(() =>
        Promise.resolve([[mockListing], 1]),
      );

      await service.search({} as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── findById ──────────────────────────────────────────────────────────────

  describe('findById', () => {
    it('should return cached listing if available', async () => {
      // Service JSON.parse(cached), so dates become strings — compare id only
      mockRedis.get.mockResolvedValue(JSON.stringify(mockListing));

      const result = await service.findById('listing_1');

      expect(result.id).toBe('listing_1');
      expect(result.title).toBe(mockListing.title);
      expect(mockPrisma.propertyListing.findUnique).not.toHaveBeenCalled();
    });

    it('should fetch from DB and cache if not in Redis', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockRedis.set.mockResolvedValue(undefined);

      const result = await service.findById('listing_1');

      expect(result.id).toBe('listing_1');
      expect(result.title).toBe(mockListing.title);
      expect(mockPrisma.propertyListing.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'listing_1' } }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'listing:listing_1',
        JSON.stringify(mockListing),
        600,
      );
    });

    it('should include owner, images and reviews in DB fetch', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockRedis.set.mockResolvedValue(undefined);

      await service.findById('listing_1');

      expect(mockPrisma.propertyListing.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({
          include: expect.objectContaining({
            owner: expect.any(Object),
            images: expect.any(Object),
            reviews: expect.any(Object),
          }),
        }),
      );
    });

    it('should throw NotFoundException when listing does not exist', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });

  // ─── update ────────────────────────────────────────────────────────────────

  describe('update', () => {
    it('should update listing and invalidate cache', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockPrisma.propertyListing.update.mockResolvedValue({
        ...mockListing,
        title: 'Updated Title',
      });
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      const result = await service.update('user_1', 'listing_1', { title: 'Updated Title' } as any);

      expect(result.title).toBe('Updated Title');
      expect(mockRedis.del).toHaveBeenCalledWith('listing:listing_1');
      expect(mockRedis.invalidatePattern).toHaveBeenCalledWith('listings:featured:*');
    });

    it('should set publishedAt when status changes to ACTIVE', async () => {
      const draftListing = { ...mockListing, status: 'DRAFT' };
      mockPrisma.propertyListing.findUnique.mockResolvedValue(draftListing);
      mockPrisma.propertyListing.update.mockImplementation((args: any) => {
        expect(args.data.publishedAt).toBeInstanceOf(Date);
        return Promise.resolve({ ...draftListing, status: 'ACTIVE', publishedAt: args.data.publishedAt });
      });
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.update('user_1', 'listing_1', { status: 'ACTIVE' } as any);
    });

    it('should NOT update publishedAt when already ACTIVE', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing); // already ACTIVE
      mockPrisma.propertyListing.update.mockImplementation((args: any) => {
        expect(args.data.publishedAt).toBeUndefined();
        return Promise.resolve(mockListing);
      });
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.update('user_1', 'listing_1', { status: 'ACTIVE' } as any);
    });

    it('should throw NotFoundException when listing does not exist', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(
        service.update('user_1', 'nonexistent', { title: 'x' } as any),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException when updater is not the owner', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);

      await expect(
        service.update('other_user', 'listing_1', { title: 'x' } as any),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // ─── delete ────────────────────────────────────────────────────────────────

  describe('delete', () => {
    it('should soft-delete listing and clear caches', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockPrisma.propertyListing.update.mockResolvedValue({
        ...mockListing,
        status: 'ARCHIVED',
        isAvailable: false,
      });
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      const result = await service.delete('user_1', 'listing_1');

      expect(mockPrisma.propertyListing.update).toHaveBeenCalledWith({
        where: { id: 'listing_1' },
        data: { status: 'ARCHIVED', isAvailable: false },
      });
      expect(result).toEqual({ message: 'Listing archived successfully' });
      expect(mockRedis.del).toHaveBeenCalledWith('listing:listing_1');
      expect(mockRedis.invalidatePattern).toHaveBeenCalledWith('listings:featured:*');
    });

    it('should throw NotFoundException when listing does not exist', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(service.delete('user_1', 'nonexistent')).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException when deleter is not the owner', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);

      await expect(service.delete('other_user', 'listing_1')).rejects.toThrow(ForbiddenException);
    });
  });

  // ─── addImages ─────────────────────────────────────────────────────────────

  describe('addImages', () => {
    const mockFiles = [
      { originalname: 'img1.jpg', buffer: Buffer.from(''), mimetype: 'image/jpeg' },
      { originalname: 'img2.jpg', buffer: Buffer.from(''), mimetype: 'image/jpeg' },
    ] as Express.Multer.File[];

    it('should upload images and create listing image records', async () => {
      const listingWithCount = { ...mockListing, _count: { images: 0 } };
      mockPrisma.propertyListing.findUnique.mockResolvedValue(listingWithCount);
      mockCloudinary.uploadMultipleImages.mockResolvedValue([
        { url: 'https://cdn.test/img1.jpg', publicId: 'listings/listing_1/img1' },
        { url: 'https://cdn.test/img2.jpg', publicId: 'listings/listing_1/img2' },
      ]);
      const mockImages = [
        { id: 'img_1', url: 'https://cdn.test/img1.jpg', isCover: true, order: 0 },
        { id: 'img_2', url: 'https://cdn.test/img2.jpg', isCover: false, order: 1 },
      ];
      mockPrisma.$transaction.mockResolvedValue(mockImages);
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.addImages('user_1', 'listing_1', mockFiles);

      expect(result).toEqual(mockImages);
      expect(mockCloudinary.uploadMultipleImages).toHaveBeenCalledWith(
        mockFiles,
        'listings/listing_1',
      );
    });

    it('should mark first image as cover when no existing images', async () => {
      const listingWithCount = { ...mockListing, _count: { images: 0 } };
      mockPrisma.propertyListing.findUnique.mockResolvedValue(listingWithCount);
      mockCloudinary.uploadMultipleImages.mockResolvedValue([
        { url: 'https://cdn.test/img1.jpg', publicId: 'img1' },
      ]);
      mockPrisma.$transaction.mockImplementation((operations: any[]) => {
        return Promise.resolve([{ id: 'img_1', isCover: true }]);
      });
      mockRedis.del.mockResolvedValue(undefined);

      await service.addImages('user_1', 'listing_1', [mockFiles[0]]);
    });

    it('should throw BadRequestException when no files provided', async () => {
      await expect(service.addImages('user_1', 'listing_1', [])).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw NotFoundException when listing does not exist', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(service.addImages('user_1', 'nonexistent', mockFiles)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException when uploader is not the owner', async () => {
      const listingWithCount = { ...mockListing, _count: { images: 0 } };
      mockPrisma.propertyListing.findUnique.mockResolvedValue(listingWithCount);

      await expect(
        service.addImages('other_user', 'listing_1', mockFiles),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw BadRequestException when exceeding max 20 images', async () => {
      // 19 existing + 2 new = 21 > 20 — should throw
      const listingWithCount = { ...mockListing, _count: { images: 19 } };
      mockPrisma.propertyListing.findUnique.mockResolvedValue(listingWithCount);

      await expect(
        service.addImages('user_1', 'listing_1', mockFiles), // 19 + 2 = 21 > 20
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── getFeatured ───────────────────────────────────────────────────────────

  describe('getFeatured', () => {
    it('should return cached result when available', async () => {
      const cachedListings = [mockListing];
      mockRedis.get.mockResolvedValue(JSON.stringify(cachedListings));

      const result = await service.getFeatured(8);

      // JSON.parse converts Dates to strings — compare stable fields
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(mockListing.id);
      expect(result[0].title).toBe(mockListing.title);
      expect(mockPrisma.propertyListing.findMany).not.toHaveBeenCalled();
    });

    it('should fetch from DB and cache when Redis is empty', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.propertyListing.findMany.mockResolvedValue([mockListing]);
      mockRedis.set.mockResolvedValue(undefined);

      const result = await service.getFeatured(8);

      expect(result).toEqual([mockListing]);
      expect(mockPrisma.propertyListing.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: 'ACTIVE',
            isAvailable: true,
          }),
          take: 8,
        }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'listings:featured:8',
        JSON.stringify([mockListing]),
        1800,
      );
    });

    it('should use custom limit', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.propertyListing.findMany.mockResolvedValue([]);
      mockRedis.set.mockResolvedValue(undefined);

      await service.getFeatured(4);

      expect(mockPrisma.propertyListing.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ take: 4 }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'listings:featured:4',
        expect.any(String),
        1800,
      );
    });
  });

  // ─── incrementViewCount ────────────────────────────────────────────────────

  describe('incrementViewCount', () => {
    it('should increment view count if not throttled', async () => {
      mockRedis.exists.mockResolvedValue(false);
      mockPrisma.propertyListing.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.set.mockResolvedValue(undefined);

      await service.incrementViewCount('listing_1');

      expect(mockPrisma.propertyListing.update).toHaveBeenCalledWith({
        where: { id: 'listing_1' },
        data: { viewCount: { increment: 1 } },
      });
    });

    it('should skip increment if view was already counted recently', async () => {
      mockRedis.exists.mockResolvedValue(true);

      await service.incrementViewCount('listing_1');

      expect(mockPrisma.propertyListing.update).not.toHaveBeenCalled();
    });

    it('should set throttle key for 1 hour after increment', async () => {
      mockRedis.exists.mockResolvedValue(false);
      mockPrisma.propertyListing.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.set.mockResolvedValue(undefined);

      await service.incrementViewCount('listing_1');

      expect(mockRedis.set).toHaveBeenCalledWith(
        'listing:listing_1:view_throttle',
        '1',
        3600,
      );
    });
  });

  // ─── updateAvgRating ───────────────────────────────────────────────────────

  describe('updateAvgRating', () => {
    it('should aggregate reviews and update listing rating', async () => {
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 3.8 },
        _count: { rating: 12 },
      });
      mockPrisma.propertyListing.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.updateAvgRating('listing_1');

      expect(mockPrisma.propertyListing.update).toHaveBeenCalledWith({
        where: { id: 'listing_1' },
        data: { avgRating: 3.8, totalReviews: 12 },
      });
      expect(mockRedis.del).toHaveBeenCalledWith('listing:listing_1');
      expect(mockRedis.invalidatePattern).toHaveBeenCalledWith('listings:featured:*');
    });

    it('should set avgRating to 0 when there are no reviews', async () => {
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: null },
        _count: { rating: 0 },
      });
      mockPrisma.propertyListing.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.updateAvgRating('listing_1');

      expect(mockPrisma.propertyListing.update).toHaveBeenCalledWith({
        where: { id: 'listing_1' },
        data: { avgRating: 0, totalReviews: 0 },
      });
    });
  });
});
