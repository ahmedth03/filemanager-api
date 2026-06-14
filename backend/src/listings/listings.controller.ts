import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ListingsService } from './listings.service';
import { ListingFilterDto } from './dto/listing-filter.dto';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { Public } from '../common/decorators/public.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('listings')
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  @Public()
  @Get()
  findAll(@Query() filter: ListingFilterDto, @Request() req: any) {
    const userId = req.user?.id;
    return this.listingsService.findAll(filter, userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('my')
  getMyListings(@CurrentUser() user: any) {
    return this.listingsService.getMyListings(user.id);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string, @Request() req: any) {
    const userId = req.user?.id;
    return this.listingsService.findOne(id, userId);
  }

  @UseGuards(JwtAuthGuard)
  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateListingDto) {
    return this.listingsService.create(user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  update(@Param('id') id: string, @CurrentUser() user: any, @Body() dto: UpdateListingDto) {
    return this.listingsService.update(id, user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Delete(':id')
  delete(@Param('id') id: string, @CurrentUser() user: any) {
    return this.listingsService.delete(id, user.id);
  }
}
