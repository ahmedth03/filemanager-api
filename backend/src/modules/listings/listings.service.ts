import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { SearchListingDto } from './dto/search-listing.dto';
import { PaginationDto, paginate } from '../../common/dto/pagination.dto';

const LISTING_CACHE_TTL = 600;        // 10 minutes
const FEATURED_CACHE_TTL = 1800;      // 30 minutes
const MAX_IMAGES_PER_LISTING = 20;

@Injectable()
export class ListingsService {
  private readonly logger = new Logger(ListingsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly cloudinary: CloudinaryService,
  ) {}

  // ─── Create ───────────────────────────────────────────────────────────────────

  async create(ownerId: string, dto: CreateListingDto) {
    const listing = await this.prisma.propertyListing.create({
      data: {
        ownerId,
        title: dto.title,
        description: dto.description,
        type: dto.type,
        price: dto.price,
        pricePeriod: dto.pricePeriod ?? 'monthly',
        wilaya: dto.wilaya,
        city: dto.city,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
        rooms: dto.rooms,
        bathrooms: dto.bathrooms ?? 1,
        area: dto.area,
        floor: dto.floor,
        totalFloors: dto.totalFloors,
        hasParking: dto.hasParking ?? false,
        hasElevator: dto.hasElevator ?? false,
        hasBalcony: dto.hasBalcony ?? false,
        isFurnished: dto.isFurnished ?? false,
        status: 'DRAFT',
      },
      include: {
        owner: { select: { id: true, firstName: true, lastName: true, avatarUrl: true, phone: true } },
        images: { orderBy: { order: 'asc' } },
      },
    });

    await this.redis.invalidatePattern('listings:featured:*');
    return listing;
  }

  // ─── Search ───────────────────────────────────────────────────────────────────

  async search(dto: SearchListingDto) {
    const {
      page = 1,
      limit = 20,
      query,
      wilaya,
      type,
      city,
      minPrice,
      maxPrice,
      minRooms,
      maxRooms,
      isFurnished,
      hasParking,
      hasElevator,
      sortBy = 'createdAt',
      sortOrder = 'desc',
    } = dto;

    const skip = (page - 1) * limit;

    const where: any = {
      status: 'ACTIVE',
      isAvailable: true,
    };

    if (query) {
      where.OR = [
        { title: { contains: query, mode: 'insensitive' } },
        { description: { contains: query, mode: 'insensitive' } },
        { city: { contains: query, mode: 'insensitive' } },
        { address: { contains: query, mode: 'insensitive' } },
      ];
    }

    if (wilaya) where.wilaya = wilaya;
    if (type) where.type = type;
    if (city) where.city = { contains: city, mode: 'insensitive' };

    if (minPrice !== undefined || maxPrice !== undefined) {
      where.price = {};
      if (minPrice !== undefined) where.price.gte = minPrice;
      if (maxPrice !== undefined) where.price.lte = maxPrice;
    }

    if (minRooms !== undefined || maxRooms !== undefined) {
      where.rooms = {};
      if (minRooms !== undefined) where.rooms.gte = minRooms;
      if (maxRooms !== undefined) where.rooms.lte = maxRooms;
    }

    if (isFurnished !== undefined) where.isFurnished = isFurnished;
    if (hasParking !== undefined) where.hasParking = hasParking;
    if (hasElevator !== undefined) where.hasElevator = hasElevator;

    const orderBy: any = {};
    switch (sortBy) {
      case 'price':
        orderBy.price = sortOrder;
        break;
      case 'views':
        orderBy.viewCount = sortOrder;
        break;
      case 'rating':
        orderBy.avgRating = sortOrder;
        break;
      default:
        orderBy.createdAt = sortOrder;
    }

    const [listings, total] = await this.prisma.$transaction([
      this.prisma.propertyListing.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          owner: { select: { id: true, firstName: true, lastName: true, avatarUrl: true, phone: true } },
          images: {
            where: { isCover: true },
            take: 1,
            orderBy: { order: 'asc' },
          },
        },
      }),
      this.prisma.propertyListing.count({ where }),
    ]);

    return paginate(listings, total, page, limit);
  }

  // ─── Find by ID ───────────────────────────────────────────────────────────────

  async findById(id: string) {
    const cacheKey = `listing:${id}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const listing = await this.prisma.propertyListing.findUnique({
      where: { id },
      include: {
        owner: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            phone: true,
          },
        },
        images: { orderBy: { order: 'asc' } },
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
        _count: {
          select: { favorites: true },
        },
      },
    });

    if (!listing) throw new NotFoundException('Listing not found');

    await this.redis.set(cacheKey, JSON.stringify(listing), LISTING_CACHE_TTL);
    return listing;
  }

  // ─── Update ───────────────────────────────────────────────────────────────────

  async update(ownerId: string, id: string, dto: UpdateListingDto) {
    const listing = await this.prisma.propertyListing.findUnique({ where: { id } });
    if (!listing) throw new NotFoundException('Listing not found');
    if (listing.ownerId !== ownerId) throw new ForbiddenException('You do not own this listing');

    // When activating a listing for the first time, stamp the publish date
    const publishedAt =
      dto.status === 'ACTIVE' && listing.status !== 'ACTIVE'
        ? new Date()
        : undefined;

    const updated = await this.prisma.propertyListing.update({
      where: { id },
      data: {
        ...(dto.title !== undefined && { title: dto.title }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.type !== undefined && { type: dto.type }),
        ...(dto.price !== undefined && { price: dto.price }),
        ...(dto.pricePeriod !== undefined && { pricePeriod: dto.pricePeriod }),
        ...(dto.wilaya !== undefined && { wilaya: dto.wilaya }),
        ...(dto.city !== undefined && { city: dto.city }),
        ...(dto.address !== undefined && { address: dto.address }),
        ...(dto.latitude !== undefined && { latitude: dto.latitude }),
        ...(dto.longitude !== undefined && { longitude: dto.longitude }),
        ...(dto.rooms !== undefined && { rooms: dto.rooms }),
        ...(dto.bathrooms !== undefined && { bathrooms: dto.bathrooms }),
        ...(dto.area !== undefined && { area: dto.area }),
        ...(dto.floor !== undefined && { floor: dto.floor }),
        ...(dto.totalFloors !== undefined && { totalFloors: dto.totalFloors }),
        ...(dto.hasParking !== undefined && { hasParking: dto.hasParking }),
        ...(dto.hasElevator !== undefined && { hasElevator: dto.hasElevator }),
        ...(dto.hasBalcony !== undefined && { hasBalcony: dto.hasBalcony }),
        ...(dto.isFurnished !== undefined && { isFurnished: dto.isFurnished }),
        ...(dto.status !== undefined && { status: dto.status }),
        ...(publishedAt && { publishedAt }),
      },
      include: {
        owner: { select: { id: true, firstName: true, lastName: true, avatarUrl: true } },
        images: { orderBy: { order: 'asc' } },
      },
    });

    await this.redis.del(`listing:${id}`);
    await this.redis.invalidatePattern('listings:featured:*');
    return updated;
  }

  // ─── Soft Delete ──────────────────────────────────────────────────────────────

  async delete(ownerId: string, id: string) {
    const listing = await this.prisma.propertyListing.findUnique({ where: { id } });
    if (!listing) throw new NotFoundException('Listing not found');
    if (listing.ownerId !== ownerId) throw new ForbiddenException('You do not own this listing');

    await this.prisma.propertyListing.update({
      where: { id },
      data: { status: 'ARCHIVED', isAvailable: false },
    });

    await this.redis.del(`listing:${id}`);
    await this.redis.invalidatePattern('listings:featured:*');

    return { message: 'Listing archived successfully' };
  }

  // ─── Images ───────────────────────────────────────────────────────────────────

  async addImages(ownerId: string, listingId: string, files: Express.Multer.File[]) {
    if (!files || files.length === 0) {
      throw new BadRequestException('No image files provided');
    }

    const listing = await this.prisma.propertyListing.findUnique({
      where: { id: listingId },
      include: { _count: { select: { images: true } } },
    });
    if (!listing) throw new NotFoundException('Listing not found');
    if (listing.ownerId !== ownerId) throw new ForbiddenException('You do not own this listing');

    const currentCount = listing._count.images;
    if (currentCount + files.length > MAX_IMAGES_PER_LISTING) {
      throw new BadRequestException(
        `Cannot exceed ${MAX_IMAGES_PER_LISTING} images per listing. Currently has ${currentCount}.`,
      );
    }

    const uploaded = await this.cloudinary.uploadMultipleImages(files, `listings/${listingId}`);
    const isFirstImages = currentCount === 0;

    const images = await this.prisma.$transaction(
      uploaded.map((result, index) =>
        this.prisma.listingImage.create({
          data: {
            listingId,
            url: result.url,
            publicId: result.publicId,
            isCover: isFirstImages && index === 0,
            order: currentCount + index,
          },
        }),
      ),
    );

    await this.redis.del(`listing:${listingId}`);
    return images;
  }

  async removeImage(ownerId: string, imageId: string) {
    const image = await this.prisma.listingImage.findUnique({
      where: { id: imageId },
      include: { listing: { select: { ownerId: true, id: true } } },
    });
    if (!image) throw new NotFoundException('Image not found');
    if (image.listing.ownerId !== ownerId) throw new ForbiddenException('You do not own this listing');

    await this.cloudinary.deleteImage(image.publicId);
    await this.prisma.listingImage.delete({ where: { id: imageId } });

    // If the deleted image was the cover, promote the next image
    if (image.isCover) {
      const nextImage = await this.prisma.listingImage.findFirst({
        where: { listingId: image.listingId },
        orderBy: { order: 'asc' },
      });
      if (nextImage) {
        await this.prisma.listingImage.update({
          where: { id: nextImage.id },
          data: { isCover: true },
        });
      }
    }

    await this.redis.del(`listing:${image.listing.id}`);
    return { message: 'Image removed successfully' };
  }

  async setCoverImage(ownerId: string, imageId: string) {
    const image = await this.prisma.listingImage.findUnique({
      where: { id: imageId },
      include: { listing: { select: { ownerId: true, id: true } } },
    });
    if (!image) throw new NotFoundException('Image not found');
    if (image.listing.ownerId !== ownerId) throw new ForbiddenException('You do not own this listing');

    // Unset any existing cover, then set the new one
    await this.prisma.$transaction([
      this.prisma.listingImage.updateMany({
        where: { listingId: image.listingId },
        data: { isCover: false },
      }),
      this.prisma.listingImage.update({
        where: { id: imageId },
        data: { isCover: true },
      }),
    ]);

    await this.redis.del(`listing:${image.listing.id}`);
    return { message: 'Cover image updated successfully' };
  }

  // ─── Featured ─────────────────────────────────────────────────────────────────

  async getFeatured(limit = 8) {
    const cacheKey = `listings:featured:${limit}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const listings = await this.prisma.propertyListing.findMany({
      where: {
        status: 'ACTIVE',
        isAvailable: true,
      },
      take: limit,
      orderBy: [{ viewCount: 'desc' }, { avgRating: 'desc' }, { createdAt: 'desc' }],
      include: {
        owner: { select: { id: true, firstName: true, lastName: true, avatarUrl: true } },
        images: {
          where: { isCover: true },
          take: 1,
        },
      },
    });

    await this.redis.set(cacheKey, JSON.stringify(listings), FEATURED_CACHE_TTL);
    return listings;
  }

  // ─── View Count ───────────────────────────────────────────────────────────────

  async incrementViewCount(id: string) {
    // Use Redis to throttle view counts — one increment per listing per hour
    const throttleKey = `listing:${id}:view_throttle`;
    const already = await this.redis.exists(throttleKey);
    if (already) return;

    await this.prisma.propertyListing.update({
      where: { id },
      data: { viewCount: { increment: 1 } },
    });

    // Bust detail cache so the updated count is served
    await this.redis.del(`listing:${id}`);
    // Set throttle key for 1 hour
    await this.redis.set(throttleKey, '1', 3600);
  }

  // ─── Rating Aggregation (called from ReviewsService) ─────────────────────────

  async updateAvgRating(listingId: string) {
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

    await this.redis.del(`listing:${listingId}`);
    await this.redis.invalidatePattern('listings:featured:*');
  }

  // ─── My Listings ──────────────────────────────────────────────────────────────

  async getMyListings(ownerId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [listings, total] = await this.prisma.$transaction([
      this.prisma.propertyListing.findMany({
        where: { ownerId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          images: {
            where: { isCover: true },
            take: 1,
          },
          _count: {
            select: { favorites: true, reviews: true, chatRooms: true },
          },
        },
      }),
      this.prisma.propertyListing.count({ where: { ownerId } }),
    ]);

    return paginate(listings, total, page, limit);
  }
}
