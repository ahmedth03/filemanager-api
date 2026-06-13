import { Test, TestingModule } from '@nestjs/testing';
import {
  ConflictException,
  UnauthorizedException,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { RedisService } from '../../shared/redis/redis.service';
import { EmailService } from '../../shared/email/email.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  userSession: {
    create: jest.fn(),
    findUnique: jest.fn(),
    update: jest.fn(),
    deleteMany: jest.fn(),
  },
  emailVerification: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
  },
  passwordReset: {
    findUnique: jest.fn(),
    create: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockJwt = {
  signAsync: jest.fn().mockResolvedValue('mock_token'),
};

const mockConfig = {
  get: jest.fn((key: string, defaultVal?: string) => {
    const config: Record<string, string> = {
      'jwt.secret': 'test_secret',
      'jwt.expiresIn': '15m',
      'jwt.refreshSecret': 'test_refresh_secret',
      'jwt.refreshExpiresIn': '7d',
    };
    return config[key] ?? defaultVal;
  }),
};

const mockRedis = {
  get: jest.fn(),
  set: jest.fn(),
  setex: jest.fn(),
  del: jest.fn(),
};

const mockEmail = {
  sendVerificationEmail: jest.fn().mockResolvedValue(undefined),
  sendPasswordResetEmail: jest.fn().mockResolvedValue(undefined),
  sendWelcomeEmail: jest.fn().mockResolvedValue(undefined),
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('AuthService', () => {
  let service: AuthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: JwtService, useValue: mockJwt },
        { provide: ConfigService, useValue: mockConfig },
        { provide: RedisService, useValue: mockRedis },
        { provide: EmailService, useValue: mockEmail },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    jest.clearAllMocks();
  });

  // ─── register ──────────────────────────────────────────────────────────────

  describe('register', () => {
    const dto = {
      email: 'test@example.com',
      firstName: 'Ahmed',
      lastName: 'Tabich',
      password: 'Password@123',
    };

    const createdUser = {
      id: 'user_1',
      email: 'test@example.com',
      firstName: 'Ahmed',
      lastName: 'Tabich',
      role: 'USER',
      status: 'ACTIVE',
      createdAt: new Date(),
    };

    it('should register a new user successfully', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue(createdUser);
      mockPrisma.emailVerification.create.mockResolvedValue({ id: 'ev_1' });
      mockPrisma.userSession.create.mockResolvedValue({ id: 'session_1' });

      const result = await service.register(dto as any);

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe(dto.email);
      expect(result.message).toContain('Registration successful');
    });

    it('should call user.findUnique with lowercased email', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue(createdUser);
      mockPrisma.emailVerification.create.mockResolvedValue({ id: 'ev_1' });
      mockPrisma.userSession.create.mockResolvedValue({});

      await service.register({ ...dto, email: 'TEST@EXAMPLE.COM' } as any);

      expect(mockPrisma.user.findUnique).toHaveBeenCalledWith({
        where: { email: 'test@example.com' },
      });
    });

    it('should throw ConflictException if email already exists', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ email: dto.email });

      await expect(service.register(dto as any)).rejects.toThrow(ConflictException);
    });

    it('should check phone uniqueness when phone is provided', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(null) // email check
        .mockResolvedValueOnce({ phone: '+213555000111' }); // phone check

      await expect(
        service.register({ ...dto, phone: '+213555000111' } as any),
      ).rejects.toThrow(ConflictException);

      expect(mockPrisma.user.findUnique).toHaveBeenCalledTimes(2);
    });

    it('should hash password before storing', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockImplementation((args: any) => {
        expect(args.data.passwordHash).not.toBe(dto.password);
        expect(args.data.passwordHash).toMatch(/^\$2[ayb]\$.{56}$/);
        return Promise.resolve(createdUser);
      });
      mockPrisma.emailVerification.create.mockResolvedValue({});
      mockPrisma.userSession.create.mockResolvedValue({});

      await service.register(dto as any);
    });

    it('should create an emailVerification record', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue(createdUser);
      mockPrisma.emailVerification.create.mockResolvedValue({ id: 'ev_1' });
      mockPrisma.userSession.create.mockResolvedValue({});

      await service.register(dto as any);

      expect(mockPrisma.emailVerification.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ userId: 'user_1' }),
        }),
      );
    });
  });

  // ─── login ─────────────────────────────────────────────────────────────────

  describe('login', () => {
    const hashedPassword = bcrypt.hashSync('Password@123', 12);
    const mockUser = {
      id: 'user_1',
      email: 'test@example.com',
      firstName: 'Ahmed',
      lastName: 'Tabich',
      passwordHash: hashedPassword,
      role: 'USER',
      status: 'ACTIVE',
      avatarUrl: null,
      isEmailVerified: true,
      fcmToken: null,
    };

    it('should login successfully with correct credentials', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue(mockUser);
      mockPrisma.userSession.create.mockResolvedValue({ id: 'session_1' });

      const result = await service.login({
        email: 'test@example.com',
        password: 'Password@123',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('test@example.com');
      expect(result.user).not.toHaveProperty('passwordHash');
    });

    it('should update lastSeenAt on successful login', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue(mockUser);
      mockPrisma.userSession.create.mockResolvedValue({});

      await service.login({ email: 'test@example.com', password: 'Password@123' });

      expect(mockPrisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'user_1' },
          data: expect.objectContaining({ lastSeenAt: expect.any(Date) }),
        }),
      );
    });

    it('should throw UnauthorizedException for non-existent user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.login({ email: 'nouser@example.com', password: 'pass' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for wrong password', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);

      await expect(
        service.login({ email: 'test@example.com', password: 'WrongPass123' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for BANNED user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ ...mockUser, status: 'BANNED' });

      await expect(
        service.login({ email: 'test@example.com', password: 'Password@123' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException for SUSPENDED user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ ...mockUser, status: 'SUSPENDED' });

      await expect(
        service.login({ email: 'test@example.com', password: 'Password@123' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should store fcmToken when provided', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue(mockUser);
      mockPrisma.userSession.create.mockResolvedValue({});

      await service.login({
        email: 'test@example.com',
        password: 'Password@123',
        fcmToken: 'fcm_abc123',
      } as any);

      expect(mockPrisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ fcmToken: 'fcm_abc123' }),
        }),
      );
    });
  });

  // ─── refreshTokens ─────────────────────────────────────────────────────────

  describe('refreshTokens', () => {
    const mockSession = {
      id: 'session_1',
      userId: 'user_1',
      refreshToken: 'valid_refresh_token',
      user: {
        id: 'user_1',
        email: 'test@example.com',
        role: 'USER',
      },
    };

    it('should return new tokens for valid session', async () => {
      mockPrisma.userSession.findUnique.mockResolvedValue(mockSession);
      mockPrisma.userSession.update.mockResolvedValue({});
      mockPrisma.userSession.create.mockResolvedValue({});

      const result = await service.refreshTokens(
        'user_1',
        'session_1',
        'valid_refresh_token',
      );

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
    });

    it('should throw UnauthorizedException when session not found', async () => {
      mockPrisma.userSession.findUnique.mockResolvedValue(null);

      await expect(
        service.refreshTokens('user_1', 'bad_session', 'bad_token'),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException when refresh token mismatch', async () => {
      mockPrisma.userSession.findUnique.mockResolvedValue({
        ...mockSession,
        refreshToken: 'correct_token',
      });

      await expect(
        service.refreshTokens('user_1', 'session_1', 'wrong_token'),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  // ─── logout ────────────────────────────────────────────────────────────────

  describe('logout', () => {
    it('should delete specific session when refreshToken is provided', async () => {
      mockPrisma.userSession.deleteMany.mockResolvedValue({ count: 1 });
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.logout('user_1', 'refresh_token_123');

      expect(mockPrisma.userSession.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user_1', refreshToken: 'refresh_token_123' },
      });
      expect(result).toEqual({ message: 'Logged out successfully' });
    });

    it('should delete all sessions when no refreshToken provided', async () => {
      mockPrisma.userSession.deleteMany.mockResolvedValue({ count: 3 });
      mockRedis.del.mockResolvedValue(undefined);

      const result = await service.logout('user_1');

      expect(mockPrisma.userSession.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user_1' },
      });
      expect(result).toEqual({ message: 'Logged out successfully' });
    });

    it('should invalidate Redis sessions key', async () => {
      mockPrisma.userSession.deleteMany.mockResolvedValue({ count: 1 });
      mockRedis.del.mockResolvedValue(undefined);

      await service.logout('user_1', 'token');

      expect(mockRedis.del).toHaveBeenCalledWith('user:user_1:sessions');
    });
  });

  // ─── verifyEmail ───────────────────────────────────────────────────────────

  describe('verifyEmail', () => {
    it('should verify email with valid unused token', async () => {
      const verification = {
        id: 'ev_1',
        userId: 'user_1',
        token: 'valid_token',
        usedAt: null,
        expiresAt: new Date(Date.now() + 60 * 60 * 1000),
      };
      mockPrisma.emailVerification.findUnique.mockResolvedValue(verification);
      mockPrisma.$transaction.mockResolvedValue([{}, {}]);

      const result = await service.verifyEmail('valid_token');

      expect(result).toEqual({ message: 'Email verified successfully' });
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should throw BadRequestException for invalid token', async () => {
      mockPrisma.emailVerification.findUnique.mockResolvedValue(null);

      await expect(service.verifyEmail('bad_token')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for already-used token', async () => {
      mockPrisma.emailVerification.findUnique.mockResolvedValue({
        id: 'ev_1',
        userId: 'user_1',
        token: 'used_token',
        usedAt: new Date(),
        expiresAt: new Date(Date.now() + 3600_000),
      });

      await expect(service.verifyEmail('used_token')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for expired token', async () => {
      mockPrisma.emailVerification.findUnique.mockResolvedValue({
        id: 'ev_1',
        userId: 'user_1',
        token: 'expired_token',
        usedAt: null,
        expiresAt: new Date(Date.now() - 1000),
      });

      await expect(service.verifyEmail('expired_token')).rejects.toThrow(BadRequestException);
    });
  });

  // ─── forgotPassword ────────────────────────────────────────────────────────

  describe('forgotPassword', () => {
    it('should return generic message even if email does not exist', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      const result = await service.forgotPassword('noone@example.com');

      expect(result.message).toContain('If this email exists');
      expect(mockPrisma.passwordReset.create).not.toHaveBeenCalled();
    });

    it('should invalidate old reset tokens and create new one', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'user_1', email: 'test@example.com' });
      mockPrisma.passwordReset.updateMany.mockResolvedValue({ count: 1 });
      mockPrisma.passwordReset.create.mockResolvedValue({ token: 'new_reset_token' });

      const result = await service.forgotPassword('test@example.com');

      expect(mockPrisma.passwordReset.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user_1', usedAt: null },
        data: { usedAt: expect.any(Date) },
      });
      expect(mockPrisma.passwordReset.create).toHaveBeenCalled();
      expect(result.message).toContain('If this email exists');
    });
  });

  // ─── resetPassword ─────────────────────────────────────────────────────────

  describe('resetPassword', () => {
    it('should reset password with valid token', async () => {
      const resetRecord = {
        id: 'pr_1',
        userId: 'user_1',
        token: 'valid_reset_token',
        usedAt: null,
        expiresAt: new Date(Date.now() + 3600_000),
      };
      mockPrisma.passwordReset.findUnique.mockResolvedValue(resetRecord);
      mockPrisma.$transaction.mockResolvedValue([{}, {}, {}]);

      const result = await service.resetPassword('valid_reset_token', 'NewPassword@123');

      expect(result.message).toContain('Password reset successfully');
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should throw BadRequestException for invalid reset token', async () => {
      mockPrisma.passwordReset.findUnique.mockResolvedValue(null);

      await expect(service.resetPassword('bad_token', 'pass')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for already-used reset token', async () => {
      mockPrisma.passwordReset.findUnique.mockResolvedValue({
        id: 'pr_1',
        userId: 'user_1',
        token: 'used_token',
        usedAt: new Date(),
        expiresAt: new Date(Date.now() + 3600_000),
      });

      await expect(service.resetPassword('used_token', 'pass')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for expired reset token', async () => {
      mockPrisma.passwordReset.findUnique.mockResolvedValue({
        id: 'pr_1',
        userId: 'user_1',
        token: 'expired_token',
        usedAt: null,
        expiresAt: new Date(Date.now() - 1000),
      });

      await expect(service.resetPassword('expired_token', 'pass')).rejects.toThrow(BadRequestException);
    });
  });

  // ─── changePassword ────────────────────────────────────────────────────────

  describe('changePassword', () => {
    const hashedPassword = bcrypt.hashSync('OldPassword@123', 12);

    it('should change password with correct current password', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user_1',
        passwordHash: hashedPassword,
      });
      mockPrisma.user.update.mockResolvedValue({});
      mockPrisma.userSession.deleteMany.mockResolvedValue({ count: 2 });

      const result = await service.changePassword('user_1', 'OldPassword@123', 'NewPassword@456');

      expect(result).toEqual({ message: 'Password changed successfully' });
      expect(mockPrisma.userSession.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user_1' },
      });
    });

    it('should throw NotFoundException if user not found', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.changePassword('nonexistent', 'old', 'new'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if current password is wrong', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'user_1',
        passwordHash: hashedPassword,
      });

      await expect(
        service.changePassword('user_1', 'WrongPassword', 'NewPassword@456'),
      ).rejects.toThrow(BadRequestException);
    });
  });

  // ─── getProfile ────────────────────────────────────────────────────────────

  describe('getProfile', () => {
    it('should return user profile', async () => {
      const profile = {
        id: 'user_1',
        email: 'test@example.com',
        firstName: 'Ahmed',
        craftsman: null,
      };
      mockPrisma.user.findUnique.mockResolvedValue(profile);

      const result = await service.getProfile('user_1');

      expect(result).toEqual(profile);
    });

    it('should throw NotFoundException for unknown user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(service.getProfile('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });
});
