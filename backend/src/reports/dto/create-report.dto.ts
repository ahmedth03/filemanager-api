import { IsString, IsEnum, IsOptional } from 'class-validator';

export class CreateReportDto {
  @IsString()
  targetId: string;

  @IsEnum(['USER', 'LISTING', 'CRAFTSMAN', 'MESSAGE'])
  type: string;

  @IsString()
  reason: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  reportedUserId?: string;
}
