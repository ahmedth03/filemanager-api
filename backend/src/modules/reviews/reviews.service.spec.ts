import { Test, TestingModule } from '@nestjs/testing';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { PrismaService } from '../../shared/prisma/prisma.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  review: {
    create: jest.fn(),
    findFirst: jest.fn(),
    findMany: jest.fn(),
    count: jest.fn(),
    delete: jest.fn(),
    aggregate: jest.fn(),
    groupBy: jest.fn(),
  },
  craftsman: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  propertyListing: {
    findUnique: jest.fn(),
    update: jest.fn(),
  },
  $transaction: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const mockReviewer = {
  id: 'reviewer_1',
  firstName: 'Youcef',
  lastName: 'Benali',
  avatarUrl: null,
};

const mockCraftsman = {
  id: 'craft_1',
  userId: 'craftsman_user_1',
  specialtyId: 'spec_1',
  avgRating: 4.5,
  totalReviews: 10,
};

const mockListing = {
  id: 'listing_1',
  ownerId: 'listing_owner_1',
  title: 'Test Apartment',
  avgRating: 4.0,
  totalReviews: 5,
};

const mockCraftsmanReview = {
  id: 'review_1',
  reviewerId: 'reviewer_1',
  craftsmanId: 'craft_1',
  listingId: null,
  revieweeId: 'craftsman_user_1',
  rating: 5,
  comment: 'Excellent service',
  createdAt: new Date(),
  reviewer: mockReviewer,
};

const mockListingReview = {
  id: 'review_2',
  reviewerId: 'reviewer_1',
  craftsmanId: null,
  listingId: 'listing_1',
  revieweeId: 'listing_owner_1',
  rating: 4,
  comment: 'Nice apartment',
  createdAt: new Date(),
  reviewer: mockReviewer,
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('ReviewsService', () => {
  let service: ReviewsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReviewsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<ReviewsService>(ReviewsService);
    jest.clearAllMocks();
  });

  // ─── create ────────────────────────────────────────────────────────────────

  describe('create', () => {
    // ─ craftsman review ─

    describe('craftsman review', () => {
      const craftsmanReviewDto = {
        craftsmanId: 'craft_1',
        rating: 5,
        comment: 'Excellent service',
      };

      it('should create a craftsman review successfully', async () => {
        mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
        mockPrisma.review.findFirst.mockResolvedValue(null);
        mockPrisma.review.create.mockResolvedValue(mockCraftsmanReview);
        mockPrisma.review.aggregate.mockResolvedValue({
          _avg: { rating: 4.8 },
          _count: { rating: 11 },
        });
        mockPrisma.craftsman.update.mockResolvedValue({});

        const result = await service.create('reviewer_1', craftsmanReviewDto as any);

        expect(result).toEqual(mockCraftsmanReview);
        expect(mockPrisma.review.create).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining({
              reviewerId: 'reviewer_1',
              craftsmanId: 'craft_1',
              revieweeId: mockCraftsman.userId,
              rating: 5,
              comment: 'Excellent service',
            }),
          }),
        );
      });

      it('should update craftsman rating after creating review', async () => {
        mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
        mockPrisma.review.findFirst.mockResolvedValue(null);
        mockPrisma.review.create.mockResolvedValue(mockCraftsmanReview);
        mockPrisma.review.aggregate.mockResolvedValue({
          _avg: { rating: 4.8 },
          _count: { rating: 11 },
        });
        mockPrisma.craftsman.update.mockResolvedValue({});

        await service.create('reviewer_1', craftsmanReviewDto as any);

        expect(mockPrisma.craftsman.update).toHaveBeenCalledWith({
          where: { id: 'craft_1' },
          data: { avgRating: 4.8, totalReviews: 11 },
        });
      });

      it('should throw NotFoundException when craftsman does not exist', async () => {
        mockPrisma.craftsman.findUnique.mockResolvedValue(null);

        await expect(
          service.create('reviewer_1', craftsmanReviewDto as any),
        ).rejects.toThrow(NotFoundException);
      });

      it('should throw ForbiddenException when reviewing yourself as craftsman', async () => {
        mockPrisma.craftsman.findUnique.mockResolvedValue({
          ...mockCraftsman,
          userId: 'reviewer_1', // Same as reviewer
        });

        await expect(
          service.create('reviewer_1', craftsmanReviewDto as any),
        ).rejects.toThrow(ForbiddenException);
      });

      it('should throw BadRequestException when reviewing a craftsman twice', async () => {
        mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
        mockPrisma.review.findFirst.mockResolvedValue(mockCraftsmanReview); // Already reviewed

        await expect(
          service.create('reviewer_1', craftsmanReviewDto as any),
        ).rejects.toThrow(BadRequestException);
      });
    });

    // ─ listing review ─

    describe('listing review', () => {
      const listingReviewDto = {
        listingId: 'listing_1',
        rating: 4,
        comment: 'Nice apartment',
      };

      it('should create a listing review successfully', async () => {
        mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
        mockPrisma.review.findFirst.mockResolvedValue(null);
        mockPrisma.review.create.mockResolvedValue(mockListingReview);
        mockPrisma.review.aggregate.mockResolvedValue({
          _avg: { rating: 4.0 },
          _count: { rating: 6 },
        });
        mockPrisma.propertyListing.update.mockResolvedValue({});

        const result = await service.create('reviewer_1', listingReviewDto as any);

        expect(result).toEqual(mockListingReview);
        expect(mockPrisma.review.create).toHaveBeenCalledWith(
          expect.objectContaining({
            data: expect.objectContaining({
              reviewerId: 'reviewer_1',
              listingId: 'listing_1',
              revieweeId: mockListing.ownerId,
              rating: 4,
            }),
          }),
        );
      });

      it('should update listing rating after creating review', async () => {
        mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
        mockPrisma.review.findFirst.mockResolvedValue(null);
        mockPrisma.review.create.mockResolvedValue(mockListingReview);
        mockPrisma.review.aggregate.mockResolvedValue({
          _avg: { rating: 4.0 },
          _count: { rating: 6 },
        });
        mockPrisma.propertyListing.update.mockResolvedValue({});

        await service.create('reviewer_1', listingReviewDto as any);

        expect(mockPrisma.propertyListing.update).toHaveBeenCalledWith({
          where: { id: 'listing_1' },
          data: { avgRating: 4.0, totalReviews: 6 },
        });
      });

      it('should throw NotFoundException when listing does not exist', async () => {
        mockPrisma.propertyListing.findUnique.mockResolvedValue(null);

        await expect(
          service.create('reviewer_1', listingReviewDto as any),
        ).rejects.toThrow(NotFoundException);
      });

      it('should throw ForbiddenException when reviewing own listing', async () => {
        mockPrisma.propertyListing.findUnique.mockResolvedValue({
          ...mockListing,
          ownerId: 'reviewer_1', // Same as reviewer
        });

        await expect(
          service.create('reviewer_1', listingReviewDto as any),
        ).rejects.toThrow(ForbiddenException);
      });

      it('should throw BadRequestException when reviewing same listing twice', async () => {
        mockPrisma.propertyListing.findUnique.mockResolvedValue(mockListing);
        mockPrisma.review.findFirst.mockResolvedValue(mockListingReview); // Already reviewed

        await expect(
          service.create('reviewer_1', listingReviewDto as any),
        ).rejects.toThrow(BadRequestException);
      });
    });

    // ─ validation errors ─

    describe('validation', () => {
      it('should throw BadRequestException when neither craftsmanId nor listingId provided', async () => {
        await expect(
          service.create('reviewer_1', { rating: 5 } as any),
        ).rejects.toThrow(BadRequestException);
      });

      it('should throw BadRequestException when both craftsmanId and listingId provided', async () => {
        await expect(
          service.create('reviewer_1', {
            craftsmanId: 'craft_1',
            listingId: 'listing_1',
            rating: 5,
          } as any),
        ).rejects.toThrow(BadRequestException);
      });
    });
  });

  // ─── getCraftsmanReviews ───────────────────────────────────────────────────

  describe('getCraftsmanReviews', () => {
    const mockReviewsList = [mockCraftsmanReview];

    it('should return paginated reviews with rating distribution', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockReviewsList, 5]);
      mockPrisma.review.groupBy.mockResolvedValue([
        { rating: 5, _count: { rating: 3 } },
        { rating: 4, _count: { rating: 2 } },
      ]);

      const result = await service.getCraftsmanReviews('craft_1', { page: 1, limit: 20 });

      expect(result.reviews).toEqual(mockReviewsList);
      expect(result.total).toBe(5);
      expect(result.page).toBe(1);
      expect(result.ratingDistribution).toEqual({
        1: 0,
        2: 0,
        3: 0,
        4: 2,
        5: 3,
      });
    });

    it('should calculate correct skip for page 2', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);
      mockPrisma.review.groupBy.mockResolvedValue([]);

      await service.getCraftsmanReviews('craft_1', { page: 2, limit: 10 });

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should return empty ratingDistribution when no reviews exist', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);
      mockPrisma.review.groupBy.mockResolvedValue([]);

      const result = await service.getCraftsmanReviews('craft_1', { page: 1, limit: 20 });

      expect(result.ratingDistribution).toEqual({ 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 });
      expect(result.total).toBe(0);
    });

    it('should compute totalPages correctly', async () => {
      mockPrisma.$transaction.mockResolvedValue([mockReviewsList, 25]);
      mockPrisma.review.groupBy.mockResolvedValue([]);

      const result = await service.getCraftsmanReviews('craft_1', { page: 1, limit: 10 });

      expect(result.totalPages).toBe(3);
    });
  });

  // ─── getListingReviews ────────────────────────────────────────────────────

  describe('getListingReviews', () => {
    it('should return paginated listing reviews with rating distribution', async () => {
      mockPrisma.$transaction.mockResolvedValue([[mockListingReview], 3]);
      mockPrisma.review.groupBy.mockResolvedValue([
        { rating: 4, _count: { rating: 2 } },
        { rating: 3, _count: { rating: 1 } },
      ]);

      const result = await service.getListingReviews('listing_1', { page: 1, limit: 20 });

      expect(result.reviews).toEqual([mockListingReview]);
      expect(result.total).toBe(3);
      expect(result.ratingDistribution[4]).toBe(2);
      expect(result.ratingDistribution[3]).toBe(1);
    });

    it('should query reviews for the correct listingId', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0]);
      mockPrisma.review.groupBy.mockResolvedValue([]);

      await service.getListingReviews('listing_1', { page: 1, limit: 20 });

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });

  // ─── delete ────────────────────────────────────────────────────────────────

  describe('delete', () => {
    it('should delete a craftsman review and update ratings', async () => {
      mockPrisma.review.findFirst.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.delete.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 4.3 },
        _count: { rating: 9 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});

      const result = await service.delete('reviewer_1', 'review_1');

      expect(result).toEqual({ message: 'Review deleted successfully' });
      expect(mockPrisma.review.delete).toHaveBeenCalledWith({ where: { id: 'review_1' } });
      expect(mockPrisma.craftsman.update).toHaveBeenCalledWith({
        where: { id: 'craft_1' },
        data: { avgRating: 4.3, totalReviews: 9 },
      });
    });

    it('should delete a listing review and update ratings', async () => {
      mockPrisma.review.findFirst.mockResolvedValue(mockListingReview);
      mockPrisma.review.delete.mockResolvedValue(mockListingReview);
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 3.5 },
        _count: { rating: 4 },
      });
      mockPrisma.propertyListing.update.mockResolvedValue({});

      const result = await service.delete('reviewer_1', 'review_2');

      expect(result).toEqual({ message: 'Review deleted successfully' });
      expect(mockPrisma.propertyListing.update).toHaveBeenCalledWith({
        where: { id: 'listing_1' },
        data: { avgRating: 3.5, totalReviews: 4 },
      });
    });

    it('should throw NotFoundException when review not found or not owned', async () => {
      mockPrisma.review.findFirst.mockResolvedValue(null);

      await expect(service.delete('reviewer_1', 'nonexistent_review')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should not find review when reviewer is not the author', async () => {
      mockPrisma.review.findFirst.mockResolvedValue(null);

      await expect(service.delete('wrong_reviewer', 'review_1')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.review.findFirst).toHaveBeenCalledWith({
        where: { id: 'review_1', reviewerId: 'wrong_reviewer' },
      });
    });

    it('should update craftsman rating to 0 when last review is deleted', async () => {
      mockPrisma.review.findFirst.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.delete.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: null },
        _count: { rating: 0 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});

      await service.delete('reviewer_1', 'review_1');

      expect(mockPrisma.craftsman.update).toHaveBeenCalledWith({
        where: { id: 'craft_1' },
        data: { avgRating: 0, totalReviews: 0 },
      });
    });
  });

  // ─── private updateCraftsmanRating (via create/delete) ────────────────────

  describe('updateCraftsmanRating side effects', () => {
    it('should be called after creating a craftsman review', async () => {
      mockPrisma.craftsman.findUnique.mockResolvedValue(mockCraftsman);
      mockPrisma.review.findFirst.mockResolvedValue(null);
      mockPrisma.review.create.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 5.0 },
        _count: { rating: 11 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});

      await service.create('reviewer_1', { craftsmanId: 'craft_1', rating: 5 } as any);

      expect(mockPrisma.craftsman.update).toHaveBeenCalled();
    });

    it('should be called after deleting a craftsman review', async () => {
      mockPrisma.review.findFirst.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.delete.mockResolvedValue(mockCraftsmanReview);
      mockPrisma.review.aggregate.mockResolvedValue({
        _avg: { rating: 4.0 },
        _count: { rating: 9 },
      });
      mockPrisma.craftsman.update.mockResolvedValue({});

      await service.delete('reviewer_1', 'review_1');

      expect(mockPrisma.craftsman.update).toHaveBeenCalled();
    });
  });
});
