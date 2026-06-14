import {
  Injectable,
  UnauthorizedException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../shared/prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponseDto } from './dto/auth-response.dto';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private config: ConfigService,
  ) {}

  async register(dto: RegisterDto, userAgent?: string, ipAddress?: string): Promise<AuthResponseDto> {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already in use');

    if (dto.phone) {
      const phoneExists = await this.prisma.user.findUnique({ where: { phone: dto.phone } });
      if (phoneExists) throw new ConflictException('Phone number already in use');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        firstName: dto.firstName,
        lastName: dto.lastName,
        passwordHash,
        phone: dto.phone,
        role: (dto.role as any) || 'USER',
        status: 'ACTIVE',
      },
    });

    const tokens = await this.generateTokens(user);

    await this.prisma.userSession.create({
      data: {
        userId: user.id,
        refreshToken: tokens.refreshToken,
        deviceInfo: userAgent ? { userAgent } : undefined,
        ipAddress,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    const { passwordHash: _, refreshToken: __, ...safeUser } = user;

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: safeUser.id,
        email: safeUser.email,
        firstName: safeUser.firstName,
        lastName: safeUser.lastName,
        phone: safeUser.phone ?? undefined,
        avatarUrl: safeUser.avatarUrl ?? undefined,
        role: safeUser.role,
        status: safeUser.status,
      },
    };
  }

  async login(dto: LoginDto, userAgent?: string, ipAddress?: string): Promise<AuthResponseDto> {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user) throw new UnauthorizedException('Invalid credentials');

    const passwordMatch = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordMatch) throw new UnauthorizedException('Invalid credentials');

    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedException(`Account is ${user.status.toLowerCase()}`);
    }

    const tokens = await this.generateTokens(user);

    // Upsert session — delete old sessions for this device if any, then create
    await this.prisma.userSession.create({
      data: {
        userId: user.id,
        refreshToken: tokens.refreshToken,
        deviceInfo: userAgent ? { userAgent } : undefined,
        ipAddress,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastSeenAt: new Date() },
    });

    const { passwordHash: _, refreshToken: __, ...safeUser } = user;

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: safeUser.id,
        email: safeUser.email,
        firstName: safeUser.firstName,
        lastName: safeUser.lastName,
        phone: safeUser.phone ?? undefined,
        avatarUrl: safeUser.avatarUrl ?? undefined,
        role: safeUser.role,
        status: safeUser.status,
      },
    };
  }

  async refreshToken(userId: string, refreshToken: string): Promise<AuthResponseDto> {
    const session = await this.prisma.userSession.findUnique({
      where: { refreshToken },
      include: { user: true },
    });

    if (!session || session.userId !== userId) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    if (session.expiresAt < new Date()) {
      await this.prisma.userSession.delete({ where: { id: session.id } });
      throw new UnauthorizedException('Refresh token expired');
    }

    const user = session.user;
    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Account is not active');
    }

    const tokens = await this.generateTokens(user);

    await this.prisma.userSession.update({
      where: { id: session.id },
      data: {
        refreshToken: tokens.refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    const { passwordHash: _, refreshToken: __, ...safeUser } = user;

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      user: {
        id: safeUser.id,
        email: safeUser.email,
        firstName: safeUser.firstName,
        lastName: safeUser.lastName,
        phone: safeUser.phone ?? undefined,
        avatarUrl: safeUser.avatarUrl ?? undefined,
        role: safeUser.role,
        status: safeUser.status,
      },
    };
  }

  async logout(userId: string, refreshToken: string): Promise<void> {
    await this.prisma.userSession.deleteMany({
      where: { userId, refreshToken },
    });
  }

  async generateTokens(user: { id: string; email: string; role: string }) {
    const payload = { sub: user.id, email: user.email, role: user.role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.config.get<string>('jwt.secret'),
        expiresIn: this.config.get<string>('jwt.expiresIn'),
      }),
      this.jwtService.signAsync(payload, {
        secret: this.config.get<string>('jwt.refreshSecret'),
        expiresIn: this.config.get<string>('jwt.refreshExpiresIn'),
      }),
    ]);

    return { accessToken, refreshToken };
  }
}
