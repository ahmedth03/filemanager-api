import { IsOptional, IsBoolean, IsInt, Min, Max, IsString, IsNumber } from 'class-validator';
import { Transform, Type } from 'class-transformer';

export class ListingFilterDto {
  @IsOptional() @IsString() wilaya?: string;
  @IsOptional() @IsString() type?: string;
  @IsOptional() @Type(() => Number) @IsNumber() minPrice?: number;
  @IsOptional() @Type(() => Number) @IsNumber() maxPrice?: number;
  @IsOptional() @Type(() => Number) @IsInt() @Min(0) rooms?: number;
  @IsOptional() @IsBoolean() @Transform(({ value }) => value === 'true') isFurnished?: boolean;
  @IsOptional() @IsString() search?: string;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number = 20;
  @IsOptional() @IsString() sortBy?: string;
}
