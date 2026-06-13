import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
  WsException,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ChatService } from './chat.service';
import { RedisService } from '../../shared/redis/redis.service';

const ONLINE_TTL_SECONDS = 300; // 5 minutes – refreshed on each action
const ONLINE_KEY = (userId: string) => `user:online:${userId}`;

@WebSocketGateway({
  cors: { origin: '*', credentials: true },
  namespace: '/chat',
  transports: ['websocket', 'polling'],
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  /**
   * Maps userId → set of connected socket IDs.
   * A user can be connected from multiple tabs / devices simultaneously.
   */
  private readonly userSockets = new Map<string, Set<string>>();

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly redis: RedisService,
  ) {}

  // ─── Lifecycle ────────────────────────────────────────────────────────────────

  async handleConnection(client: Socket) {
    try {
      const token = this.extractToken(client);
      if (!token) {
        client.disconnect(true);
        return;
      }

      const payload = this.jwtService.verify<{ sub: string; email: string }>(token, {
        secret: this.configService.get<string>('jwt.secret'),
      });

      client.data.userId = payload.sub;
      client.data.userEmail = payload.email;

      // Register socket
      if (!this.userSockets.has(payload.sub)) {
        this.userSockets.set(payload.sub, new Set());
      }
      this.userSockets.get(payload.sub).add(client.id);

      // Mark user as online in Redis (TTL extended on each message)
      await this.redis.set(ONLINE_KEY(payload.sub), '1', ONLINE_TTL_SECONDS);

      // Broadcast online presence
      this.server.emit('user:online', { userId: payload.sub });
      this.logger.log(`Client connected: ${client.id} (user: ${payload.sub})`);
    } catch (err) {
      this.logger.warn(`Connection rejected for ${client.id}: ${(err as Error).message}`);
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket) {
    const userId: string | undefined = client.data?.userId;
    if (!userId) return;

    const sockets = this.userSockets.get(userId);
    if (sockets) {
      sockets.delete(client.id);

      if (sockets.size === 0) {
        // Last socket for this user disconnected
        this.userSockets.delete(userId);
        await this.redis.del(ONLINE_KEY(userId));
        this.server.emit('user:offline', { userId });
        this.logger.log(`User fully disconnected: ${userId}`);
      }
    }
  }

  // ─── Room management ──────────────────────────────────────────────────────────

  @SubscribeMessage('join:room')
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string },
  ) {
    const userId = this.requireAuth(client);

    const isMember = await this.chatService.isRoomMember(userId, data.roomId);
    if (!isMember) throw new WsException('Access denied: you are not a member of this room');

    await client.join(data.roomId);
    this.logger.log(`User ${userId} joined room ${data.roomId}`);
    return { event: 'joined', roomId: data.roomId };
  }

  @SubscribeMessage('leave:room')
  async handleLeaveRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string },
  ) {
    await client.leave(data.roomId);
    return { event: 'left', roomId: data.roomId };
  }

  // ─── Messaging ────────────────────────────────────────────────────────────────

  @SubscribeMessage('send:message')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string; content: string; mediaUrl?: string },
  ) {
    const userId = this.requireAuth(client);

    try {
      const message = await this.chatService.sendMessage(userId, {
        roomId: data.roomId,
        content: data.content,
        mediaUrl: data.mediaUrl,
      });

      // Broadcast to everyone in the room (including sender for multi-device support)
      this.server.to(data.roomId).emit('message:new', message);

      // Refresh online TTL
      await this.redis.set(ONLINE_KEY(userId), '1', ONLINE_TTL_SECONDS);

      return message;
    } catch (err) {
      throw new WsException((err as Error).message ?? 'Failed to send message');
    }
  }

  @SubscribeMessage('mark:read')
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string },
  ) {
    const userId = this.requireAuth(client);

    const result = await this.chatService.markAsRead(userId, data.roomId);

    // Notify all room participants that messages were read
    this.server.to(data.roomId).emit('messages:read', {
      roomId: data.roomId,
      userId,
      updatedCount: result.updatedCount,
    });

    return { success: true, updatedCount: result.updatedCount };
  }

  // ─── Typing indicators ───────────────────────────────────────────────────────

  @SubscribeMessage('typing:start')
  handleTypingStart(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string },
  ) {
    const userId = this.requireAuth(client);
    // Emit to other participants only (not back to sender)
    client.to(data.roomId).emit('user:typing', { userId, roomId: data.roomId });
  }

  @SubscribeMessage('typing:stop')
  handleTypingStop(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { roomId: string },
  ) {
    const userId = this.requireAuth(client);
    client.to(data.roomId).emit('user:stop-typing', { userId, roomId: data.roomId });
  }

  // ─── Public helpers used by other services ───────────────────────────────────

  /**
   * Emit an event directly to a specific user across all their connected sockets.
   */
  async emitToUser(userId: string, event: string, data: unknown): Promise<void> {
    const sockets = this.userSockets.get(userId);
    if (!sockets || sockets.size === 0) return;
    sockets.forEach((socketId) => this.server.to(socketId).emit(event, data));
  }

  /**
   * Check whether a user is currently online (Redis-backed).
   */
  async isUserOnline(userId: string): Promise<boolean> {
    return this.redis.exists(ONLINE_KEY(userId));
  }

  // ─── Private utilities ───────────────────────────────────────────────────────

  private extractToken(client: Socket): string | undefined {
    return (
      client.handshake.auth?.token ||
      (client.handshake.headers?.authorization as string | undefined)?.replace('Bearer ', '')
    );
  }

  private requireAuth(client: Socket): string {
    const userId: string | undefined = client.data?.userId;
    if (!userId) throw new WsException('Unauthorized');
    return userId;
  }
}
