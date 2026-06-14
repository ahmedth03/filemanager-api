import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    const { passwordHash, refreshToken, ...safeUser } = user;
    return safeUser;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.firstName !== undefined && { firstName: dto.firstName }),
        ...(dto.lastName !== undefined && { lastName: dto.lastName }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
      },
    });
    const { passwordHash, refreshToken, ...safeUser } = user;
    return safeUser;
  }

  async updateAvatar(userId: string, avatarUrl: string | null) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl },
    });
    const { passwordHash, refreshToken, ...safeUser } = user;
    return safeUser;
  }
}
