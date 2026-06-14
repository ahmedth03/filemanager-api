import { IsOptional, IsBoolean, IsInt, Min, Max, IsString } from 'class-validator';
import { Transform, Type } from 'class-transformer';

export class CraftsmanFilterDto {
  @IsOptional() @IsString() wilaya?: string;
  @IsOptional() @IsString() specialtyId?: string;
  @IsOptional() @Transform(({ value }) => value === 'true') @IsBoolean() isAvailable?: boolean;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page?: number = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit?: number = 20;
  @IsOptional() @IsString() search?: string;
}
