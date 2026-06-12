import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { AccountStatus, Role } from '@prisma/client';
import { PaginationDto, paginate } from '../../common/dto/pagination.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService,
  ) {}

  async findAll(pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        skip,
        take: limit,
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          phone: true,
          role: true,
          status: true,
          avatarUrl: true,
          isEmailVerified: true,
          createdAt: true,
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count(),
    ]);

    return paginate(users, total, page, limit);
  }

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        phone: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        role: true,
        status: true,
        isEmailVerified: true,
        isPhoneVerified: true,
        lastSeenAt: true,
        createdAt: true,
        craftsman: {
          include: {
            specialty: true,
            portfolio: true,
          },
        },
        _count: {
          select: {
            listings: true,
            reviewsGiven: true,
            reviewsReceived: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  async update(userId: string, dto: UpdateUserDto, requesterId: string, requesterRole: string) {
    // Only the user themselves or an admin can update
    if (userId !== requesterId && requesterRole !== Role.ADMIN) {
      throw new ForbiddenException('You can only update your own profile');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (dto.phone && dto.phone !== user.phone) {
      const existing = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (existing) {
        throw new ConflictException('Phone number already in use');
      }
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.firstName && { firstName: dto.firstName }),
        ...(dto.lastName && { lastName: dto.lastName }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
        ...(dto.fcmToken !== undefined && { fcmToken: dto.fcmToken }),
      },
      select: {
        id: true,
        email: true,
        phone: true,
        firstName: true,
        lastName: true,
        avatarUrl: true,
        role: true,
        status: true,
        isEmailVerified: true,
        updatedAt: true,
      },
    });

    return updated;
  }

  async updateAvatar(userId: string, file: Express.Multer.File, requesterId: string, requesterRole: string) {
    if (userId !== requesterId && requesterRole !== Role.ADMIN) {
      throw new ForbiddenException('You can only update your own avatar');
    }

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Delete old avatar if exists
    // We'd need to store publicId separately for proper deletion
    // For now, upload new one
    const result = await this.cloudinary.uploadImage(file, 'avatars', {
      width: 400,
      height: 400,
      crop: 'fill',
      gravity: 'face',
    });

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: result.url },
      select: {
        id: true,
        avatarUrl: true,
      },
    });

    return updated;
  }

  async updateStatus(userId: string, status: AccountStatus, adminId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.role === Role.ADMIN) {
      throw new ForbiddenException('Cannot change admin status');
    }

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { status },
      select: {
        id: true,
        email: true,
        status: true,
      },
    });

    this.logger.log(`Admin ${adminId} updated user ${userId} status to ${status}`);
    return updated;
  }

  async getUserStats(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        _count: {
          select: {
            listings: true,
            favorites: true,
            reviewsGiven: true,
            reviewsReceived: true,
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      userId,
      listings: user._count.listings,
      favorites: user._count.favorites,
      reviewsGiven: user._count.reviewsGiven,
      reviewsReceived: user._count.reviewsReceived,
    };
  }
}
