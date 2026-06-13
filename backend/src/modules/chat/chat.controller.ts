import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiParam,
} from '@nestjs/swagger';
import { ChatService } from './chat.service';
import { CreateRoomDto, SendMessageDto } from './dto/send-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PaginationDto } from '../../common/dto/pagination.dto';

@ApiTags('Chat')
@ApiBearerAuth('JWT')
@UseGuards(JwtAuthGuard)
@Controller({ path: 'chat', version: '1' })
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  // ─── Rooms ────────────────────────────────────────────────────────────────────

  @Post('rooms')
  @ApiOperation({
    summary: 'Create or retrieve a 1:1 chat room',
    description:
      'Returns an existing room if one already exists between the two users ' +
      '(optionally scoped to a listing), otherwise creates a new one.',
  })
  createRoom(@CurrentUser('id') userId: string, @Body() dto: CreateRoomDto) {
    return this.chatService.createRoom(userId, dto);
  }

  @Get('rooms')
  @ApiOperation({ summary: 'Get all chat rooms I am a member of (paginated)' })
  getRooms(@CurrentUser('id') userId: string, @Query() pagination: PaginationDto) {
    return this.chatService.getRooms(userId, pagination);
  }

  @Get('rooms/:roomId')
  @ApiOperation({ summary: 'Get a single chat room by ID' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  getRoom(@CurrentUser('id') userId: string, @Param('roomId') roomId: string) {
    return this.chatService.getRoom(userId, roomId);
  }

  // ─── Messages ─────────────────────────────────────────────────────────────────

  @Get('rooms/:roomId/messages')
  @ApiOperation({
    summary: 'Get paginated messages in a room',
    description: 'Also marks received messages in this room as READ.',
  })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  getMessages(
    @CurrentUser('id') userId: string,
    @Param('roomId') roomId: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.chatService.getRoomMessages(userId, roomId, pagination);
  }

  @Post('rooms/:roomId/messages')
  @ApiOperation({ summary: 'Send a message to a chat room via HTTP (use WebSocket for real-time)' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  sendMessage(
    @CurrentUser('id') userId: string,
    @Param('roomId') roomId: string,
    @Body() dto: SendMessageDto,
  ) {
    // Ensure roomId from path takes precedence
    return this.chatService.sendMessage(userId, { ...dto, roomId });
  }

  @Post('rooms/:roomId/read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all unread messages in a room as read' })
  @ApiParam({ name: 'roomId', description: 'Chat room ID' })
  markAsRead(@CurrentUser('id') userId: string, @Param('roomId') roomId: string) {
    return this.chatService.markAsRead(userId, roomId);
  }

  // ─── Messages (individual) ────────────────────────────────────────────────────

  @Delete('messages/:messageId')
  @ApiOperation({ summary: 'Soft-delete a message you sent' })
  @ApiParam({ name: 'messageId', description: 'Message ID' })
  deleteMessage(@CurrentUser('id') userId: string, @Param('messageId') messageId: string) {
    return this.chatService.deleteMessage(userId, messageId);
  }
}
