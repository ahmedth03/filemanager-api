import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, MaxLength } from 'class-validator';

export class SendMessageDto {
  @ApiPropertyOptional({ description: 'Chat room ID (inferred from URL path when omitted)' })
  @IsOptional()
  @IsString()
  roomId?: string;

  @ApiProperty({ description: 'Message content', maxLength: 2000 })
  @IsString()
  @MaxLength(2000)
  content: string;

  @ApiPropertyOptional({ description: 'Optional media attachment URL' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;
}

export class CreateRoomDto {
  @ApiProperty({ description: 'ID of the user to start a conversation with' })
  @IsString()
  recipientId: string;

  @ApiPropertyOptional({ description: 'Optional listing context for the conversation' })
  @IsOptional()
  @IsString()
  listingId?: string;
}
