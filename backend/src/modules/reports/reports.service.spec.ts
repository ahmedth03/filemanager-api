import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ReportType } from '@prisma/client';
import { ReportsService } from './reports.service';
import { PrismaService } from '../../shared/prisma/prisma.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  propertyListing: { findUnique: jest.fn() },
  craftsman: { findUnique: jest.fn() },
  user: { findUnique: jest.fn() },
  message: { findUnique: jest.fn() },
  report: {
    findFirst: jest.fn(),
    create: jest.fn(),
    findMany: jest.fn(),
  },
};

const mockReport = {
  id: 'report_1',
  reportedById: 'user_1',
  targetId: 'listing_1',
  type: ReportType.LISTING,
  reason: 'محتوى مضلل',
  status: 'PENDING',
  createdAt: new Date(),
  reportedBy: { id: 'user_1', firstName: 'Test', lastName: 'User' },
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('ReportsService', () => {
  let service: ReportsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ReportsService>(ReportsService);
    jest.clearAllMocks();
  });

  // ─── create ────────────────────────────────────────────────────────────────

  describe('create', () => {
    const createDto = {
      targetId: 'listing_1',
      type: ReportType.LISTING,
      reason: 'محتوى مضلل',
    };

    it('should create a listing report successfully', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue({ id: 'listing_1' });
      mockPrisma.report.findFirst.mockResolvedValue(null);
      mockPrisma.report.create.mockResolvedValue(mockReport);

      const result = await service.create('user_1', createDto as any);

      expect(result).toEqual(mockReport);
      expect(mockPrisma.report.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            reportedById: 'user_1',
            targetId: 'listing_1',
            type: ReportType.LISTING,
            reason: 'محتوى مضلل',
          }),
        }),
      );
    });

    it('should create a craftsman report', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue({ id: 'craft_1' });
      mockPrisma.report.findFirst.mockResolvedValue(null);
      mockPrisma.report.create.mockResolvedValue({ ...mockReport, type: ReportType.CRAFTSMAN });

      await service.create('user_1', {
        targetId: 'craft_1',
        type: ReportType.CRAFTSMAN,
        reason: 'احتيال',
      } as any);

      expect(mockPrisma.craftsman.findUnique).toHaveBeenCalledWith({ where: { id: 'craft_1' } });
    });

    it('should create a user report', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'user_2' });
      mockPrisma.report.findFirst.mockResolvedValue(null);
      mockPrisma.report.create.mockResolvedValue({ ...mockReport, type: ReportType.USER });

      await service.create('user_1', {
        targetId: 'user_2',
        type: ReportType.USER,
        reason: 'سلوك مسيء',
        reportedUserId: 'user_2',
      } as any);

      expect(mockPrisma.user.findUnique).toHaveBeenCalledWith({ where: { id: 'user_2' } });
    });

    it('should throw BadRequestException when reporting yourself', async () => {
      await expect(
        service.create('user_1', {
          targetId: 'user_1',
          type: ReportType.USER,
          reason: 'test',
          reportedUserId: 'user_1',
        } as any),
      ).rejects.toThrow(BadRequestException);

      expect(mockPrisma.report.create).not.toHaveBeenCalled();
    });

    it('should throw BadRequestException when already reported', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue({ id: 'listing_1' });
      mockPrisma.report.findFirst.mockResolvedValue(mockReport);

      await expect(service.create('user_1', createDto as any)).rejects.toThrow(BadRequestException);
      expect(mockPrisma.report.create).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when listing target does not exist', async () => {
      mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

      await expect(service.create('user_1', createDto as any)).rejects.toThrow(NotFoundException);
    });

    it('should throw NotFoundException when craftsman target does not exist', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(null);

      await expect(
        service.create('user_1', {
          targetId: 'nonexistent',
          type: ReportType.CRAFTSMAN,
          reason: 'test',
        } as any),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── getMyReports ──────────────────────────────────────────────────────────

  describe('getMyReports', () => {
    it('should return all reports submitted by the user', async () => {
      const reports = [mockReport, { ...mockReport, id: 'report_2' }];
      mockPrisma.report.findMany.mockResolvedValue(reports);

      const result = await service.getMyReports('user_1');

      expect(result).toEqual(reports);
      expect(mockPrisma.report.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { reportedById: 'user_1' } }),
      );
    });

    it('should return empty array when user has no reports', async () => {
      mockPrisma.report.findMany.mockResolvedValue([]);

      const result = await service.getMyReports('user_1');

      expect(result).toHaveLength(0);
    });
  });
});
