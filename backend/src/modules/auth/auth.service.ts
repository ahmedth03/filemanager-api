import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccountStatus, Role } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';
import { EmailService } from '../../shared/email/email.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly SALT_ROUNDS = 12;

  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
    private configService: ConfigService,
    private redis: RedisService,
    private emailService: EmailService,
  ) {}

  async register(dto: RegisterDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (existingUser) {
      throw new ConflictException('Email already registered');
    }

    if (dto.phone) {
      const existingPhone = await this.prisma.user.findUnique({
        where: { phone: dto.phone },
      });
      if (existingPhone) {
        throw new ConflictException('Phone number already registered');
      }
    }

    const passwordHash = await bcrypt.hash(dto.password, this.SALT_ROUNDS);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash,
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
        role: dto.role || Role.USER,
        status: AccountStatus.ACTIVE,
      },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        createdAt: true,
      },
    });

    // Create email verification token
    const verificationToken = uuidv4();
    await this.prisma.emailVerification.create({
      data: {
        userId: user.id,
        token: verificationToken,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      },
    });

    try {
      await this.emailService.sendVerificationEmail(user.email, user.firstName, verificationToken);
    } catch (e) {
      this.logger.warn(`Email service unavailable; verification email not sent to ${user.email}`);
    }
    this.logger.log(`User registered: ${user.email}`);

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return {
      user,
      ...tokens,
      message: 'Registration successful. Please verify your email.',
    };
  }

  async login(dto: LoginDto, ipAddress?: string, deviceInfo?: any) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    if (user.status === AccountStatus.BANNED) {
      throw new UnauthorizedException('Your account has been banned. Contact support.');
    }

    if (user.status === AccountStatus.SUSPENDED) {
      throw new UnauthorizedException('Your account is suspended. Contact support.');
    }

    // Update last seen and FCM token
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        lastSeenAt: new Date(),
        ...(dto.fcmToken && { fcmToken: dto.fcmToken }),
      },
    });

    const tokens = await this.generateTokens(
      user.id,
      user.email,
      user.role,
      ipAddress,
      deviceInfo,
    );

    const userResponse = {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: user.role,
      status: user.status,
      avatarUrl: user.avatarUrl,
      isEmailVerified: user.isEmailVerified,
    };

    return {
      user: userResponse,
      ...tokens,
    };
  }

  async refreshTokens(userId: string, sessionId: string, oldRefreshToken: string) {
    const session = await this.prisma.userSession.findUnique({
      where: { id: sessionId },
      include: { user: true },
    });

    if (!session || session.refreshToken !== oldRefreshToken) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const user = session.user;

    // Delete old session first to avoid unique constraint violation on refreshToken
    await this.prisma.userSession.delete({ where: { id: sessionId } });

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    return tokens;
  }

  async logout(userId: string, refreshToken?: string) {
    if (refreshToken) {
      await this.prisma.userSession.deleteMany({
        where: { userId, refreshToken },
      });
    } else {
      // Logout from all devices
      await this.prisma.userSession.deleteMany({ where: { userId } });
    }

    // Blacklist the access token in Redis if needed
    await this.redis.del(`user:${userId}:sessions`);

    return { message: 'Logged out successfully' };
  }

  async verifyEmail(token: string) {
    const verification = await this.prisma.emailVerification.findUnique({
      where: { token },
    });

    if (!verification) {
      throw new BadRequestException('Invalid verification token');
    }

    if (verification.usedAt) {
      throw new BadRequestException('Token already used');
    }

    if (new Date() > verification.expiresAt) {
      throw new BadRequestException('Verification token has expired');
    }

    const [verifiedUser] = await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: verification.userId },
        data: { isEmailVerified: true },
        select: { email: true, firstName: true },
      }),
      this.prisma.emailVerification.update({
        where: { id: verification.id },
        data: { usedAt: new Date() },
      }),
    ]);

    // Send welcome email — non-blocking, failure is swallowed inside sendWelcomeEmail
    this.emailService
      .sendWelcomeEmail(verifiedUser.email, verifiedUser.firstName)
      .catch((err) => this.logger.error('Welcome email error', err));

    return { message: 'Email verified successfully' };
  }

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
    });

    // Always return success to prevent email enumeration
    if (!user) {
      return { message: 'If this email exists, a reset link has been sent' };
    }

    // Invalidate existing reset tokens
    await this.prisma.passwordReset.updateMany({
      where: { userId: user.id, usedAt: null },
      data: { usedAt: new Date() },
    });

    const resetToken = uuidv4();
    await this.prisma.passwordReset.create({
      data: {
        userId: user.id,
        token: resetToken,
        expiresAt: new Date(Date.now() + 60 * 60 * 1000), // 1 hour
      },
    });

    try {
      await this.emailService.sendPasswordResetEmail(user.email, user.firstName, resetToken);
      this.logger.log(`Password reset email sent to ${email}`);
    } catch (e) {
      this.logger.warn(`Email service unavailable; password reset email not sent to ${email}`);
    }

    return { message: 'If this email exists, a reset link has been sent' };
  }

  async resetPassword(token: string, newPassword: string) {
    const resetRecord = await this.prisma.passwordReset.findUnique({
      where: { token },
    });

    if (!resetRecord) {
      throw new BadRequestException('Invalid reset token');
    }

    if (resetRecord.usedAt) {
      throw new BadRequestException('Reset token already used');
    }

    if (new Date() > resetRecord.expiresAt) {
      throw new BadRequestException('Reset token has expired');
    }

    const passwordHash = await bcrypt.hash(newPassword, this.SALT_ROUNDS);

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: resetRecord.userId },
        data: { passwordHash },
      }),
      this.prisma.passwordReset.update({
        where: { id: resetRecord.id },
        data: { usedAt: new Date() },
      }),
      // Invalidate all sessions
      this.prisma.userSession.deleteMany({
        where: { userId: resetRecord.userId },
      }),
    ]);

    return { message: 'Password reset successfully. Please login with your new password.' };
  }

  async changePassword(userId: string, currentPassword: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) {
      throw new BadRequestException('Current password is incorrect');
    }

    const passwordHash = await bcrypt.hash(newPassword, this.SALT_ROUNDS);

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });

    // Invalidate all other sessions
    await this.prisma.userSession.deleteMany({ where: { userId } });

    return { message: 'Password changed successfully' };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
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
          },
        },
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private async generateTokens(
    userId: string,
    email: string,
    role: string,
    ipAddress?: string,
    deviceInfo?: any,
  ) {
    const payload = { sub: userId, email, role };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('jwt.secret'),
        expiresIn: this.configService.get<string>('jwt.expiresIn', '15m'),
      }),
      this.jwtService.signAsync(payload, {
        secret: this.configService.get<string>('jwt.refreshSecret'),
        expiresIn: this.configService.get<string>('jwt.refreshExpiresIn', '7d'),
      }),
    ]);

    // Store refresh token as a session
    await this.prisma.userSession.create({
      data: {
        userId,
        refreshToken,
        ipAddress,
        deviceInfo,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      },
    });

    return { accessToken, refreshToken };
  }
}
