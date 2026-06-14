import { IsString, IsNumber, IsInt, IsOptional, IsBoolean, IsEnum, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateListingDto {
  @IsString() title: string;
  @IsString() description: string;
  @IsEnum(['APARTMENT', 'HOUSE', 'STUDIO', 'VILLA', 'COMMERCIAL']) type: string;
  @Type(() => Number) @IsNumber() @Min(0) price: number;
  @IsOptional() @IsString() pricePeriod?: string;
  @IsString() wilaya: string;
  @IsString() city: string;
  @IsOptional() @IsString() address?: string;
  @IsOptional() @Type(() => Number) @IsNumber() latitude?: number;
  @IsOptional() @Type(() => Number) @IsNumber() longitude?: number;
  @Type(() => Number) @IsInt() @Min(1) rooms: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) bathrooms?: number;
  @IsOptional() @Type(() => Number) @IsNumber() @Min(0) area?: number;
  @IsOptional() @Type(() => Number) @IsInt() floor?: number;
  @IsOptional() @Type(() => Number) @IsInt() totalFloors?: number;
  @IsOptional() @IsBoolean() hasParking?: boolean;
  @IsOptional() @IsBoolean() hasElevator?: boolean;
  @IsOptional() @IsBoolean() hasBalcony?: boolean;
  @IsOptional() @IsBoolean() isFurnished?: boolean;
}
