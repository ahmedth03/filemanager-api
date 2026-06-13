import { Test, TestingModule } from '@nestjs/testing';
import {
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockPrisma = {
  user: {
    findUnique: jest.fn(),
    findMany: jest.fn(),
    update: jest.fn(),
    count: jest.fn(),
  },
  $transaction: jest.fn(),
};

const mockCloudinary = {
  uploadImage: jest.fn(),
  deleteImage: jest.fn(),
};

const mockUser = {
  id: 'user_1',
  email: 'test@example.com',
  firstName: 'Ahmed',
  lastName: 'Tabich',
  phone: '+213555000111',
  avatarUrl: null,
  role: 'USER',
  status: 'ACTIVE',
  isEmailVerified: true,
  isPhoneVerified: false,
  lastSeenAt: new Date(),
  createdAt: new Date(),
  craftsman: null,
  _count: { listings: 0, reviewsGiven: 0, reviewsReceived: 0 },
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('UsersService', () => {
  let service: UsersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: CloudinaryService, useValue: mockCloudinary },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    jest.clearAllMocks();
  });

  // ─── findAll ───────────────────────────────────────────────────────────────

  describe('findAll', () => {
    it('should return paginated users', async () => {
      mockPrisma.user.findMany.mockResolvedValue([mockUser]);
      mockPrisma.user.count.mockResolvedValue(1);

      const result = await service.findAll({ page: 1, limit: 20 });

      expect(result.data).toHaveLength(1);
      expect(result.meta.total).toBe(1);
      expect(result.meta.page).toBe(1);
      expect(mockPrisma.user.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 0, take: 20 }),
      );
    });

    it('should calculate correct skip for page 2', async () => {
      mockPrisma.user.findMany.mockResolvedValue([]);
      mockPrisma.user.count.mockResolvedValue(0);

      await service.findAll({ page: 2, limit: 10 });

      expect(mockPrisma.user.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 10, take: 10 }),
      );
    });
  });

  // ─── findById ──────────────────────────────────────────────────────────────

  describe('findById', () => {
    it('should return user when found', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findById('user_1');

      expect(result).toEqual(mockUser);
      expect(mockPrisma.user.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'user_1' } }),
      );
    });

    it('should throw NotFoundException for unknown user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });

  // ─── update ────────────────────────────────────────────────────────────────

  describe('update', () => {
    it('should update user profile when requester is the user', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(mockUser) // user exists check
        .mockResolvedValueOnce(null);    // phone uniqueness check
      mockPrisma.user.update.mockResolvedValue({ ...mockUser, firstName: 'Mohamed' });

      const result = await service.update(
        'user_1',
        { firstName: 'Mohamed' },
        'user_1',
        'USER',
      );

      expect(result.firstName).toBe('Mohamed');
      expect(mockPrisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({ where: { id: 'user_1' } }),
      );
    });

    it('should allow admin to update another user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue({ ...mockUser, firstName: 'Updated' });

      const result = await service.update(
        'user_1',
        { firstName: 'Updated' },
        'admin_user',
        'ADMIN',
      );

      expect(result.firstName).toBe('Updated');
    });

    it('should throw ForbiddenException if non-admin tries to update another user', async () => {
      await expect(
        service.update('user_1', { firstName: 'Hacked' }, 'other_user', 'USER'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if user does not exist', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.update('nonexistent', { firstName: 'Test' }, 'nonexistent', 'USER'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ConflictException if phone is already taken', async () => {
      mockPrisma.user.findUnique
        .mockResolvedValueOnce(mockUser) // user exists
        .mockResolvedValueOnce({ id: 'other_user', phone: '+213555999888' }); // phone conflict

      await expect(
        service.update('user_1', { phone: '+213555999888' }, 'user_1', 'USER'),
      ).rejects.toThrow(ConflictException);
    });

    it('should not check phone uniqueness if phone is unchanged', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockPrisma.user.update.mockResolvedValue({ ...mockUser, firstName: 'New Name' });

      // passing the same phone as the existing user — no conflict check needed
      await service.update(
        'user_1',
        { firstName: 'New Name', phone: mockUser.phone },
        'user_1',
        'USER',
      );

      // findUnique called once (user check), NOT a second time for phone uniqueness
      expect(mockPrisma.user.findUnique).toHaveBeenCalledTimes(1);
    });
  });

  // ─── updateAvatar ──────────────────────────────────────────────────────────

  describe('updateAvatar', () => {
    const mockFile = {
      originalname: 'avatar.jpg',
      buffer: Buffer.from(''),
      mimetype: 'image/jpeg',
    } as Express.Multer.File;

    it('should upload image and update avatarUrl', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(mockUser);
      mockCloudinary.uploadImage.mockResolvedValue({ url: 'https://cdn.test/avatar.jpg' });
      mockPrisma.user.update.mockResolvedValue({
        id: 'user_1',
        avatarUrl: 'https://cdn.test/avatar.jpg',
      });

      const result = await service.updateAvatar('user_1', mockFile, 'user_1', 'USER');

      expect(result.avatarUrl).toBe('https://cdn.test/avatar.jpg');
      expect(mockCloudinary.uploadImage).toHaveBeenCalledWith(
        mockFile,
        'avatars',
        expect.any(Object),
      );
    });

    it('should throw ForbiddenException if non-admin updates another user avatar', async () => {
      await expect(
        service.updateAvatar('user_1', mockFile, 'other_user', 'USER'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if user not found', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.updateAvatar('nonexistent', mockFile, 'nonexistent', 'USER'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── updateStatus ──────────────────────────────────────────────────────────

  describe('updateStatus', () => {
    it('should update user status', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ ...mockUser, role: 'USER' });
      mockPrisma.user.update.mockResolvedValue({
        id: 'user_1',
        email: mockUser.email,
        status: 'BANNED',
      });

      const result = await service.updateStatus('user_1', 'BANNED' as any, 'admin_1');

      expect(result.status).toBe('BANNED');
    });

    it('should throw NotFoundException for unknown user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.updateStatus('nonexistent', 'BANNED' as any, 'admin_1'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException when trying to change ADMIN status', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ ...mockUser, role: 'ADMIN' });

      await expect(
        service.updateStatus('admin_user', 'BANNED' as any, 'admin_1'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // ─── getUserStats ──────────────────────────────────────────────────────────

  describe('getUserStats', () => {
    it('should return user counts', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({
        ...mockUser,
        _count: { listings: 3, favorites: 5, reviewsGiven: 2, reviewsReceived: 1 },
      });

      const result = await service.getUserStats('user_1');

      expect(result.listings).toBe(3);
      expect(result.favorites).toBe(5);
      expect(result.reviewsGiven).toBe(2);
      expect(result.reviewsReceived).toBe(1);
    });

    it('should throw NotFoundException for unknown user', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      await expect(service.getUserStats('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });
});
