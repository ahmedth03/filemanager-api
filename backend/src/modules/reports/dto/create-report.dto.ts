import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MaxLength, IsUUID } from 'class-validator';
import { ReportType } from '@prisma/client';

export class CreateReportDto {
  @ApiProperty({ description: 'ID of the content being reported' })
  @IsString()
  targetId: string;

  @ApiProperty({ enum: ReportType, description: 'Type of reported content' })
  @IsEnum(ReportType)
  type: ReportType;

  @ApiProperty({
    description: 'Reason for the report',
    example: 'محتوى مضلل',
  })
  @IsString()
  @MaxLength(200)
  reason: string;

  @ApiPropertyOptional({
    description: 'Additional details about the report',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({ description: 'ID of the reported user (if applicable)' })
  @IsOptional()
  @IsString()
  reportedUserId?: string;
}
