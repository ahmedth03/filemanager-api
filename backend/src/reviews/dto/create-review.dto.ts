import { IsInt, Min, Max, IsOptional, IsString } from 'class-validator';

export class CreateReviewDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating: number;

  @IsOptional()
  @IsString()
  comment?: string;

  @IsOptional()
  @IsString()
  craftsmanId?: string;

  @IsOptional()
  @IsString()
  listingId?: string;

  @IsOptional()
  @IsString()
  revieweeId?: string;
}
