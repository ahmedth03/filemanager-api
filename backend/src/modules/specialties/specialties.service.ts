import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';

const CACHE_KEY = 'specialties:all';
const CACHE_TTL = 3600; // 1 hour

@Injectable()
export class SpecialtiesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
  ) {}

  async findAll() {
    const cached = await this.redis.get(CACHE_KEY);
    if (cached) return JSON.parse(cached);

    const specialties = await this.prisma.specialty.findMany({
      where: { isActive: true },
      include: {
        _count: { select: { craftsmen: { where: { status: 'VERIFIED' } } } },
      },
      orderBy: { nameAr: 'asc' },
    });

    await this.redis.set(CACHE_KEY, JSON.stringify(specialties), CACHE_TTL);
    return specialties;
  }

  async findById(id: string) {
    const specialty = await this.prisma.specialty.findUnique({ where: { id } });
    if (!specialty) throw new NotFoundException('Specialty not found');
    return specialty;
  }

  async create(data: {
    nameAr: string;
    nameFr: string;
    nameEn: string;
    icon?: string;
  }) {
    const specialty = await this.prisma.specialty.create({ data });
    await this.redis.del(CACHE_KEY);
    return specialty;
  }

  async update(
    id: string,
    data: Partial<{
      nameAr: string;
      nameFr: string;
      nameEn: string;
      icon: string;
      isActive: boolean;
    }>,
  ) {
    await this.findById(id);
    const specialty = await this.prisma.specialty.update({ where: { id }, data });
    await this.redis.del(CACHE_KEY);
    return specialty;
  }
}
