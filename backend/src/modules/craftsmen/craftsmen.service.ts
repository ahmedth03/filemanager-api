import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';
import { CreateCraftsmanDto } from './dto/create-craftsman.dto';
import { UpdateCraftsmanDto } from './dto/update-craftsman.dto';
import { SearchCraftsmanDto } from './dto/search-craftsman.dto';
import { paginate } from '../../common/dto/pagination.dto';

@Injectable()
export class CraftsmenService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  // ─── Create ──────────────────────────────────────────────────────────────────

  async createProfile(userId: string, dto: CreateCraftsmanDto) {
    const existing = await this.prisma.craftsman.findUnique({ where: { userId } });
    if (existing) throw new ConflictException('A craftsman profile already exists for this account');

    const specialty = await this.prisma.specialty.findUnique({ where: { id: dto.specialtyId } });
    if (!specialty) throw new NotFoundException('Specialty not found');

    const craftsman = await this.prisma.craftsman.create({
      data: {
        userId,
        specialtyId: dto.specialtyId,
        bio: dto.bio,
        yearsExperience: dto.yearsExperience ?? 0,
        wilaya: dto.wilaya,
        city: dto.city,
        address: dto.address,
        whatsappNumber: dto.whatsappNumber,
        businessPhone: dto.businessPhone,
        businessName: dto.businessName,
        status: 'PENDING',
      },
      include: {
        user: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        specialty: true,
        portfolio: true,
      },
    });

    // Upgrade role to CRAFTSMAN so they can access craftsman-gated endpoints
    await this.prisma.user.update({
      where: { id: userId },
      data: { role: 'CRAFTSMAN' },
    });

    // Invalidate any cached user profile
    await this.redis.del(`user:${userId}:profile`);

    return craftsman;
  }

  // ─── Search ───────────────────────────────────────────────────────────────────

  async search(dto: SearchCraftsmanDto) {
    const {
      page = 1,
      limit = 20,
      query,
      wilaya,
      specialtyId,
      isAvailable,
      minRating,
      city,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = dto;

    const skip = (page - 1) * limit;

    const where: any = { status: 'VERIFIED' };

    if (query) {
      where.OR = [
        { user: { firstName: { contains: query, mode: 'insensitive' } } },
        { user: { lastName: { contains: query, mode: 'insensitive' } } },
        { businessName: { contains: query, mode: 'insensitive' } },
        { bio: { contains: query, mode: 'insensitive' } },
        { city: { contains: query, mode: 'insensitive' } },
      ];
    }

    if (wilaya) where.wilaya = wilaya;
    if (specialtyId) where.specialtyId = specialtyId;
    if (isAvailable !== undefined) where.isAvailable = isAvailable;
    if (minRating) where.avgRating = { gte: minRating };
    if (city) where.city = { contains: city, mode: 'insensitive' };

    const orderBy: any = {};
    switch (sortBy) {
      case 'rating':
        orderBy.avgRating = sortOrder;
        break;
      case 'reviews':
        orderBy.totalReviews = sortOrder;
        break;
      case 'experience':
        orderBy.yearsExperience = sortOrder;
        break;
      default:
        orderBy.createdAt = sortOrder;
    }

    const [craftsmen, total] = await this.prisma.$transaction([
      this.prisma.craftsman.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              avatarUrl: true,
              phone: true,
            },
          },
          specialty: {
            select: { id: true, nameAr: true, nameFr: true, icon: true },
          },
          portfolio: {
            take: 3,
            orderBy: { order: 'asc' },
          },
        },
      }),
      this.prisma.craftsman.count({ where }),
    ]);

    return paginate(craftsmen, total, page, limit);
  }

  // ─── Find by ID ───────────────────────────────────────────────────────────────

  async findById(id: string) {
    const cacheKey = `craftsman:${id}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const craftsman = await this.prisma.craftsman.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            phone: true,
          },
        },
        specialty: true,
        portfolio: { orderBy: { order: 'asc' } },
        reviews: {
          take: 10,
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
        },
      },
    });

    if (!craftsman) throw new NotFoundException('Craftsman not found');

    await this.redis.set(cacheKey, JSON.stringify(craftsman), 600);
    return craftsman;
  }

  // ─── Find by User ID ──────────────────────────────────────────────────────────

  async findByUserId(userId: string) {
    const craftsman = await this.prisma.craftsman.findUnique({
      where: { userId },
      include: {
        specialty: true,
        portfolio: { orderBy: { order: 'asc' } },
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            phone: true,
          },
        },
      },
    });

    if (!craftsman) throw new NotFoundException('Craftsman profile not found');
    return craftsman;
  }

  // ─── Update ───────────────────────────────────────────────────────────────────

  async updateProfile(userId: string, dto: UpdateCraftsmanDto) {
    const craftsman = await this.prisma.craftsman.findUnique({ where: { userId } });
    if (!craftsman) throw new NotFoundException('Craftsman profile not found');

    // If specialtyId changes, validate it exists
    if (dto.specialtyId && dto.specialtyId !== craftsman.specialtyId) {
      const specialty = await this.prisma.specialty.findUnique({
        where: { id: dto.specialtyId },
      });
      if (!specialty) throw new NotFoundException('Specialty not found');
    }

    const updated = await this.prisma.craftsman.update({
      where: { userId },
      data: {
        ...(dto.specialtyId !== undefined && { specialtyId: dto.specialtyId }),
        ...(dto.bio !== undefined && { bio: dto.bio }),
        ...(dto.yearsExperience !== undefined && { yearsExperience: dto.yearsExperience }),
        ...(dto.wilaya !== undefined && { wilaya: dto.wilaya }),
        ...(dto.city !== undefined && { city: dto.city }),
        ...(dto.address !== undefined && { address: dto.address }),
        ...(dto.whatsappNumber !== undefined && { whatsappNumber: dto.whatsappNumber }),
        ...(dto.businessPhone !== undefined && { businessPhone: dto.businessPhone }),
        ...(dto.businessName !== undefined && { businessName: dto.businessName }),
        ...(dto.isAvailable !== undefined && { isAvailable: dto.isAvailable }),
      },
      include: {
        specialty: true,
        user: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        portfolio: { orderBy: { order: 'asc' } },
      },
    });

    await this.redis.del(`craftsman:${craftsman.id}`);
    return updated;
  }

  // ─── Portfolio ────────────────────────────────────────────────────────────────

  async addPortfolioItem(
    userId: string,
    file: Express.Multer.File,
    title: string,
    description?: string,
  ) {
    const craftsman = await this.prisma.craftsman.findUnique({ where: { userId } });
    if (!craftsman) throw new NotFoundException('Craftsman profile not found');

    const result = await this.cloudinary.uploadImage(file, `portfolio/${craftsman.id}`);
    const count = await this.prisma.portfolioItem.count({
      where: { craftsmanId: craftsman.id },
    });

    const item = await this.prisma.portfolioItem.create({
      data: {
        craftsmanId: craftsman.id,
        title,
        description,
        imageUrl: result.url,
        publicId: result.publicId,
        order: count,
      },
    });

    await this.redis.del(`craftsman:${craftsman.id}`);
    return item;
  }

  async deletePortfolioItem(userId: string, itemId: string) {
    const craftsman = await this.prisma.craftsman.findUnique({ where: { userId } });
    if (!craftsman) throw new NotFoundException('Craftsman profile not found');

    const item = await this.prisma.portfolioItem.findFirst({
      where: { id: itemId, craftsmanId: craftsman.id },
    });
    if (!item) throw new NotFoundException('Portfolio item not found');

    await this.cloudinary.deleteImage(item.publicId);
    await this.prisma.portfolioItem.delete({ where: { id: itemId } });
    await this.redis.del(`craftsman:${craftsman.id}`);

    return { message: 'Portfolio item deleted successfully' };
  }

  // ─── Featured ─────────────────────────────────────────────────────────────────

  async getFeatured(limit = 8) {
    const cacheKey = `craftsmen:featured:${limit}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const craftsmen = await this.prisma.craftsman.findMany({
      where: {
        status: 'VERIFIED',
        isAvailable: true,
        avgRating: { gte: 4 },
      },
      take: limit,
      orderBy: [{ avgRating: 'desc' }, { totalReviews: 'desc' }],
      include: {
        user: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        specialty: {
          select: { id: true, nameAr: true, nameFr: true, icon: true },
        },
        portfolio: { take: 1, orderBy: { order: 'asc' } },
      },
    });

    await this.redis.set(cacheKey, JSON.stringify(craftsmen), 1800);
    return craftsmen;
  }

  // ─── Rating Aggregation (called from ReviewsService) ──────────────────────────

  async updateAvgRating(craftsmanId: string) {
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

    // Bust the craftsman detail cache and the featured cache
    await this.redis.del(`craftsman:${craftsmanId}`);
    await this.redis.invalidatePattern('craftsmen:featured:*');
  }
}
