import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { ListingFilterDto } from './dto/listing-filter.dto';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { paginate } from '../common/utils/pagination.util';

@Injectable()
export class ListingsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filter: ListingFilterDto, userId?: string) {
    const page = filter.page ?? 1;
    const limit = filter.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: any = {
      status: 'ACTIVE',
      ...(filter.wilaya && { wilaya: filter.wilaya }),
      ...(filter.type && { type: filter.type }),
      ...(filter.rooms !== undefined && { rooms: filter.rooms }),
      ...(filter.isFurnished !== undefined && { isFurnished: filter.isFurnished }),
      ...((filter.minPrice !== undefined || filter.maxPrice !== undefined) && {
        price: {
          ...(filter.minPrice !== undefined && { gte: filter.minPrice }),
          ...(filter.maxPrice !== undefined && { lte: filter.maxPrice }),
        },
      }),
      ...(filter.search && {
        OR: [
          { title: { contains: filter.search, mode: 'insensitive' } },
          { description: { contains: filter.search, mode: 'insensitive' } },
          { city: { contains: filter.search, mode: 'insensitive' } },
        ],
      }),
    };

    let orderBy: any = { publishedAt: 'desc' };
    if (filter.sortBy === 'price_asc') orderBy = { price: 'asc' };
    else if (filter.sortBy === 'price_desc') orderBy = { price: 'desc' };
    else if (filter.sortBy === 'newest') orderBy = { publishedAt: 'desc' };

    const [listings, total] = await Promise.all([
      this.prisma.propertyListing.findMany({
        where,
        skip,
        take: limit,
        orderBy,
        include: {
          owner: {
            select: {
              firstName: true,
              lastName: true,
              avatarUrl: true,
            },
          },
          images: {
            where: { isCover: true },
            take: 1,
          },
          ...(userId && {
            favorites: {
              where: { userId },
              select: { id: true },
            },
          }),
        },
      }),
      this.prisma.propertyListing.count({ where }),
    ]);

    const data = listings.map((listing) => ({
      ...listing,
      price: listing.price.toNumber(),
      isFavorited: userId ? (listing.favorites?.length ?? 0) > 0 : false,
      favorites: undefined,
    }));

    return paginate(data, total, page, limit);
  }

  async findOne(id: string, userId?: string) {
    const listing = await this.prisma.propertyListing.findFirst({
      where: { id, status: 'ACTIVE' },
      include: {
        owner: {
          select: {
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        images: {
          orderBy: { order: 'asc' },
        },
        ...(userId && {
          favorites: {
            where: { userId },
            select: { id: true },
          },
        }),
      },
    });

    if (!listing) {
      throw new NotFoundException(`Listing with id ${id} not found`);
    }

    await this.prisma.propertyListing.update({
      where: { id },
      data: { viewCount: { increment: 1 } },
    });

    return {
      ...listing,
      price: listing.price.toNumber(),
      isFavorited: userId ? (listing.favorites?.length ?? 0) > 0 : false,
      favorites: undefined,
    };
  }

  async create(ownerId: string, dto: CreateListingDto) {
    const listing = await this.prisma.propertyListing.create({
      data: {
        ownerId,
        title: dto.title,
        description: dto.description,
        type: dto.type as any,
        status: 'ACTIVE',
        price: dto.price,
        pricePeriod: dto.pricePeriod ?? 'monthly',
        wilaya: dto.wilaya as any,
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
        isAvailable: true,
        publishedAt: new Date(),
      },
    });

    return {
      ...listing,
      price: listing.price.toNumber(),
    };
  }

  async update(id: string, ownerId: string, dto: UpdateListingDto) {
    const listing = await this.prisma.propertyListing.findUnique({ where: { id } });

    if (!listing) {
      throw new NotFoundException(`Listing with id ${id} not found`);
    }

    if (listing.ownerId !== ownerId) {
      throw new ForbiddenException('You are not allowed to update this listing');
    }

    const updated = await this.prisma.propertyListing.update({
      where: { id },
      data: {
        ...(dto.title && { title: dto.title }),
        ...(dto.description && { description: dto.description }),
        ...(dto.type && { type: dto.type as any }),
        ...(dto.price !== undefined && { price: dto.price }),
        ...(dto.pricePeriod && { pricePeriod: dto.pricePeriod }),
        ...(dto.wilaya && { wilaya: dto.wilaya as any }),
        ...(dto.city && { city: dto.city }),
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
      },
    });

    return {
      ...updated,
      price: updated.price.toNumber(),
    };
  }

  async delete(id: string, ownerId: string) {
    const listing = await this.prisma.propertyListing.findUnique({ where: { id } });

    if (!listing) {
      throw new NotFoundException(`Listing with id ${id} not found`);
    }

    if (listing.ownerId !== ownerId) {
      throw new ForbiddenException('You are not allowed to delete this listing');
    }

    await this.prisma.propertyListing.update({
      where: { id },
      data: { status: 'ARCHIVED' },
    });

    return { message: 'Listing archived successfully' };
  }

  async getMyListings(ownerId: string) {
    const listings = await this.prisma.propertyListing.findMany({
      where: { ownerId },
      include: {
        images: {
          orderBy: { order: 'asc' },
        },
      },
      orderBy: { publishedAt: 'desc' },
    });

    return listings.map((listing) => ({
      ...listing,
      price: listing.price.toNumber(),
    }));
  }
}
