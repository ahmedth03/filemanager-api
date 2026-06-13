import { Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { FirebaseService } from '../../shared/firebase/firebase.service';
import { PaginationDto } from '../../common/dto/pagination.dto';

export interface CreateNotificationInput {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private firebaseService: FirebaseService,
  ) {}

  async create(input: CreateNotificationInput) {
    const notification = await this.prisma.notification.create({
      data: {
        userId: input.userId,
        type: input.type,
        title: input.title,
        body: input.body,
        data: (input.data ?? {}) as Prisma.InputJsonValue,
      },
    });

    // Fire-and-forget push notification — failure is handled inside pushToUser
    this.pushToUser(input.userId, input.title, input.body).catch(() => {
      // Already logged inside pushToUser
    });

    return notification;
  }

  private async pushToUser(
    userId: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });
    if (user?.fcmToken) {
      await this.firebaseService.sendPushNotification(user.fcmToken, title, body, data);
    }
  }

  async createMany(inputs: CreateNotificationInput[]) {
    return this.prisma.notification.createMany({
      data: inputs.map((input) => ({
        userId: input.userId,
        type: input.type,
        title: input.title,
        body: input.body,
        data: (input.data ?? {}) as Prisma.InputJsonValue,
      })),
    });
  }

  async getMyNotifications(userId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [notifications, total, unreadCount] = await this.prisma.$transaction([
      this.prisma.notification.findMany({
        where: { userId },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.notification.count({ where: { userId } }),
      this.prisma.notification.count({ where: { userId, isRead: false } }),
    ]);

    return {
      notifications,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
      unreadCount,
    };
  }

  async markAsRead(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });
    if (!notification) throw new NotFoundException('Notification not found');

    return this.prisma.notification.update({
      where: { id: notificationId },
      data: { isRead: true, readAt: new Date() },
    });
  }

  async markAllAsRead(userId: string) {
    const result = await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true, readAt: new Date() },
    });
    return { message: `Marked ${result.count} notifications as read`, count: result.count };
  }

  async delete(userId: string, notificationId: string) {
    const notification = await this.prisma.notification.findFirst({
      where: { id: notificationId, userId },
    });
    if (!notification) throw new NotFoundException('Notification not found');

    await this.prisma.notification.delete({ where: { id: notificationId } });
    return { message: 'Notification deleted successfully' };
  }

  async deleteAll(userId: string) {
    const result = await this.prisma.notification.deleteMany({ where: { userId } });
    return { message: `Deleted ${result.count} notifications`, count: result.count };
  }

  async getUnreadCount(userId: string): Promise<{ count: number }> {
    const count = await this.prisma.notification.count({
      where: { userId, isRead: false },
    });
    return { count };
  }

  // Convenience factory methods used by other services

  async notifyMessage(recipientId: string, senderName: string, preview: string) {
    return this.create({
      userId: recipientId,
      type: NotificationType.MESSAGE,
      title: `New message from ${senderName}`,
      body: preview.length > 100 ? preview.slice(0, 97) + '...' : preview,
      data: { senderName },
    });
  }

  async notifyReview(
    recipientId: string,
    reviewerName: string,
    targetType: 'craftsman' | 'listing',
    targetId: string,
    rating: number,
  ) {
    return this.create({
      userId: recipientId,
      type: NotificationType.REVIEW,
      title: `New review from ${reviewerName}`,
      body: `You received a ${rating}-star review on your ${targetType}`,
      data: { reviewerName, targetType, targetId, rating },
    });
  }

  async notifyListingApproved(ownerId: string, listingTitle: string, listingId: string) {
    return this.create({
      userId: ownerId,
      type: NotificationType.LISTING_APPROVED,
      title: 'Listing approved',
      body: `Your listing "${listingTitle}" has been approved and is now live`,
      data: { listingId, listingTitle },
    });
  }

  async notifyListingRejected(
    ownerId: string,
    listingTitle: string,
    listingId: string,
    reason?: string,
  ) {
    return this.create({
      userId: ownerId,
      type: NotificationType.LISTING_REJECTED,
      title: 'Listing rejected',
      body: reason
        ? `Your listing "${listingTitle}" was rejected: ${reason}`
        : `Your listing "${listingTitle}" was rejected. Please review and resubmit.`,
      data: { listingId, listingTitle, reason },
    });
  }

  async notifyCraftsmanVerified(userId: string) {
    return this.create({
      userId,
      type: NotificationType.CRAFTSMAN_VERIFIED,
      title: 'Profile verified',
      body: 'Congratulations! Your craftsman profile has been verified.',
      data: {},
    });
  }

  async notifyReportResolved(
    reportedById: string,
    reportId: string,
    status: string,
    adminNote?: string,
  ) {
    return this.create({
      userId: reportedById,
      type: NotificationType.REPORT_RESOLVED,
      title: 'Your report has been resolved',
      body: adminNote
        ? `Your report was ${status.toLowerCase()}: ${adminNote}`
        : `Your report has been ${status.toLowerCase()} by our team.`,
      data: { reportId, status, adminNote },
    });
  }

  async notifySystem(userId: string, title: string, body: string, data?: Record<string, unknown>) {
    return this.create({
      userId,
      type: NotificationType.SYSTEM,
      title,
      body,
      data,
    });
  }
}
