import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
} from '@nestjs/common';
import { ChatService } from './chat.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post('rooms')
  createRoom(@CurrentUser() user: any, @Body() dto: CreateRoomDto) {
    return this.chatService.getOrCreateRoom(user.id, dto);
  }

  @Get('rooms')
  getUserRooms(@CurrentUser() user: any) {
    return this.chatService.getUserRooms(user.id);
  }

  @Get('rooms/:id/messages')
  getRoomMessages(
    @CurrentUser() user: any,
    @Param('id') roomId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    return this.chatService.getRoomMessages(
      roomId,
      user.id,
      parseInt(page, 10),
      parseInt(limit, 10),
    );
  }

  @Post('rooms/:id/messages')
  sendMessage(
    @CurrentUser() user: any,
    @Param('id') roomId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chatService.sendMessage(roomId, user.id, dto);
  }

  @Patch('rooms/:id/read')
  markMessagesRead(@CurrentUser() user: any, @Param('id') roomId: string) {
    return this.chatService.markMessagesRead(roomId, user.id);
  }
}
