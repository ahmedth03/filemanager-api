import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { PaginationDto } from '../../common/dto/pagination.dto';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  async addListing(userId: string, listingId: string) {
    const listing = await this.prisma.propertyListing.findUnique({
      where: { id: listingId },
    });
    if (!listing) throw new NotFoundException('Listing not found');

    const existing = await this.prisma.favorite.findFirst({
      where: { userId, listingId },
    });
    if (existing) throw new ConflictException('Listing is already in favorites');

    return this.prisma.favorite.create({ data: { userId, listingId } });
  }

  async removeListing(userId: string, listingId: string) {
    const favorite = await this.prisma.favorite.findFirst({
      where: { userId, listingId },
    });
    if (!favorite) throw new NotFoundException('Favorite not found');

    await this.prisma.favorite.delete({ where: { id: favorite.id } });
    return { message: 'Removed from favorites' };
  }

  async addCraftsman(userId: string, craftsmanId: string) {
    const craftsman = await this.prisma.craftsman.findUnique({
      where: { id: craftsmanId },
    });
    if (!craftsman) throw new NotFoundException('Craftsman not found');

    const existing = await this.prisma.favorite.findFirst({
      where: { userId, craftsmanId },
    });
    if (existing) throw new ConflictException('Craftsman is already in favorites');

    return this.prisma.favorite.create({ data: { userId, craftsmanId } });
  }

  async removeCraftsman(userId: string, craftsmanId: string) {
    const favorite = await this.prisma.favorite.findFirst({
      where: { userId, craftsmanId },
    });
    if (!favorite) throw new NotFoundException('Favorite not found');

    await this.prisma.favorite.delete({ where: { id: favorite.id } });
    return { message: 'Removed from favorites' };
  }

  async getMyFavoriteListings(userId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [favorites, total] = await this.prisma.$transaction([
      this.prisma.favorite.findMany({
        where: { userId, listingId: { not: null } },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          listing: {
            include: {
              images: { where: { isCover: true }, take: 1 },
              owner: {
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
      }),
      this.prisma.favorite.count({ where: { userId, listingId: { not: null } } }),
    ]);

    return {
      favorites: favorites.map((f) => f.listing),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getMyFavoriteCraftsmen(userId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [favorites, total] = await this.prisma.$transaction([
      this.prisma.favorite.findMany({
        where: { userId, craftsmanId: { not: null } },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.favorite.count({ where: { userId, craftsmanId: { not: null } } }),
    ]);

    const craftsmanIds = favorites
      .map((f) => f.craftsmanId)
      .filter((id): id is string => id !== null);

    const craftsmen = await this.prisma.craftsman.findMany({
      where: { id: { in: craftsmanIds } },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
          },
        },
        specialty: {
          select: {
            id: true,
            nameAr: true,
            nameFr: true,
            icon: true,
          },
        },
        portfolio: { take: 1 },
      },
    });

    return {
      craftsmen,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async checkListingFavorite(userId: string, listingId: string): Promise<{ isFavorited: boolean }> {
    const favorite = await this.prisma.favorite.findFirst({
      where: { userId, listingId },
    });
    return { isFavorited: !!favorite };
  }

  async checkCraftsmanFavorite(userId: string, craftsmanId: string): Promise<{ isFavorited: boolean }> {
    const favorite = await this.prisma.favorite.findFirst({
      where: { userId, craftsmanId },
    });
    return { isFavorited: !!favorite };
  }
}
