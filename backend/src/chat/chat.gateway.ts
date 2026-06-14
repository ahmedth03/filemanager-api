import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ChatService } from './chat.service';
import { PrismaService } from '../shared/prisma/prisma.service';

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/chat' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  // Map userId -> Set of socketIds (user can have multiple connections)
  private userSockets = new Map<string, Set<string>>();

  constructor(
    private jwtService: JwtService,
    private config: ConfigService,
    private chatService: ChatService,
    private prisma: PrismaService,
  ) {}

  async handleConnection(client: Socket) {
    const token =
      client.handshake.auth?.token ||
      (client.handshake.query?.token as string);
    try {
      const payload = this.jwtService.verify(token, {
        secret: this.config.get<string>('jwt.secret'),
      });
      client.data.userId = payload.sub;

      if (!this.userSockets.has(payload.sub)) {
        this.userSockets.set(payload.sub, new Set());
      }
      this.userSockets.get(payload.sub).add(client.id);

      // Join all user's rooms
      const rooms = await this.chatService.getUserRooms(payload.sub);
      rooms.forEach((room) => client.join(`room:${room.id}`));

      // Update lastSeenAt
      await this.prisma.user.update({
        where: { id: payload.sub },
        data: { lastSeenAt: new Date() },
      });
    } catch {
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    const userId = client.data.userId as string | undefined;
    if (userId) {
      const sockets = this.userSockets.get(userId);
      if (sockets) {
        sockets.delete(client.id);
        if (sockets.size === 0) this.userSockets.delete(userId);
      }
      await this.prisma.user
        .update({ where: { id: userId }, data: { lastSeenAt: new Date() } })
        .catch(() => {});
    }
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; content: string; mediaUrl?: string },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;

    const message = await this.chatService.sendMessage(data.roomId, userId, {
      content: data.content,
      mediaUrl: data.mediaUrl,
    });

    this.server.to(`room:${data.roomId}`).emit('new_message', message);
    return { success: true, message };
  }

  @SubscribeMessage('mark_read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;

    await this.chatService.markMessagesRead(data.roomId, userId);
    this.server
      .to(`room:${data.roomId}`)
      .emit('messages_read', { roomId: data.roomId, userId });
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; isTyping: boolean },
  ) {
    const userId = client.data.userId as string | undefined;
    if (!userId) return;

    client
      .to(`room:${data.roomId}`)
      .emit('user_typing', { userId, isTyping: data.isTyping });
  }

  // Helper: emit to specific user (all their sockets)
  emitToUser(userId: string, event: string, data: any) {
    const sockets = this.userSockets.get(userId);
    if (sockets) {
      sockets.forEach((socketId) =>
        this.server.to(socketId).emit(event, data),
      );
    }
  }
}
