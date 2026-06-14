import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(reviewerId: string, dto: CreateReviewDto) {
    if (!dto.craftsmanId && !dto.listingId && !dto.revieweeId) {
      throw new BadRequestException(
        'At least one of craftsmanId, listingId, or revieweeId must be provided',
      );
    }

    const review = await this.prisma.review.create({
      data: {
        reviewerId,
        rating: dto.rating,
        comment: dto.comment,
        craftsmanId: dto.craftsmanId,
        listingId: dto.listingId,
        revieweeId: dto.revieweeId,
        isVerified: false,
      },
      include: {
        reviewer: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
      },
    });

    if (dto.craftsmanId) {
      await this.updateCraftsmanRating(dto.craftsmanId);
    }

    if (dto.listingId) {
      await this.updateListingRating(dto.listingId);
    }

    return review;
  }

  async findForCraftsman(craftsmanId: string, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { craftsmanId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewer: {
            select: { id: true, firstName: true, lastName: true, avatarUrl: true },
          },
        },
      }),
      this.prisma.review.count({ where: { craftsmanId } }),
    ]);

    return { reviews, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async findForListing(listingId: string, page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { listingId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          reviewer: {
            select: { id: true, firstName: true, lastName: true, avatarUrl: true },
          },
        },
      }),
      this.prisma.review.count({ where: { listingId } }),
    ]);

    return { reviews, total, page, limit, totalPages: Math.ceil(total / limit) };
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
        avgRating: result._avg.rating ?? 0,
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
        avgRating: result._avg.rating ?? 0,
        totalReviews: result._count.rating,
      },
    });
  }
}
