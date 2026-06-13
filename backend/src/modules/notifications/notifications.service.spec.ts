import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { FirebaseService } from '../../shared/firebase/firebase.service';
import { NotificationType } from '@prisma/client';

// ─── Mocks ────────────────────────────────────────────────────────────────────

const mockFirebase = {
  sendPushNotification: jest.fn().mockResolvedValue(undefined),
};

const mockPrisma = {
  notification: {
    create: jest.fn(),
    createMany: jest.fn(),
    findMany: jest.fn(),
    findFirst: jest.fn(),
    update: jest.fn(),
    updateMany: jest.fn(),
    delete: jest.fn(),
    deleteMany: jest.fn(),
    count: jest.fn(),
  },
  user: {
    findUnique: jest.fn().mockResolvedValue({ fcmToken: null }),
  },
  $transaction: jest.fn(),
};

// ─── Fixtures ─────────────────────────────────────────────────────────────────

const mockNotification = {
  id: 'notif_1',
  userId: 'user_1',
  type: NotificationType.SYSTEM,
  title: 'Test Notification',
  body: 'This is a test notification body',
  data: {},
  isRead: false,
  readAt: null,
  createdAt: new Date(),
};

const mockReadNotification = {
  ...mockNotification,
  id: 'notif_2',
  isRead: true,
  readAt: new Date(),
};

// ─── Test Suite ───────────────────────────────────────────────────────────────

describe('NotificationsService', () => {
  let service: NotificationsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: FirebaseService, useValue: mockFirebase },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
    jest.clearAllMocks();
  });

  // ─── create ────────────────────────────────────────────────────────────────

  describe('create', () => {
    it('should create a notification successfully', async () => {
      mockPrisma.notification.create.mockResolvedValue(mockNotification);

      const input = {
        userId: 'user_1',
        type: NotificationType.SYSTEM,
        title: 'Test Notification',
        body: 'This is a test notification body',
      };

      const result = await service.create(input);

      expect(result).toEqual(mockNotification);
      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: {
          userId: input.userId,
          type: input.type,
          title: input.title,
          body: input.body,
          data: {},
        },
      });
    });

    it('should create notification with custom data payload', async () => {
      const customData = { orderId: 'order_123', amount: 5000 };
      const notifWithData = { ...mockNotification, data: customData };
      mockPrisma.notification.create.mockResolvedValue(notifWithData);

      const result = await service.create({
        userId: 'user_1',
        type: NotificationType.SYSTEM,
        title: 'Order Update',
        body: 'Your order has been updated',
        data: customData,
      });

      expect(result.data).toEqual(customData);
      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ data: customData }),
      });
    });

    it('should default data to empty object when not provided', async () => {
      mockPrisma.notification.create.mockResolvedValue(mockNotification);

      await service.create({
        userId: 'user_1',
        type: NotificationType.SYSTEM,
        title: 'Test',
        body: 'Body',
      });

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({ data: {} }),
      });
    });
  });

  // ─── createMany ────────────────────────────────────────────────────────────

  describe('createMany', () => {
    it('should create multiple notifications', async () => {
      mockPrisma.notification.createMany.mockResolvedValue({ count: 2 });

      const inputs = [
        { userId: 'user_1', type: NotificationType.MESSAGE, title: 'Msg 1', body: 'Body 1' },
        { userId: 'user_2', type: NotificationType.REVIEW, title: 'Review', body: 'Body 2' },
      ];

      const result = await service.createMany(inputs);

      expect(result).toEqual({ count: 2 });
      expect(mockPrisma.notification.createMany).toHaveBeenCalledWith({
        data: expect.arrayContaining([
          expect.objectContaining({ userId: 'user_1', type: NotificationType.MESSAGE }),
          expect.objectContaining({ userId: 'user_2', type: NotificationType.REVIEW }),
        ]),
      });
    });
  });

  // ─── getMyNotifications ────────────────────────────────────────────────────

  describe('getMyNotifications', () => {
    it('should return paginated notifications with unread count', async () => {
      mockPrisma.$transaction.mockResolvedValue([
        [mockNotification, mockReadNotification],
        2,
        1, // unreadCount
      ]);

      const result = await service.getMyNotifications('user_1', { page: 1, limit: 20 });

      expect(result.notifications).toHaveLength(2);
      expect(result.total).toBe(2);
      expect(result.page).toBe(1);
      expect(result.limit).toBe(20);
      expect(result.totalPages).toBe(1);
      expect(result.unreadCount).toBe(1);
    });

    it('should calculate correct skip for page 2', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0, 0]);

      await service.getMyNotifications('user_1', { page: 2, limit: 10 });

      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });

    it('should compute totalPages correctly', async () => {
      mockPrisma.$transaction.mockResolvedValue([
        new Array(10).fill(mockNotification),
        35,
        5,
      ]);

      const result = await service.getMyNotifications('user_1', { page: 1, limit: 10 });

      expect(result.totalPages).toBe(4);
    });

    it('should return empty result when user has no notifications', async () => {
      mockPrisma.$transaction.mockResolvedValue([[], 0, 0]);

      const result = await service.getMyNotifications('user_1', { page: 1, limit: 20 });

      expect(result.notifications).toHaveLength(0);
      expect(result.total).toBe(0);
      expect(result.unreadCount).toBe(0);
    });
  });

  // ─── markAsRead ────────────────────────────────────────────────────────────

  describe('markAsRead', () => {
    it('should mark a notification as read', async () => {
      mockPrisma.notification.findFirst.mockResolvedValue(mockNotification);
      mockPrisma.notification.update.mockResolvedValue({
        ...mockNotification,
        isRead: true,
        readAt: new Date(),
      });

      const result = await service.markAsRead('user_1', 'notif_1');

      expect(result.isRead).toBe(true);
      expect(mockPrisma.notification.update).toHaveBeenCalledWith({
        where: { id: 'notif_1' },
        data: { isRead: true, readAt: expect.any(Date) },
      });
    });

    it('should throw NotFoundException when notification not found', async () => {
      mockPrisma.notification.findFirst.mockResolvedValue(null);

      await expect(service.markAsRead('user_1', 'nonexistent')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.notification.update).not.toHaveBeenCalled();
    });

    it('should only find notification belonging to the user', async () => {
      mockPrisma.notification.findFirst.mockResolvedValue(null);

      await expect(service.markAsRead('wrong_user', 'notif_1')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.notification.findFirst).toHaveBeenCalledWith({
        where: { id: 'notif_1', userId: 'wrong_user' },
      });
    });
  });

  // ─── markAllAsRead ─────────────────────────────────────────────────────────

  describe('markAllAsRead', () => {
    it('should mark all unread notifications as read', async () => {
      mockPrisma.notification.updateMany.mockResolvedValue({ count: 5 });

      const result = await service.markAllAsRead('user_1');

      expect(result).toEqual(
        expect.objectContaining({ message: expect.stringContaining('5') }),
      );
      expect(mockPrisma.notification.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user_1', isRead: false },
        data: { isRead: true, readAt: expect.any(Date) },
      });
    });

    it('should return count of marked notifications', async () => {
      mockPrisma.notification.updateMany.mockResolvedValue({ count: 3 });

      const result = await service.markAllAsRead('user_1');

      expect(result.count).toBe(3);
    });

    it('should handle case where all notifications are already read', async () => {
      mockPrisma.notification.updateMany.mockResolvedValue({ count: 0 });

      const result = await service.markAllAsRead('user_1');

      expect(result.count).toBe(0);
    });
  });

  // ─── delete ────────────────────────────────────────────────────────────────

  describe('delete', () => {
    it('should delete a notification successfully', async () => {
      mockPrisma.notification.findFirst.mockResolvedValue(mockNotification);
      mockPrisma.notification.delete.mockResolvedValue(mockNotification);

      const result = await service.delete('user_1', 'notif_1');

      expect(result).toEqual({ message: 'Notification deleted successfully' });
      expect(mockPrisma.notification.delete).toHaveBeenCalledWith({
        where: { id: 'notif_1' },
      });
    });

    it('should throw NotFoundException when notification not found', async () => {
      mockPrisma.notification.findFirst.mockResolvedValue(null);

      await expect(service.delete('user_1', 'nonexistent')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.notification.delete).not.toHaveBeenCalled();
    });

    it('should only delete notifications belonging to the user', async () => {
      mockPrisma.notification.findFirst.mockResolvedValue(null);

      await expect(service.delete('wrong_user', 'notif_1')).rejects.toThrow(NotFoundException);
      expect(mockPrisma.notification.findFirst).toHaveBeenCalledWith({
        where: { id: 'notif_1', userId: 'wrong_user' },
      });
    });
  });

  // ─── deleteAll ─────────────────────────────────────────────────────────────

  describe('deleteAll', () => {
    it('should delete all notifications for a user', async () => {
      mockPrisma.notification.deleteMany.mockResolvedValue({ count: 8 });

      const result = await service.deleteAll('user_1');

      expect(result.count).toBe(8);
      expect(mockPrisma.notification.deleteMany).toHaveBeenCalledWith({
        where: { userId: 'user_1' },
      });
    });
  });

  // ─── getUnreadCount ────────────────────────────────────────────────────────

  describe('getUnreadCount', () => {
    it('should return unread notification count', async () => {
      mockPrisma.notification.count.mockResolvedValue(7);

      const result = await service.getUnreadCount('user_1');

      expect(result).toEqual({ count: 7 });
      expect(mockPrisma.notification.count).toHaveBeenCalledWith({
        where: { userId: 'user_1', isRead: false },
      });
    });

    it('should return zero when all notifications are read', async () => {
      mockPrisma.notification.count.mockResolvedValue(0);

      const result = await service.getUnreadCount('user_1');

      expect(result).toEqual({ count: 0 });
    });
  });

  // ─── convenience factory methods ──────────────────────────────────────────

  describe('notifyMessage', () => {
    it('should create a MESSAGE type notification', async () => {
      mockPrisma.notification.create.mockResolvedValue({
        ...mockNotification,
        type: NotificationType.MESSAGE,
      });

      await service.notifyMessage('user_1', 'Karim Benzema', 'Hello there!');

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'user_1',
          type: NotificationType.MESSAGE,
          title: expect.stringContaining('Karim Benzema'),
          body: 'Hello there!',
        }),
      });
    });

    it('should truncate message preview longer than 100 chars', async () => {
      mockPrisma.notification.create.mockResolvedValue(mockNotification);
      const longMessage = 'a'.repeat(150);

      await service.notifyMessage('user_1', 'Sender', longMessage);

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          body: expect.stringMatching(/\.\.\.$/),
        }),
      });
    });

    it('should not truncate preview of 100 chars or fewer', async () => {
      mockPrisma.notification.create.mockResolvedValue(mockNotification);
      const exactMessage = 'a'.repeat(100);

      await service.notifyMessage('user_1', 'Sender', exactMessage);

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          body: exactMessage,
        }),
      });
    });
  });

  describe('notifyReview', () => {
    it('should create a REVIEW type notification', async () => {
      mockPrisma.notification.create.mockResolvedValue({
        ...mockNotification,
        type: NotificationType.REVIEW,
      });

      await service.notifyReview('user_1', 'Ahmed', 'craftsman', 'craft_1', 5);

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'user_1',
          type: NotificationType.REVIEW,
          body: expect.stringContaining('5-star'),
        }),
      });
    });
  });

  describe('notifyListingApproved', () => {
    it('should create a LISTING_APPROVED notification', async () => {
      mockPrisma.notification.create.mockResolvedValue({
        ...mockNotification,
        type: NotificationType.LISTING_APPROVED,
      });

      await service.notifyListingApproved('user_1', 'My Apartment', 'listing_1');

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          type: NotificationType.LISTING_APPROVED,
          body: expect.stringContaining('My Apartment'),
        }),
      });
    });
  });

  describe('notifyListingRejected', () => {
    it('should create a LISTING_REJECTED notification with reason', async () => {
      mockPrisma.notification.create.mockResolvedValue({
        ...mockNotification,
        type: NotificationType.LISTING_REJECTED,
      });

      await service.notifyListingRejected('user_1', 'My Apartment', 'listing_1', 'Duplicate listing');

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          type: NotificationType.LISTING_REJECTED,
          body: expect.stringContaining('Duplicate listing'),
        }),
      });
    });

    it('should create a LISTING_REJECTED notification without reason', async () => {
      mockPrisma.notification.create.mockResolvedValue(mockNotification);

      await service.notifyListingRejected('user_1', 'My Apartment', 'listing_1');

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          type: NotificationType.LISTING_REJECTED,
        }),
      });
    });
  });

  describe('notifyCraftsmanVerified', () => {
    it('should create a CRAFTSMAN_VERIFIED notification', async () => {
      mockPrisma.notification.create.mockResolvedValue({
        ...mockNotification,
        type: NotificationType.CRAFTSMAN_VERIFIED,
      });

      await service.notifyCraftsmanVerified('user_1');

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'user_1',
          type: NotificationType.CRAFTSMAN_VERIFIED,
        }),
      });
    });
  });

  describe('notifySystem', () => {
    it('should create a SYSTEM notification with custom title and body', async () => {
      mockPrisma.notification.create.mockResolvedValue(mockNotification);

      await service.notifySystem('user_1', 'Platform Update', 'New features are available');

      expect(mockPrisma.notification.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'user_1',
          type: NotificationType.SYSTEM,
          title: 'Platform Update',
          body: 'New features are available',
        }),
      });
    });
  });
});
