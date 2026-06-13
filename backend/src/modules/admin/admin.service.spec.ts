// @prisma/client is mapped to __mocks__/@prisma/client.ts via jest.config.ts
// moduleNameMapper so enum types are available even without `prisma generate`.
import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { AdminService } from './admin.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { AccountStatus, CraftsmanStatus, ListingStatus, ReportStatus } from '@prisma/client';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    update: jest.fn(),
    groupBy: jest.fn(),
  },
  craftsman: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    update: jest.fn(),
    groupBy: jest.fn(),
  },
  propertyListing: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    update: jest.fn(),
  },
  report: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    update: jest.fn(),
  },
  message: {
    count: jest.fn(),
  },
  review: {
    count: jest.fn(),
    aggregate: jest.fn(),
  },
  $transaction: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const mockUser = {
  id: 'user_1',
  email: 'user@example.com',
  firstName: 'Regular',
  lastName: 'User',
  role: 'USER',
  status: AccountStatus.ACTIVE,
  phone: '+213555000111',
  createdAt: new Date(),
  isEmailVerified: true,
  avatarUrl: null,
  _count: { listings: 2, reviewsGiven: 5 },
};

const mockAdminUser = {
  ...mockUser,
  id: 'admin_1',
  email: 'admin@example.com',
  role: 'ADMIN',
};

const mockCraftsman = {
  id: 'craft_1',
  userId: 'user_2',
  status: CraftsmanStatus.PENDING,
  specialtyId: 'spec_1',
  createdAt: new Date(),
  user: {
    id: 'user_2',
    email: 'craftsman@example.com',
    firstName: 'Craftsman',
    lastName: 'User',
    phone: '+213555000222',
  },
  specialty: { id: 'spec_1', nameAr: 'سباكة', nameFr: 'Plomberie' },
};

const mockListing = {
  id: 'listing_1',
  ownerId: 'user_1',
  title: 'Test Listing',
  status: ListingStatus.DRAFT,
  wilaya: 16,
  createdAt: new Date(),
  owner: { id: 'user_1', email: 'user@example.com', firstName: 'Regular', lastName: 'User' },
  images: [],
  _count: { favorites: 3, reviews: 1 },
};

const mockReport = {
  id: 'report_1',
  status: ReportStatus.PENDING,
  reason: 'Spam content',
  adminNote: null,
  resolvedAt: null,
  createdAt: new Date(),
  reportedBy: { id: 'user_1', email: 'user@example.com', firstName: 'Regular', lastName: 'User' },
  reportedUser: { id: 'user_3', email: 'bad@example.com', firstName: 'Bad', lastName: 'Actor' },
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('AdminService', () => {
  let service: AdminService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<AdminService>(AdminService);
    jest.clearAllMocks();
  });

  // ─── getDashboardStats ─────────────────────────────────────────────────────

  describe('getDashboardStats', () => {
    it('should return dashboard overview statistics', async () => {
      // Mock all the Promise.all counts
      mockPrisma.user.count
        .mockResolvedValueOnce(100)  // totalUsers
        .mockResolvedValueOnce(5);   // todayUsers
      mockPrisma.craftsman.count
        .mockResolvedValueOnce(30)   // totalCraftsmen
        .mockResolvedValueOnce(8);   // pendingCraftsmen
      mockPrisma.propertyListing.count
        .mockResolvedValueOnce(200)  // totalListings
        .mockResolvedValueOnce(15)   // pendingListings (DRAFT)
        .mockResolvedValueOnce(120); // activeListings
      mockPrisma.report.count
        .mockResolvedValueOnce(50)   // totalReports
        .mockResolvedValueOnce(12);  // pendingReports
      mockPrisma.user.groupBy.mockResolvedValue([]);

      const result = await service.getDashboardStats();

      expect(result).toHaveProperty('overview');
      expect(result).toHaveProperty('pending');
      expect(result).toHaveProperty('today');
      expect(result).toHaveProperty('activeListings');
      expect(result).toHaveProperty('userGrowth');
      expect(result.overview.totalUsers).toBe(100);
      expect(result.overview.totalCraftsmen).toBe(30);
      expect(result.overview.totalListings).toBe(200);
    });

    it('should include pending counts in stats', async () => {
      mockPrisma.user.count.mockResolvedValueOnce(100).mockResolvedValueOnce(5);
      mockPrisma.craftsman.count.mockResolvedValueOnce(30).mockResolvedValueOnce(8);
      mockPrisma.propertyListing.count
        .mockResolvedValueOnce(200)
        .mockResolvedValueOnce(15)
        .mockResolvedValueOnce(120);
      mockPrisma.report.count.mockResolvedValueOnce(50).mockResolvedValueOnce(12);
      mockPrisma.user.groupBy.mockResolvedValue([]);

      const result = await service.getDashboardStats();

      expect(result.pending.pendingCraftsmen).toBe(8);
      expect(result.pending.pendingListings).toBe(15);
      expect(result.pending.pendingReports).toBe(12);
    });

    it('should include today new users count', async () => {
      mockPrisma.user.count.mockResolvedValueOnce(100).mockResolvedValueOnce(3);
      mockPrisma.craftsman.count.mockResolvedValueOnce(30).mockResolvedValueOnce(0);
      mockPrisma.propertyListing.count
        .mockResolvedValueOnce(200)
        .mockResolvedValueOnce(0)
        .mockResolvedValueOnce(180);
      mockPrisma.report.count.mockResolvedValueOnce(0).mockResolvedValueOnce(0);
      mockPrisma.user.groupBy.mockResolvedValue([]);

      const result = await service.getDashboardStats();

      expect(result.today.newUsers).toBe(3);
    });
  });

  // ─── getUsers ──────────────────────────────────────────────────────────────

  describe('getUsers', () => {
    it('should return paginated users', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockUser], 1]);

      const result = await service.getUsers(1, 20);

      expect(result.users).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(20);
    });

    it('should filter by status', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockUser], 1]);

      await service.getUsers(1, 20, 'ACTIVE');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by role', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockUser], 1]);

      await service.getUsers(1, 20, undefined, 'USER');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should search by email, firstName, or lastName', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockUser], 1]);

      await service.getUsers(1, 20, undefined, undefined, 'Ahmed');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should compute totalPages correctly', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockUser], 45]);

      const result = await service.getUsers(1, 20);

      expect(result.totalPages).toBe(3);
    });

    it('should calculate correct skip for page 3', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);

      await service.getUsers(3, 10);

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── updateUserStatus ──────────────────────────────────────────────────────

  describe('updateUserStatus', () => {
    it('should update user status to BANNED', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue({
        id: 'user_1',
        email: mockUser.email,
        status: AccountStatus.BANNED,
        role: 'USER',
      });

      const result = await service.updateUserStatus('user_1', AccountStatus.BANNED);

      expect(result.status).toBe(AccountStatus.BANNED);
      expect(mockPrisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user_1' },
        data: { status: AccountStatus.BANNED },
        select: { id: true, email: true, status: true, role: true },
      });
    });

    it('should update user status to SUSPENDED', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue({
        id: 'user_1',
        email: mockUser.email,
        status: AccountStatus.SUSPENDED,
        role: 'USER',
      });

      const result = await service.updateUserStatus('user_1', AccountStatus.SUSPENDED);

      expect(result.status).toBe(AccountStatus.SUSPENDED);
    });

    it('should update user status to ACTIVE', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ ...mockUser, status: AccountStatus.BANNED });
      mockPrisma.user.update.mockResolvedValue({
        id: 'user_1',
        email: mockUser.email,
        status: AccountStatus.ACTIVE,
        role: 'USER',
      });

      const result = await service.updateUserStatus('user_1', AccountStatus.ACTIVE);

      expect(result.status).toBe(AccountStatus.ACTIVE);
    });

    it('should throw NotFoundException when user does not exist', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.updateUserStatus('nonexistent', AccountStatus.BANNED),
      ).rejects.toThrow(NotFoundException);
      expect(mockPrisma.user.update).not.toHaveBeenCalled();
    });

    it('should throw ForbiddenException when trying to modify an ADMIN account', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockAdminUser);

      await expect(
        service.updateUserStatus('admin_1', AccountStatus.BANNED),
      ).rejects.toThrow(ForbiddenException);
      expect(mockPrisma.user.update).not.toHaveBeenCalled();
    });
  });

  // ─── getCraftsmen ──────────────────────────────────────────────────────────

  describe('getCraftsmen', () => {
    it('should return paginated craftsmen', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockCraftsman], 1]);

      const result = await service.getCraftsmen(1, 20);

      expect(result.craftsmen).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('should filter by status', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockCraftsman], 1]);

      await service.getCraftsmen(1, 20, 'PENDING');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── verifyCraftsman ───────────────────────────────────────────────────────

  describe('verifyCraftsman', () => {
    it('should verify a craftsman and set verifiedAt', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.craftsman.update.mockResolvedValue({
        ...mockCraftsman,
        status: CraftsmanStatus.VERIFIED,
        verifiedAt: new Date(),
      });

      const result = await service.verifyCraftsman('craft_1');

      expect(result.status).toBe(CraftsmanStatus.VERIFIED);
      expect(mockPrisma.craftsman.update).toHaveBeenCalledWith({
        where: { id: 'craft_1' },
        data: {
          status: CraftsmanStatus.VERIFIED,
          verifiedAt: expect.any(Date),
        },
        include: expect.any(Object),
      });
    });

    it('should throw NotFoundException when craftsman does not exist', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(service.verifyCraftsman('nonexistent')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.craftsman.update).not.toHaveBeenCalled();
    });
  });

  // ─── rejectCraftsman ───────────────────────────────────────────────────────

  describe('rejectCraftsman', () => {
    it('should reject a craftsman', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.craftsman.update.mockResolvedValue({
        ...mockCraftsman,
        status: CraftsmanStatus.REJECTED,
      });

      const result = await service.rejectCraftsman('craft_1', 'Insufficient documentation');

      expect(result.status).toBe(CraftsmanStatus.REJECTED);
    });

    it('should throw NotFoundException when craftsman does not exist', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(service.rejectCraftsman('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });

  // ─── getListings ───────────────────────────────────────────────────────────

  describe('getListings', () => {
    it('should return paginated listings', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      const result = await service.getListings(1, 20);

      expect(result.listings).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('should filter by status', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      await service.getListings(1, 20, 'ACTIVE');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should filter by wilaya', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListing], 1]);

      await service.getListings(1, 20, undefined, '16');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── updateListingStatus ───────────────────────────────────────────────────

  describe('updateListingStatus', () => {
    it('should update listing status', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockPrisma.propertyListing.update.mockResolvedValue({
        ...mockListing,
        status: ListingStatus.ACTIVE,
        publishedAt: new Date(),
        owner: { id: 'user_1', email: 'user@example.com' },
      });

      const result = await service.updateListingStatus('listing_1', ListingStatus.ACTIVE);

      expect(result.status).toBe(ListingStatus.ACTIVE);
    });

    it('should set publishedAt when status is ACTIVE', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
      mockPrisma.propertyListing.update.mockImplementation((args: any) => {
        expect(args.data.publishedAt).toBeInstanceOf(Date);
        return Promise.resolve({
          ...mockListing,
          status: ListingStatus.ACTIVE,
          publishedAt: args.data.publishedAt,
          owner: { id: 'user_1', email: 'user@example.com' },
        });
      });

      await service.updateListingStatus('listing_1', ListingStatus.ACTIVE);
    });

    it('should throw NotFoundException when listing does not exist', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(
        service.updateListingStatus('nonexistent', ListingStatus.ACTIVE),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── getReports ────────────────────────────────────────────────────────────

  describe('getReports', () => {
    it('should return paginated reports', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockReport], 1]);

      const result = await service.getReports(1, 20);

      expect(result.reports).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('should filter by status', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockReport], 1]);

      await service.getReports(1, 20, 'PENDING');

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── resolveReport ─────────────────────────────────────────────────────────

  describe('resolveReport', () => {
    it('should resolve a report with RESOLVED status', async () => {
      mockPrisma.report.findUnique.mockResolvedValue(mockReport);
      mockPrisma.report.update.mockResolvedValue({
        ...mockReport,
        status: ReportStatus.RESOLVED,
        adminNote: 'Action taken',
        resolvedAt: new Date(),
      });

      const result = await service.resolveReport('report_1', ReportStatus.RESOLVED, 'Action taken');

      expect(result.status).toBe(ReportStatus.RESOLVED);
      expect(mockPrisma.report.update).toHaveBeenCalledWith({
        where: { id: 'report_1' },
        data: {
          status: ReportStatus.RESOLVED,
          adminNote: 'Action taken',
          resolvedAt: expect.any(Date),
        },
      });
    });

    it('should resolve a report with DISMISSED status', async () => {
      mockPrisma.report.findUnique.mockResolvedValue(mockReport);
      mockPrisma.report.update.mockResolvedValue({
        ...mockReport,
        status: ReportStatus.DISMISSED,
        resolvedAt: new Date(),
      });

      const result = await service.resolveReport('report_1', ReportStatus.DISMISSED);

      expect(result.status).toBe(ReportStatus.DISMISSED);
    });

    it('should throw NotFoundException when report does not exist', async () => {
      mockPrisma.report.findUnique.mockResolvedValue(null);

      await expect(
        service.resolveReport('nonexistent', ReportStatus.RESOLVED),
      ).rejects.toThrow(NotFoundException);
      expect(mockPrisma.report.update).not.toHaveBeenCalled();
    });

    it('should set resolvedAt timestamp on resolution', async () => {
      mockPrisma.report.findUnique.mockResolvedValue(mockReport);
      mockPrisma.report.update.mockImplementation((args: any) => {
        expect(args.data.resolvedAt).toBeInstanceOf(Date);
        return Promise.resolve({ ...mockReport, ...args.data });
      });

      await service.resolveReport('report_1', ReportStatus.RESOLVED);
    });
  });

  // ─── getPlatformStats ──────────────────────────────────────────────────────

  describe('getPlatformStats', () => {
    it('should return comprehensive platform statistics', async () => {
      mockPrisma.user.count
        .mockResolvedValueOnce(500)   // totalUsers
        .mockResolvedValueOnce(450)   // activeUsers
        .mockResolvedValueOnce(30);   // newUsersLast30Days
      mockPrisma.craftsman.count
        .mockResolvedValueOnce(80)    // totalCraftsmen
        .mockResolvedValueOnce(60);   // verifiedCraftsmen
      mockPrisma.propertyListing.count
        .mockResolvedValueOnce(300)   // totalListings
        .mockResolvedValueOnce(200);  // activeListings
      mockPrisma.message.count.mockResolvedValue(1500);
      mockPrisma.review.count.mockResolvedValue(400);
      mockPrisma.review.aggregate.mockResolvedValue({ _avg: { rating: 4.3 } });
      mockPrisma.craftsman.groupBy.mockResolvedValue([]);
      mockPrisma.user.groupBy.mockResolvedValue([]);

      const result = await service.getPlatformStats();

      expect(result).toHaveProperty('users');
      expect(result).toHaveProperty('craftsmen');
      expect(result).toHaveProperty('listings');
      expect(result).toHaveProperty('engagement');
      expect(result).toHaveProperty('distributions');
      expect(result.users.total).toBe(500);
      expect(result.craftsmen.verified).toBe(60);
      expect(result.listings.active).toBe(200);
      expect(result.engagement.avgPlatformRating).toBe(4.3);
    });
  });
});
