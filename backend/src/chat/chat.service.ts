import { Prisma } from '@prisma/client';
import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';


@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  async getOrCreateRoom(userId: string, dto: CreateRoomDto): Promise<any> {
    const isGroup = dto.isGroup ?? false;

    if (!isGroup && dto.memberIds.length === 1) {
      const otherUserId = dto.memberIds[0];

      const existingRoom = await this.prisma.chatRoom.findFirst({
        where: {
          isGroup: false,
          AND: [
            { members: { some: { id: userId } } },
            { members: { some: { id: otherUserId } } },
          ],
        },
        include: {
          members: {
            select: { id: true, firstName: true, lastName: true, avatarUrl: true },
          },
          messages: { take: 1, orderBy: { createdAt: 'desc' } },
        },
      });

      if (existingRoom) return existingRoom;
    }

    const allMemberIds = [userId, ...dto.memberIds];

    const room = await this.prisma.chatRoom.create({
      data: {
        isGroup,
        ...(dto.listingId ? { listingId: dto.listingId } : {}),
        members: {
          connect: allMemberIds.map((id) => ({ id })),
        },
      },
      include: {
        members: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        messages: { take: 1, orderBy: { createdAt: 'desc' } },
      },
    });

    return room;
  }

  async getUserRooms(userId: string): Promise<any[]> {
    return this.prisma.chatRoom.findMany({
      where: { members: { some: { id: userId } } },
      include: {
        members: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
        messages: { take: 1, orderBy: { createdAt: 'desc' } },
      },
      orderBy: { lastMessageAt: 'desc' },
    });
  }

  async getRoomMessages(
    roomId: string,
    userId: string,
    page: number,
    limit: number,
  ) {
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: userId } } },
    });

    if (!room) {
      throw new ForbiddenException('You are not a member of this room');
    }

    const skip = (page - 1) * limit;

    const [messages, total] = await Promise.all([
      this.prisma.message.findMany({
        where: { roomId, deletedAt: null },
        include: {
          sender: {
            select: { id: true, firstName: true, lastName: true, avatarUrl: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.message.count({ where: { roomId, deletedAt: null } }),
    ]);

    return {
      data: messages,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async sendMessage(
    roomId: string,
    senderId: string,
    dto: SendMessageDto,
  ): Promise<any> {
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: senderId } } },
    });

    if (!room) {
      throw new ForbiddenException('You are not a member of this room');
    }

    const message = await this.prisma.message.create({
      data: {
        roomId,
        senderId,
        content: dto.content,
        ...(dto.mediaUrl ? { mediaUrl: dto.mediaUrl } : {}),
        ...(dto.receiverId ? { receiverId: dto.receiverId } : {}),
        status: 'SENT',
      },
      include: {
        sender: {
          select: { id: true, firstName: true, lastName: true, avatarUrl: true },
        },
      },
    });

    await this.prisma.chatRoom.update({
      where: { id: roomId },
      data: {
        lastMessage: dto.content,
        lastMessageAt: new Date(),
      },
    });

    return message;
  }

  async markMessagesRead(roomId: string, userId: string): Promise<void> {
    const room = await this.prisma.chatRoom.findFirst({
      where: { id: roomId, members: { some: { id: userId } } },
    });

    if (!room) {
      throw new ForbiddenException('You are not a member of this room');
    }

    await this.prisma.message.updateMany({
      where: {
        roomId,
        receiverId: userId,
        status: { not: 'READ' },
      },
      data: {
        status: 'READ',
        readAt: new Date(),
      },
    });
  }
}
