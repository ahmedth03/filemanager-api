import { Body, Controller, Get, Post } from '@nestjs/common';
import { FavoritesService } from './favorites.service';
import { ToggleFavoriteDto } from './dto/toggle-favorite.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('favorites')
export class FavoritesController {
  constructor(private readonly favoritesService: FavoritesService) {}

  @Post('toggle')
  toggle(@CurrentUser() user: any, @Body() dto: ToggleFavoriteDto) {
    return this.favoritesService.toggle(user.id, dto);
  }

  @Get()
  getUserFavorites(@CurrentUser() user: any) {
    return this.favoritesService.getUserFavorites(user.id);
  }

  @Post('check')
  checkFavorite(@CurrentUser() user: any, @Body() dto: ToggleFavoriteDto) {
    return this.favoritesService.checkFavorite(user.id, dto);
  }
}
