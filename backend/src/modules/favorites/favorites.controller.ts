import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FavoritesService } from './favorites.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PaginationDto } from '../../common/dto/pagination.dto';

@ApiTags('Favorites')
@ApiBearerAuth('JWT')
@UseGuards(JwtAuthGuard)
@Controller({ path: 'favorites', version: '1' })
export class FavoritesController {
  constructor(private favoritesService: FavoritesService) {}

  @Get('listings')
  @ApiOperation({ summary: 'Get my favorite listings' })
  getMyFavoriteListings(
    @CurrentUser('id') userId: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.favoritesService.getMyFavoriteListings(userId, pagination);
  }

  @Get('craftsmen')
  @ApiOperation({ summary: 'Get my favorite craftsmen' })
  getMyFavoriteCraftsmen(
    @CurrentUser('id') userId: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.favoritesService.getMyFavoriteCraftsmen(userId, pagination);
  }

  @Get('listings/:listingId/check')
  @ApiOperation({ summary: 'Check if listing is favorited' })
  checkListingFavorite(
    @CurrentUser('id') userId: string,
    @Param('listingId') listingId: string,
  ) {
    return this.favoritesService.checkListingFavorite(userId, listingId);
  }

  @Get('craftsmen/:craftsmanId/check')
  @ApiOperation({ summary: 'Check if craftsman is favorited' })
  checkCraftsmanFavorite(
    @CurrentUser('id') userId: string,
    @Param('craftsmanId') craftsmanId: string,
  ) {
    return this.favoritesService.checkCraftsmanFavorite(userId, craftsmanId);
  }

  @Post('listings/:listingId')
  @ApiOperation({ summary: 'Add listing to favorites' })
  addListing(
    @CurrentUser('id') userId: string,
    @Param('listingId') listingId: string,
  ) {
    return this.favoritesService.addListing(userId, listingId);
  }

  @Delete('listings/:listingId')
  @ApiOperation({ summary: 'Remove listing from favorites' })
  removeListing(
    @CurrentUser('id') userId: string,
    @Param('listingId') listingId: string,
  ) {
    return this.favoritesService.removeListing(userId, listingId);
  }

  @Post('craftsmen/:craftsmanId')
  @ApiOperation({ summary: 'Add craftsman to favorites' })
  addCraftsman(
    @CurrentUser('id') userId: string,
    @Param('craftsmanId') craftsmanId: string,
  ) {
    return this.favoritesService.addCraftsman(userId, craftsmanId);
  }

  @Delete('craftsmen/:craftsmanId')
  @ApiOperation({ summary: 'Remove craftsman from favorites' })
  removeCraftsman(
    @CurrentUser('id') userId: string,
    @Param('craftsmanId') craftsmanId: string,
  ) {
    return this.favoritesService.removeCraftsman(userId, craftsmanId);
  }
}
