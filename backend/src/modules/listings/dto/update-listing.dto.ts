import { PartialType } from '@nestjs/swagger';
import { CreateListingDto } from './create-listing.dto';
import { IsEnum, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { ListingStatus } from '@prisma/client';

export class UpdateListingDto extends PartialType(CreateListingDto) {
  @ApiPropertyOptional({
    enum: ListingStatus,
    description: 'Listing publication status. Only ACTIVE listings appear in public search.',
  })
  @IsOptional()
  @IsEnum(ListingStatus)
  status?: ListingStatus;
}
