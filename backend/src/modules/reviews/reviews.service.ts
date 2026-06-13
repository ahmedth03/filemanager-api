import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { PaginationDto } from '../../common/dto/pagination.dto';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async create(reviewerId: string, dto: CreateReviewDto) {
    if (!dto.craftsmanId && !dto.listingId) {
      throw new BadRequestException('Either craftsmanId or listingId must be provided');
    }
    if (dto.craftsmanId && dto.listingId) {
      throw new BadRequestException('Only one of craftsmanId or listingId should be provided');
    }

    if (dto.craftsmanId) {
      const craftsman = await this.prisma.craftsman.findUnique({
        where: { id: dto.craftsmanId },
      });
      if (!craftsman) throw new NotFoundException('Craftsman not found');
      if (craftsman.userId === reviewerId) {
        throw new ForbiddenException('Cannot review yourself');
      }

      const existing = await this.prisma.review.findFirst({
        where: { reviewerId, craftsmanId: dto.craftsmanId },
      });
      if (existing) throw new BadRequestException('You have already reviewed this craftsman');

      const review = await this.prisma.review.create({
        data: {
          reviewerId,
          craftsmanId: dto.craftsmanId,
          revieweeId: craftsman.userId,
          rating: dto.rating,
          comment: dto.comment,
        },
        include: {
          reviewer: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
        },
      });

      await this.updateCraftsmanRating(dto.craftsmanId);
      return review;
    }

    if (dto.listingId) {
      const listing = await this.prisma.propertyListing.findUnique({
        where: { id: dto.listingId },
      });
      if (!listing) throw new NotFoundException('Listing not found');
      if (listing.ownerId === reviewerId) {
        throw new ForbiddenException('Cannot review your own listing');
      }

      const existing = await this.prisma.review.findFirst({
        where: { reviewerId, listingId: dto.listingId },
      });
      if (existing) throw new BadRequestException('You have already reviewed this listing');

      const review = await this.prisma.review.create({
        data: {
          reviewerId,
          listingId: dto.listingId,
          revieweeId: listing.ownerId,
          rating: dto.rating,
          comment: dto.comment,
        },
        include: {
          reviewer: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
        },
      });

      await this.updateListingRating(dto.listingId);
      return review;
    }
  }

  async getCraftsmanReviews(craftsmanId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [reviews, total] = await this.prisma.$transaction([
      this.prisma.review.findMany({
        where: { craftsmanId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewer: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
        },
      }),
      this.prisma.review.count({ where: { craftsmanId } }),
    ]);

    const stats = await this.prisma.review.groupBy({
      by: ['rating'],
      where: { craftsmanId },
      _count: { rating: true },
    });

    const ratingDistribution: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    stats.forEach((s) => {
      ratingDistribution[s.rating] = s._count.rating;
    });

    return {
      reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      ratingDistribution,
    };
  }

  async getListingReviews(listingId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [reviews, total] = await this.prisma.$transaction([
      this.prisma.review.findMany({
        where: { listingId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewer: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
        },
      }),
      this.prisma.review.count({ where: { listingId } }),
    ]);

    const stats = await this.prisma.review.groupBy({
      by: ['rating'],
      where: { listingId },
      _count: { rating: true },
    });

    const ratingDistribution: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    stats.forEach((s) => {
      ratingDistribution[s.rating] = s._count.rating;
    });

    return {
      reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      ratingDistribution,
    };
  }

  async delete(reviewerId: string, reviewId: string) {
    const review = await this.prisma.review.findFirst({
      where: { id: reviewId, reviewerId },
    });
    if (!review) throw new NotFoundException('Review not found or unauthorized');

    await this.prisma.review.delete({ where: { id: reviewId } });

    if (review.craftsmanId) await this.updateCraftsmanRating(review.craftsmanId);
    if (review.listingId) await this.updateListingRating(review.listingId);

    return { message: 'Review deleted successfully' };
  }

  private async updateCraftsmanRating(craftsmanId: string) {
    const result = await this.prisma.review.aggregate({
      where: { craftsmanId },
      _avg: { rating: true },
      _count: { rating: true },
    });
    await this.prisma.craftsman.update({
      where: { id: craftsmanId },
      data: {
        avgRating: result._avg.rating || 0,
        totalReviews: result._count.rating,
      },
    });
  }

  private async updateListingRating(listingId: string) {
    const result = await this.prisma.review.aggregate({
      where: { listingId },
      _avg: { rating: true },
      _count: { rating: true },
    });
    await this.prisma.propertyListing.update({
      where: { id: listingId },
      data: {
        avgRating: result._avg.rating || 0,
        totalReviews: result._count.rating,
      },
    });
  }
}
