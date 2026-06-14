import { IsString, IsOptional, IsArray, IsBoolean } from 'class-validator';

export class CreateRoomDto {
  @IsArray()
  @IsString({ each: true })
  memberIds: string[];

  @IsOptional()
  @IsString()
  listingId?: string;

  @IsOptional()
  @IsBoolean()
  isGroup?: boolean;
}
