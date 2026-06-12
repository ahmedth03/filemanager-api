import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, Min, Max, IsString, IsOptional, MaxLength } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateReviewDto {
  @ApiProperty({ minimum: 1, maximum: 5 })
  @IsInt()
  @Min(1)
  @Max(5)
  @Type(() => Number)
  rating: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  comment?: string;

  @ApiPropertyOptional({ description: 'Craftsman ID (if reviewing a craftsman)' })
  @IsOptional()
  @IsString()
  craftsmanId?: string;

  @ApiPropertyOptional({ description: 'Listing ID (if reviewing a property)' })
  @IsOptional()
  @IsString()
  listingId?: string;
}
