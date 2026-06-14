import { IsOptional, IsString } from 'class-validator';

export class ToggleFavoriteDto {
  @IsOptional()
  @IsString()
  listingId?: string;

  @IsOptional()
  @IsString()
  craftsmanId?: string;
}
