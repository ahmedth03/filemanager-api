import { IsString, IsOptional } from 'class-validator';

export class SendMessageDto {
  @IsString()
  content: string;

  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @IsOptional()
  @IsString()
  receiverId?: string;
}
