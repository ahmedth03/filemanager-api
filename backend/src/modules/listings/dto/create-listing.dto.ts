import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsEnum,
  IsNumber,
  IsBoolean,
  IsOptional,
  Min,
  Max,
  MaxLength,
  IsInt,
} from 'class-validator';
import { WilayaCode, PropertyType, TransactionType } from '@prisma/client';
import { Type } from 'class-transformer';

export class CreateListingDto {
  @ApiProperty({ description: 'Listing title', maxLength: 200 })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiProperty({ description: 'Detailed description of the property', maxLength: 2000 })
  @IsString()
  @MaxLength(2000)
  description: string;

  @ApiProperty({ enum: PropertyType, description: 'Type of property' })
  @IsEnum(PropertyType)
  type: PropertyType;

  @ApiPropertyOptional({ enum: TransactionType, description: 'Transaction type: RENT or SALE', default: 'RENT' })
  @IsOptional()
  @IsEnum(TransactionType)
  transactionType?: TransactionType;

  @ApiProperty({ description: 'Price (DZD)', minimum: 0 })
  @IsNumber()
  @Min(0)
  @Type(() => Number)
  price: number;

  @ApiPropertyOptional({
    description: 'Price period: monthly, weekly, daily, or sale',
    default: 'monthly',
    enum: ['monthly', 'weekly', 'daily', 'sale'],
  })
  @IsOptional()
  @IsString()
  pricePeriod?: string;

  @ApiProperty({ enum: WilayaCode, description: 'Algerian wilaya code (W01–W58)' })
  @IsEnum(WilayaCode)
  wilaya: WilayaCode;

  @ApiProperty({ description: 'City name', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  city: string;

  @ApiPropertyOptional({ description: 'Street address or neighbourhood', maxLength: 300 })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  address?: string;

  @ApiPropertyOptional({ description: 'GPS latitude' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  latitude?: number;

  @ApiPropertyOptional({ description: 'GPS longitude' })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  longitude?: number;

  @ApiProperty({ description: 'Number of rooms', minimum: 1, maximum: 20 })
  @IsInt()
  @Min(1)
  @Max(20)
  @Type(() => Number)
  rooms: number;

  @ApiPropertyOptional({ description: 'Number of bathrooms', default: 1, minimum: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  bathrooms?: number;

  @ApiPropertyOptional({ description: 'Total area in square metres', minimum: 10 })
  @IsOptional()
  @IsNumber()
  @Min(10)
  @Type(() => Number)
  area?: number;

  @ApiPropertyOptional({ description: 'Floor number (0 = ground floor)' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  floor?: number;

  @ApiPropertyOptional({ description: 'Total number of floors in the building' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  totalFloors?: number;

  @ApiPropertyOptional({ description: 'Has private or shared parking space', default: false })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  hasParking?: boolean;

  @ApiPropertyOptional({ description: 'Building has an elevator', default: false })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  hasElevator?: boolean;

  @ApiPropertyOptional({ description: 'Unit has a balcony or terrace', default: false })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  hasBalcony?: boolean;

  @ApiPropertyOptional({ description: 'Property is fully furnished', default: false })
  @IsOptional()
  @IsBoolean()
  @Type(() => Boolean)
  isFurnished?: boolean;
}
