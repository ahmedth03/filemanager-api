import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { MessageStatus } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRoomDto, SendMessageDto } from './dto/send-message.dto';
import { PaginationDto } from '../../common/dto/pagination.dto';

@Injectable()
export class ChatService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  // ─── Rooms ────────────────────────────────────────────────────────────────────

  async createRoom(initiatorId: string, dto: CreateRoomDto) {
    if (initiatorId === dto.recipientId) {
      throw new BadRequestException('Cannot start a conversation with yourself');
    }

    const recipient = await this.prisma.user.findUnique({
      where: { id: dto.recipientId },
      select: { id: true, firstName: true, lastName: true },
    });
    if (!recipient) throw new NotFoundException('Recipient user not found');

    // Validate listing if provided
    if (dto.listingId) {
      const listing = await this.prisma.propertyListing.findUnique({
        where: { id: dto.listingId },
      });
      if (!listing) throw new NotFoundException('Listing not found');
    }

    // Check for existing 1:1 room between these two users (optionally scoped to listing)
    const existingRoom = await this.prisma.chatRoom.findFirst({
      where: {
        ...(dto.listingId ? { listingId: dto.listingId } : { listingId: null }),
        isGroup: false,
        members: {
          every: {
            id: { in: [initiatorId, dto.recipientId] },
          },
        },
      },
      include: {
        members: { select: { id: true, firstName: true, lastName: true, avatarUrl: true } },
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (existingRoom) return existingRoom;

    // Create new room
    const room = await this.prisma.chatRoom.create({
      data: {
        listingId: dto.listingId ?? null,
        isGroup: false,
        members: {
          connect: [{ id: initiatorId }, { id: dto.recipientId }],
        },
      },
      include: {
        members: { select: { id: true, firstName: true, lastName: true, avatarUrl: true } },
        listing: { select: { id: true, title: true } },
      },
    });

    return room;
  }

  async getRooms(userId: string, pagination: PaginationDto) {
    const { page = 1, limit = 20 } = pagination;
    const skip = (page - 1) * limit;

    const [rooms, total] = await this.prisma.$transaction([
      this.prisma.chatRoom.findMany({
        where: { members: { some: { id: userId } } },
        skip,
        take: limit,
        orderBy: { lastMessageAt: { sort: 'desc', nulls: 'last' } },
        include: {
          members: {
            where: { id: { not: userId } },
            select: { id: true, firstName: true, lastName: true, avatarUrl: true, lastSeenAt: true },
          },
          listing: { select: { id: true, title: true } },
          messages: {
            where: { deletedAt: null },
            take: 1,
            orderBy: { createdAt: 'desc' },
            select: {
              id: true,
              content: true,
              senderId: true,
              status: true,
              createdAt: true,
            },
          },
        },
      }),
      this.prisma.chatRoom.count({ where: { members: { some: { id: userId } } } }),
    ]);

    // Attach unread counts per room
    const roomsWithUnread = await Promise.all(
      rooms.map(async (room) => {
        const unreadCount = await this.prisma.message.count({
          where: {
            roomId: room.id,
            receiverId: userId,
            status: { not: MessageStatus.READ },
            deletedAt: null,
          },
        });
        return { ...room, unreadCount };
      }),
    );

    return {
      rooms: roomsWithUnread,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getRoom(userId: string, roomId: string) {
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: userId } } },
      include: {
        members: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true, lastSeenAt: true },
        },
        listing: { select: { id: true, title: true, type: true } },
      },
    });
    if (!room) throw new NotFoundException('Room not found or access denied');
    return room;
  }

  // ─── Messages ─────────────────────────────────────────────────────────────────

  async getRoomMessages(userId: string, roomId: string, pagination: PaginationDto) {
    // Verify membership
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: userId } } },
    });
    if (!room) throw new NotFoundException('Room not found or access denied');

    const { page = 1, limit = 50 } = pagination;
    const skip = (page - 1) * limit;

    const [messages, total] = await this.prisma.$transaction([
      this.prisma.message.findMany({
        where: { roomId, deletedAt: null },
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          sender: {
            select: { id: true, firstName: true, lastName: true, avatarUrl: true },
          },
        },
      }),
      this.prisma.message.count({ where: { roomId, deletedAt: null } }),
    ]);

    // Mark received messages as read
    await this.prisma.message.updateMany({
      where: {
        roomId,
        receiverId: userId,
        status: { not: MessageStatus.READ },
        deletedAt: null,
      },
      data: { status: MessageStatus.READ, readAt: new Date() },
    });

    return {
      messages: messages.reverse(),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async sendMessage(senderId: string, dto: SendMessageDto) {
    // Verify room membership
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: dto.roomId, members: { some: { id: senderId } } },
      include: {
        members: { select: { id: true, firstName: true, lastName: true } },
      },
    });
    if (!room) throw new NotFoundException('Room not found or access denied');

    const recipient = room.members.find((m) => m.id !== senderId);
    if (!recipient) throw new BadRequestException('No recipient found in room');

    const message = await this.prisma.message.create({
      data: {
        roomId: dto.roomId,
        senderId,
        receiverId: recipient.id,
        content: dto.content,
        mediaUrl: dto.mediaUrl ?? null,
        status: MessageStatus.SENT,
      },
      include: {
        sender: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
      },
    });

    // Update room's last message snapshot
    await this.prisma.chatRoom.update({
      where: { id: dto.roomId },
      data: {
        lastMessage: dto.content.length > 100 ? dto.content.slice(0, 97) + '...' : dto.content,
        lastMessageAt: new Date(),
      },
    });

    // Fire-and-forget push notification
    const sender = room.members.find((m) => m.id === senderId);
    const senderName = sender ? `${sender.firstName} ${sender.lastName}` : 'Someone';
    this.notificationsService
      .notifyMessage(recipient.id, senderName, dto.content)
      .catch(() => undefined);

    return message;
  }

  async markAsRead(userId: string, roomId: string) {
    // Verify membership
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: userId } } },
    });
    if (!room) throw new NotFoundException('Room not found or access denied');

    const result = await this.prisma.message.updateMany({
      where: {
        roomId,
        receiverId: userId,
        status: { not: MessageStatus.READ },
        deletedAt: null,
      },
      data: { status: MessageStatus.READ, readAt: new Date() },
    });

    return { updatedCount: result.count };
  }

  async deleteMessage(userId: string, messageId: string) {
    const message = await this.prisma.message.findFirst({
      where: { id: messageId, senderId: userId },
    });
    if (!message) throw new NotFoundException('Message not found or unauthorized');

    // Soft delete
    await this.prisma.message.update({
      where: { id: messageId },
      data: { deletedAt: new Date() },
    });

    return { message: 'Message deleted successfully' };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  async isRoomMember(userId: string, roomId: string): Promise<boolean> {
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: userId } } },
    });
    return !!room;
  }
}
