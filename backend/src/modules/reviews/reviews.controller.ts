import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Public } from '../auth/decorators/public.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PaginationDto } from '../../common/dto/pagination.dto';

@ApiTags('Reviews')
@Controller({ path: 'reviews', version: '1' })
export class ReviewsController {
  constructor(private reviewsService: ReviewsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Create a review for a craftsman or listing' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreateReviewDto) {
    return this.reviewsService.create(userId, dto);
  }

  @Public()
  @Get('craftsman/:craftsmanId')
  @ApiOperation({ summary: 'Get all reviews for a craftsman' })
  getCraftsmanReviews(
    @Param('craftsmanId') id: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.reviewsService.getCraftsmanReviews(id, pagination);
  }

  @Public()
  @Get('listing/:listingId')
  @ApiOperation({ summary: 'Get all reviews for a listing' })
  getListingReviews(
    @Param('listingId') id: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.reviewsService.getListingReviews(id, pagination);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Delete my review' })
  delete(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.reviewsService.delete(userId, id);
  }
}
