import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { CraftsmanFilterDto } from './dto/craftsman-filter.dto';
import { paginate } from '../common/utils/pagination.util';

@Injectable()
export class CraftsmenService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filter: CraftsmanFilterDto) {
    const page = filter.page ?? 1;
    const limit = filter.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: any = {
      status: 'VERIFIED',
      ...(filter.wilaya && { wilaya: filter.wilaya }),
      ...(filter.specialtyId && { specialtyId: filter.specialtyId }),
      ...(filter.isAvailable !== undefined && { isAvailable: filter.isAvailable }),
      ...(filter.search && {
        OR: [
          { user: { firstName: { contains: filter.search, mode: 'insensitive' } } },
          { user: { lastName: { contains: filter.search, mode: 'insensitive' } } },
          { businessName: { contains: filter.search, mode: 'insensitive' } },
          { city: { contains: filter.search, mode: 'insensitive' } },
        ],
      }),
    };

    const [data, total] = await Promise.all([
      this.prisma.craftsman.findMany({
        where,
        skip,
        take: limit,
        include: {
          user: {
            select: {
              firstName: true,
              lastName: true,
              avatarUrl: true,
              phone: true,
            },
          },
          specialty: true,
        },
        orderBy: { avgRating: 'desc' },
      }),
      this.prisma.craftsman.count({ where }),
    ]);

    return paginate(data, total, page, limit);
  }

  async findOne(id: string) {
    const craftsman = await this.prisma.craftsman.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            firstName: true,
            lastName: true,
            avatarUrl: true,
            phone: true,
          },
        },
        specialty: true,
        portfolio: {
          orderBy: { order: 'asc' },
        },
      },
    });

    if (!craftsman) {
      throw new NotFoundException(`Craftsman with id ${id} not found`);
    }

    return craftsman;
  }

  async getSpecialties() {
    return this.prisma.specialty.findMany({
      where: { isActive: true },
      orderBy: { nameAr: 'asc' },
    });
  }
}
