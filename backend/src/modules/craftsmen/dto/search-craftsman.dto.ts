import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsString,
  IsEnum,
  IsBoolean,
  IsInt,
  Min,
  Max,
} from 'class-validator';
import { WilayaCode } from '@prisma/client';
import { Type } from 'class-transformer';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export class SearchCraftsmanDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'Full-text search across name, bio, business name, city' })
  @IsOptional()
  @IsString()
  query?: string;

  @ApiPropertyOptional({ enum: WilayaCode, description: 'Filter by wilaya' })
  @IsOptional()
  @IsEnum(WilayaCode)
  wilaya?: WilayaCode;

  @ApiPropertyOptional({ description: 'Filter by specialty ID' })
  @IsOptional()
  @IsString()
  specialtyId?: string;

  @ApiPropertyOptional({ description: 'Filter by availability' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  isAvailable?: boolean;

  @ApiPropertyOptional({ description: 'Minimum average rating (0–5)', minimum: 0, maximum: 5, default: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(5)
  @Type(() => Number)
  minRating?: number;

  @ApiPropertyOptional({ description: 'Filter by city name (case-insensitive partial match)' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({
    enum: ['rating', 'reviews', 'experience', 'createdAt'],
    description: 'Field to sort by',
    default: 'createdAt',
  })
  @IsOptional()
  @IsString()
  sortBy?: 'rating' | 'reviews' | 'experience' | 'createdAt';

  @ApiPropertyOptional({ enum: ['asc', 'desc'], description: 'Sort direction', default: 'desc' })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}
