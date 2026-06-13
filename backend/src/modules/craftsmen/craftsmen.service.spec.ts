import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { CraftsmenService } from './craftsmen.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  craftsman: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    count: jest.fn(),
  },
  specialty: {
    findUnique: jest.fn(),
  },
  user: {
    update: jest.fn(),
  },
  portfolioItem: {
    create: jest.fn(),
    count: jest.fn(),
    findFirst: jest.fn(),
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
  invalidatePattern: jest.fn(),
};

const mockCloudinary = {
  uploadImage: jest.fn(),
  deleteImage: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const mockSpecialty = {
  id: 'spec_1',
  nameAr: 'سباكة',
  nameFr: 'Plomberie',
  icon: 'plumbing',
};

const mockCraftsman = {
  id: 'craft_1',
  userId: 'user_1',
  specialtyId: 'spec_1',
  bio: 'Experienced plumber',
  yearsExperience: 5,
  wilaya: 16,
  city: 'Alger',
  address: '123 Main St',
  whatsappNumber: '+213555000111',
  businessPhone: '+213555000112',
  businessName: 'Ahmed Plumbing',
  status: 'VERIFIED',
  isAvailable: true,
  avgRating: 4.5,
  totalReviews: 10,
  createdAt: new Date(),
  user: {
    id: 'user_1',
    firstName: 'Ahmed',
    lastName: 'Tabich',
    avatarUrl: null,
    phone: '+213555000111',
  },
  specialty: mockSpecialty,
  portfolio: [],
  reviews: [],
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('CraftsmenService', () => {
  let service: CraftsmenService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CraftsmenService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
        { provide: CloudinaryService, useValue: mockCloudinary },
      ],
    }).compile();

    service = module.get<CraftsmenService>(CraftsmenService);
    jest.clearAllMocks();
  });

  // ─── createProfile ─────────────────────────────────────────────────────────

  describe('createProfile', () => {
    const dto = {
      specialtyId: 'spec_1',
      bio: 'Experienced plumber',
      yearsExperience: 5,
      wilaya: 16,
      city: 'Alger',
      address: '123 Main St',
      whatsappNumber: '+213555000111',
      businessPhone: '+213555000112',
      businessName: 'Ahmed Plumbing',
    };

    it('should create a craftsman profile successfully', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);
      mockPrisma.specialty.findUnique.mockResolvedValue(mockSpecialty);
      mockPrisma.craftsman.create.mockResolvedValue(mockCraftsman);
      mockPrisma.user.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.createProfile('user_1', dto as any);

      expect(result).toEqual(mockCraftsman);
      expect(mockPrisma.craftsman.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            userId: 'user_1',
            specialtyId: dto.specialtyId,
            status: 'PENDING',
          }),
        }),
      );
    });

    it('should upgrade user role to CRAFTSMAN after profile creation', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);
      mockPrisma.specialty.findUnique.mockResolvedValue(mockSpecialty);
      mockPrisma.craftsman.create.mockResolvedValue(mockCraftsman);
      mockPrisma.user.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);

      await service.createProfile('user_1', dto as any);

      expect(mockPrisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user_1' },
        data: { role: 'CRAFTSMAN' },
      });
    });

    it('should invalidate user profile cache after creation', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);
      mockPrisma.specialty.findUnique.mockResolvedValue(mockSpecialty);
      mockPrisma.craftsman.create.mockResolvedValue(mockCraftsman);
      mockPrisma.user.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);

      await service.createProfile('user_1', dto as any);

      expect(mockRedis.del).toHaveBeenCalledWith('user:user_1:profile');
    });

    it('should throw ConflictException if craftsman profile already exists', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);

      await expect(service.createProfile('user_1', dto as any)).rejects.toThrow(ConflictException);
      expect(mockPrisma.craftsman.create).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException if specialty does not exist', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);
      mockPrisma.specialty.findUnique.mockResolvedValue(null);

      await expect(service.createProfile('user_1', dto as any)).rejects.toThrow(NotFoundException);
      expect(mockPrisma.craftsman.create).not.toHaveBeenCalled();
    });

    it('should default yearsExperience to 0 if not provided', async () => {
      const dtoWithoutExperience = { ...dto, yearsExperience: undefined };
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);
      mockPrisma.specialty.findUnique.mockResolvedValue(mockSpecialty);
      mockPrisma.craftsman.create.mockImplementation((args: any) => {
        expect(args.data.yearsExperience).toBe(0);
        return Promise.resolve(mockCraftsman);
      });
      mockPrisma.user.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);

      await service.createProfile('user_1', dtoWithoutExperience as any);
    });
  });

  // ─── search ────────────────────────────────────────────────────────────────

  describe('search', () => {
    const mockCraftsmenList = [mockCraftsman];

    it('should return paginated craftsmen with default params', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockCraftsmenList, 1]);

      const result = await service.search({} as any);

      expect(result.data).toHaveLength(1);
      expect(result.meta.total).toBe(1);
      expect(result.meta.page).toBe(1);
    });

    it('should filter by wilaya', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      await service.search({ wilaya: 16 } as any);

      const [findManyCall] = mockPrisma.$transaction.mock.calls[0][0];
      // The where clause of the findMany call should include wilaya
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by specialtyId', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockCraftsmenList, 1]);

      const result = await service.search({ specialtyId: 'spec_1' } as any);

      expect(result.data).toHaveLength(1);
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by minRating', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockCraftsmenList, 1]);

      const result = await service.search({ minRating: 4 } as any);

      expect(result.data).toHaveLength(1);
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should handle text query filter', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockCraftsmenList, 1]);

      const result = await service.search({ query: 'Ahmed' } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should return empty result when no craftsmen match', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      const result = await service.search({ wilaya: 99 } as any);

      expect(result.data).toHaveLength(0);
      expect(result.meta.total).toBe(0);
    });

    it('should calculate correct skip for page 2', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      await service.search({ page: 2, limit: 10 } as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should sort by rating when sortBy is rating', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockCraftsmenList, 1]);

      const result = await service.search({ sortBy: 'rating', sortOrder: 'desc' } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should sort by experience when sortBy is experience', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockCraftsmenList, 1]);

      const result = await service.search({ sortBy: 'experience', sortOrder: 'asc' } as any);

      expect(result.data).toHaveLength(1);
    });

    it('should filter only VERIFIED craftsmen', async () => {
      mockPrisma.$transaction.mockImplementation((queries: any[]) => {
        // The findMany call should have where.status = 'VERIFIED'
        return Promise.resolve([mockCraftsmenList, 1]);
      });

      await service.search({} as any);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── findById ──────────────────────────────────────────────────────────────

  describe('findById', () => {
    it('should return cached craftsman if available', async () => {
      // JSON.parse converts Dates to strings — compare stable string fields
      mockRedis.get.mockResolvedValue(JSON.stringify(mockCraftsman));

      const result = await service.findById('craft_1');

      expect(result.id).toBe(mockCraftsman.id);
      expect(result.userId).toBe(mockCraftsman.userId);
      expect(result.bio).toBe(mockCraftsman.bio);
      expect(mockPrisma.craftsman.findUnique).not.toHaveBeenCalled();
    });

    it('should fetch from DB and cache if not in Redis', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockRedis.set.mockResolvedValue(undefined);

      const result = await service.findById('craft_1');

      expect(result).toEqual(mockCraftsman);
      expect(mockPrisma.craftsman.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'craft_1' } }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'craftsman:craft_1',
        JSON.stringify(mockCraftsman),
        600,
      );
    });

    it('should throw NotFoundException when craftsman does not exist', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundException);
    });

    it('should include reviews, portfolio and specialty in DB fetch', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockRedis.set.mockResolvedValue(undefined);

      await service.findById('craft_1');

      expect(mockPrisma.craftsman.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({
          include: expect.objectContaining({
            specialty: true,
            portfolio: expect.any(Object),
            reviews: expect.any(Object),
          }),
        }),
      );
    });
  });

  // ─── findByUserId ──────────────────────────────────────────────────────────

  describe('findByUserId', () => {
    it('should return craftsman profile for given userId', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);

      const result = await service.findByUserId('user_1');

      expect(result).toEqual(mockCraftsman);
      expect(mockPrisma.craftsman.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: 'user_1' } }),
      );
    });

    it('should throw NotFoundException if no craftsman profile for userId', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(service.findByUserId('user_no_profile')).rejects.toThrow(NotFoundException);
    });
  });

  // ─── updateProfile ─────────────────────────────────────────────────────────

  describe('updateProfile', () => {
    it('should update craftsman profile and invalidate cache', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.craftsman.update.mockResolvedValue({
        ...mockCraftsman,
        bio: 'Updated bio',
      });
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.updateProfile('user_1', { bio: 'Updated bio' } as any);

      expect(result.bio).toBe('Updated bio');
      expect(mockRedis.del).toHaveBeenCalledWith(`craftsman:${mockCraftsman.id}`);
    });

    it('should throw NotFoundException if craftsman profile not found', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(
        service.updateProfile('nonexistent', { bio: 'bio' } as any),
      ).rejects.toThrow(NotFoundException);
    });

    it('should validate new specialtyId if it changes', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.specialty.findUnique.mockResolvedValue(null);

      await expect(
        service.updateProfile('user_1', { specialtyId: 'new_spec_id' } as any),
      ).rejects.toThrow(NotFoundException);
    });

    it('should not validate specialtyId if it is unchanged', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.craftsman.update.mockResolvedValue(mockCraftsman);
      mockRedis.del.mockResolvedValue(undefined);

      await service.updateProfile('user_1', { specialtyId: mockCraftsman.specialtyId } as any);

      // specialty.findUnique should NOT be called when specialtyId hasn't changed
      expect(mockPrisma.specialty.findUnique).not.toHaveBeenCalled();
    });

    it('should update with valid new specialtyId', async () => {
      const newSpecialty = { id: 'spec_2', nameAr: 'كهرباء', nameFr: 'Électricité', icon: 'electric' };
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.specialty.findUnique.mockResolvedValue(newSpecialty);
      mockPrisma.craftsman.update.mockResolvedValue({
        ...mockCraftsman,
        specialtyId: 'spec_2',
        specialty: newSpecialty,
      });
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.updateProfile('user_1', { specialtyId: 'spec_2' } as any);

      expect(result.specialtyId).toBe('spec_2');
    });
  });

  // ─── addPortfolioItem ──────────────────────────────────────────────────────

  describe('addPortfolioItem', () => {
    const mockFile = {
      originalname: 'portfolio.jpg',
      buffer: Buffer.from(''),
      mimetype: 'image/jpeg',
    } as Express.Multer.File;

    const mockPortfolioItem = {
      id: 'pi_1',
      craftsmanId: 'craft_1',
      title: 'Bathroom Renovation',
      description: 'Complete bathroom renovation',
      imageUrl: 'https://cdn.test/portfolio.jpg',
      publicId: 'portfolio/craft_1/abc123',
      order: 0,
    };

    it('should upload image and create portfolio item', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockCloudinary.uploadImage.mockResolvedValue({
        url: 'https://cdn.test/portfolio.jpg',
        publicId: 'portfolio/craft_1/abc123',
      });
      mockPrisma.portfolioItem.count.mockResolvedValue(0);
      mockPrisma.portfolioItem.create.mockResolvedValue(mockPortfolioItem);
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.addPortfolioItem(
        'user_1',
        mockFile,
        'Bathroom Renovation',
        'Complete bathroom renovation',
      );

      expect(result).toEqual(mockPortfolioItem);
      expect(mockCloudinary.uploadImage).toHaveBeenCalledWith(
        mockFile,
        `portfolio/${mockCraftsman.id}`,
      );
    });

    it('should set order based on existing item count', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockCloudinary.uploadImage.mockResolvedValue({
        url: 'https://cdn.test/portfolio.jpg',
        publicId: 'portfolio/craft_1/abc123',
      });
      mockPrisma.portfolioItem.count.mockResolvedValue(3);
      mockPrisma.portfolioItem.create.mockImplementation((args: any) => {
        expect(args.data.order).toBe(3);
        return Promise.resolve(mockPortfolioItem);
      });
      mockRedis.del.mockResolvedValue(undefined);

      await service.addPortfolioItem('user_1', mockFile, 'Title');
    });

    it('should throw NotFoundException if craftsman not found', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(
        service.addPortfolioItem('unknown_user', mockFile, 'Title'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── getFeatured ───────────────────────────────────────────────────────────

  describe('getFeatured', () => {
    it('should return cached result when available', async () => {
      const cachedList = [mockCraftsman];
      mockRedis.get.mockResolvedValue(JSON.stringify(cachedList));

      const result = await service.getFeatured(8);

      // JSON.parse converts Dates to strings — compare stable fields
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe(mockCraftsman.id);
      expect(result[0].bio).toBe(mockCraftsman.bio);
      expect(mockPrisma.craftsman.findMany).not.toHaveBeenCalled();
    });

    it('should fetch from DB and cache when Redis is empty', async () => {
      const featuredList = [mockCraftsman];
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.craftsman.findMany.mockResolvedValue(featuredList);
      mockRedis.set.mockResolvedValue(undefined);

      const result = await service.getFeatured(8);

      expect(result).toEqual(featuredList);
      expect(mockPrisma.craftsman.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: 'VERIFIED',
            isAvailable: true,
          }),
          take: 8,
        }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'craftsmen:featured:8',
        JSON.stringify(featuredList),
        1800,
      );
    });

    it('should use custom limit', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.craftsman.findMany.mockResolvedValue([]);
      mockRedis.set.mockResolvedValue(undefined);

      await service.getFeatured(4);

      expect(mockPrisma.craftsman.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ take: 4 }),
      );
      expect(mockRedis.set).toHaveBeenCalledWith(
        'craftsmen:featured:4',
        expect.any(String),
        1800,
      );
    });

    it('should only include craftsmen with avgRating >= 4', async () => {
      mockRedis.get.mockResolvedValue(null);
      mockPrisma.craftsman.findMany.mockResolvedValue([]);
      mockRedis.set.mockResolvedValue(undefined);

      await service.getFeatured();

      expect(mockPrisma.craftsman.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            avgRating: { gte: 4 },
          }),
        }),
      );
    });
  });

  // ─── updateAvgRating ───────────────────────────────────────────────────────

  describe('updateAvgRating', () => {
    it('should aggregate reviews and update craftsman rating', async () => {
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 4.2 },
        _count: { rating: 15 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.updateAvgRating('craft_1');

      expect(mockPrisma.craftsman.update).toHaveBeenCalledWith({
        where: { id: 'craft_1' },
        data: { avgRating: 4.2, totalReviews: 15 },
      });
    });

    it('should set avgRating to 0 when there are no reviews', async () => {
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: null },
        _count: { rating: 0 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.updateAvgRating('craft_1');

      expect(mockPrisma.craftsman.update).toHaveBeenCalledWith({
        where: { id: 'craft_1' },
        data: { avgRating: 0, totalReviews: 0 },
      });
    });

    it('should bust detail cache and featured cache', async () => {
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 4.0 },
        _count: { rating: 5 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});
      mockRedis.del.mockResolvedValue(undefined);
      mockRedis.invalidatePattern.mockResolvedValue(undefined);

      await service.updateAvgRating('craft_1');

      expect(mockRedis.del).toHaveBeenCalledWith('craftsman:craft_1');
      expect(mockRedis.invalidatePattern).toHaveBeenCalledWith('craftsmen:featured:*');
    });
  });
});
