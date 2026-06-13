import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsString,
  IsEnum,
  IsBoolean,
  IsInt,
  IsNumber,
  Min,
  Max,
} from 'class-validator';
import { WilayaCode, PropertyType, TransactionType } from '@prisma/client';
import { Type } from 'class-transformer';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export class SearchListingDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'Full-text search across title, description, city, address' })
  @IsOptional()
  @IsString()
  query?: string;

  @ApiPropertyOptional({ enum: WilayaCode, description: 'Filter by wilaya' })
  @IsOptional()
  @IsEnum(WilayaCode)
  wilaya?: WilayaCode;

  @ApiPropertyOptional({ enum: PropertyType, description: 'Filter by property type' })
  @IsOptional()
  @IsEnum(PropertyType)
  type?: PropertyType;

  @ApiPropertyOptional({ enum: TransactionType, description: 'Filter by transaction type (RENT or SALE)' })
  @IsOptional()
  @IsEnum(TransactionType)
  transactionType?: TransactionType;

  @ApiPropertyOptional({ description: 'Number of rooms (exact match)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  rooms?: number;

  @ApiPropertyOptional({ description: 'Filter by city name (case-insensitive partial match)' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ description: 'Minimum price in DZD', minimum: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  minPrice?: number;

  @ApiPropertyOptional({ description: 'Maximum price in DZD', minimum: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  maxPrice?: number;

  @ApiPropertyOptional({ description: 'Minimum number of rooms', minimum: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  minRooms?: number;

  @ApiPropertyOptional({ description: 'Maximum number of rooms', maximum: 20 })
  @IsOptional()
  @IsInt()
  @Max(20)
  @Type(() => Number)
  maxRooms?: number;

  @ApiPropertyOptional({ description: 'Filter furnished properties only' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  isFurnished?: boolean;

  @ApiPropertyOptional({ description: 'Filter properties with parking' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  hasParking?: boolean;

  @ApiPropertyOptional({ description: 'Filter properties with elevator' })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  hasElevator?: boolean;

  @ApiPropertyOptional({
    enum: ['price', 'createdAt', 'views', 'rating'],
    description: 'Field to sort results by',
    default: 'createdAt',
  })
  @IsOptional()
  @IsString()
  sortBy?: 'price' | 'createdAt' | 'views' | 'rating';

  @ApiPropertyOptional({ enum: ['asc', 'desc'], description: 'Sort direction', default: 'desc' })
  @IsOptional()
  @IsString()
  sortOrder?: 'asc' | 'desc';
}
