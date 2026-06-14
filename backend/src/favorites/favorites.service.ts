import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { ToggleFavoriteDto } from './dto/toggle-favorite.dto';

@Injectable()
export class FavoritesService {
  constructor(private readonly prisma: PrismaService) {}

  async toggle(userId: string, dto: ToggleFavoriteDto) {
    if (!dto.listingId && !dto.craftsmanId) {
      throw new BadRequestException('Either listingId or craftsmanId must be provided');
    }

    if (dto.listingId && dto.craftsmanId) {
      throw new BadRequestException('Only one of listingId or craftsmanId can be provided');
    }

    if (dto.listingId) {
      const existing = await this.prisma.favorite.findUnique({
        where: { userId_listingId: { userId, listingId: dto.listingId } },
      });

      if (existing) {
        await this.prisma.favorite.delete({ where: { id: existing.id } });
        return { favorited: false };
      }

      const favorite = await this.prisma.favorite.create({
        data: { userId, listingId: dto.listingId },
      });
      return { favorited: true, favorite };
    }

    // craftsmanId
    const existing = await this.prisma.favorite.findUnique({
      where: { userId_craftsmanId: { userId, craftsmanId: dto.craftsmanId } },
    });

    if (existing) {
      await this.prisma.favorite.delete({ where: { id: existing.id } });
      return { favorited: false };
    }

    const favorite = await this.prisma.favorite.create({
      data: { userId, craftsmanId: dto.craftsmanId },
    });
    return { favorited: true, favorite };
  }

  async getUserFavorites(userId: string) {
    return this.prisma.favorite.findMany({
      where: { userId },
      include: {
        listing: {
          include: {
            images: { where: { isCover: true } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async checkFavorite(userId: string, dto: ToggleFavoriteDto) {
    if (!dto.listingId && !dto.craftsmanId) {
      throw new BadRequestException('Either listingId or craftsmanId must be provided');
    }

    let existing = null;

    if (dto.listingId) {
      existing = await this.prisma.favorite.findUnique({
        where: { userId_listingId: { userId, listingId: dto.listingId } },
      });
    } else {
      existing = await this.prisma.favorite.findUnique({
        where: { userId_craftsmanId: { userId, craftsmanId: dto.craftsmanId } },
      });
    }

    return { isFavorited: !!existing };
  }
}
