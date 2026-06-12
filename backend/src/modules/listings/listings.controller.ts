import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  UploadedFiles,
  UseInterceptors,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiResponse,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ListingsService } from './listings.service';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingDto } from './dto/update-listing.dto';
import { SearchListingDto } from './dto/search-listing.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Public } from '../auth/decorators/public.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { PaginationDto } from '../../common/dto/pagination.dto';

@ApiTags('Listings')
@UseGuards(JwtAuthGuard)
@Controller({ path: 'listings', version: '1' })
export class ListingsController {
  constructor(private readonly listingsService: ListingsService) {}

  // ─── Public endpoints ─────────────────────────────────────────────────────────

  @Public()
  @Get()
  @ApiOperation({
    summary: 'Search property listings',
    description: 'Search and filter active listings with pagination. All parameters are optional.',
  })
  @ApiResponse({ status: 200, description: 'Paginated list of listings' })
  search(@Query() dto: SearchListingDto) {
    return this.listingsService.search(dto);
  }

  @Public()
  @Get('featured')
  @ApiOperation({
    summary: 'Get featured listings',
    description: 'Returns the most-viewed, highest-rated active listings for the homepage.',
  })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Max number of results (default 8)' })
  @ApiResponse({ status: 200, description: 'List of featured listings' })
  getFeatured(
    @Query('limit', new DefaultValuePipe(8), ParseIntPipe) limit: number,
  ) {
    return this.listingsService.getFeatured(limit);
  }

  @Public()
  @Get(':id')
  @ApiOperation({
    summary: 'Get listing by ID',
    description: 'Returns full listing details including all images, owner info, and recent reviews. Also increments the view counter.',
  })
  @ApiParam({ name: 'id', description: 'Listing ID' })
  @ApiResponse({ status: 200, description: 'Listing details' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  async findOne(@Param('id') id: string) {
    // Fire-and-forget view increment (don't block the response)
    this.listingsService.incrementViewCount(id).catch(() => undefined);
    return this.listingsService.findById(id);
  }

  // ─── Authenticated endpoints ──────────────────────────────────────────────────

  @Get('user/mine')
  @ApiBearerAuth('JWT')
  @ApiOperation({
    summary: 'Get my listings',
    description: 'Returns all listings created by the authenticated user, including drafts and archived ones.',
  })
  @ApiResponse({ status: 200, description: 'Paginated list of own listings' })
  getMyListings(
    @CurrentUser('id') ownerId: string,
    @Query() pagination: PaginationDto,
  ) {
    return this.listingsService.getMyListings(ownerId, pagination);
  }

  @Post()
  @ApiBearerAuth('JWT')
  @ApiOperation({
    summary: 'Create a new listing',
    description: 'Creates a listing with DRAFT status. Add images and then set status to ACTIVE to publish.',
  })
  @ApiResponse({ status: 201, description: 'Listing created (status: DRAFT)' })
  create(@CurrentUser('id') ownerId: string, @Body() dto: CreateListingDto) {
    return this.listingsService.create(ownerId, dto);
  }

  @Put(':id')
  @ApiBearerAuth('JWT')
  @ApiOperation({
    summary: 'Update a listing',
    description: 'Update any listing field. Only the listing owner can update. Setting status to ACTIVE publishes the listing.',
  })
  @ApiParam({ name: 'id', description: 'Listing ID' })
  @ApiResponse({ status: 200, description: 'Updated listing' })
  @ApiResponse({ status: 403, description: 'Not the listing owner' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  update(
    @CurrentUser('id') ownerId: string,
    @Param('id') id: string,
    @Body() dto: UpdateListingDto,
  ) {
    return this.listingsService.update(ownerId, id, dto);
  }

  @Delete(':id')
  @ApiBearerAuth('JWT')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Archive a listing',
    description: 'Soft-deletes the listing by setting its status to ARCHIVED. The listing is removed from public search.',
  })
  @ApiParam({ name: 'id', description: 'Listing ID' })
  @ApiResponse({ status: 200, description: 'Listing archived' })
  @ApiResponse({ status: 403, description: 'Not the listing owner' })
  @ApiResponse({ status: 404, description: 'Listing not found' })
  delete(@CurrentUser('id') ownerId: string, @Param('id') id: string) {
    return this.listingsService.delete(ownerId, id);
  }

  // ─── Images ───────────────────────────────────────────────────────────────────

  @Post(':id/images')
  @ApiBearerAuth('JWT')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FilesInterceptor('images', 10))
  @ApiOperation({
    summary: 'Upload images for a listing',
    description: 'Upload up to 10 images at once. The first image uploaded becomes the cover if none exists. Max 20 images total per listing.',
  })
  @ApiParam({ name: 'id', description: 'Listing ID' })
  @ApiResponse({ status: 201, description: 'Images uploaded and attached to listing' })
  @ApiResponse({ status: 400, description: 'No files provided or image limit exceeded' })
  @ApiResponse({ status: 403, description: 'Not the listing owner' })
  addImages(
    @CurrentUser('id') ownerId: string,
    @Param('id') id: string,
    @UploadedFiles() files: Express.Multer.File[],
  ) {
    return this.listingsService.addImages(ownerId, id, files);
  }

  @Delete(':id/images/:imageId')
  @ApiBearerAuth('JWT')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Remove a listing image',
    description: 'Deletes the image from Cloudinary and removes it from the listing. If it was the cover, the next image is promoted automatically.',
  })
  @ApiParam({ name: 'id', description: 'Listing ID' })
  @ApiParam({ name: 'imageId', description: 'Image ID to remove' })
  @ApiResponse({ status: 200, description: 'Image removed' })
  @ApiResponse({ status: 403, description: 'Not the listing owner' })
  @ApiResponse({ status: 404, description: 'Image not found' })
  removeImage(
    @CurrentUser('id') ownerId: string,
    @Param('id') _listingId: string,
    @Param('imageId') imageId: string,
  ) {
    return this.listingsService.removeImage(ownerId, imageId);
  }

  @Patch(':id/images/:imageId/cover')
  @ApiBearerAuth('JWT')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Set an image as the listing cover',
    description: 'Designates a specific image as the cover/thumbnail shown in search results.',
  })
  @ApiParam({ name: 'id', description: 'Listing ID' })
  @ApiParam({ name: 'imageId', description: 'Image ID to promote as cover' })
  @ApiResponse({ status: 200, description: 'Cover image updated' })
  @ApiResponse({ status: 403, description: 'Not the listing owner' })
  @ApiResponse({ status: 404, description: 'Image not found' })
  setCover(
    @CurrentUser('id') ownerId: string,
    @Param('id') _listingId: string,
    @Param('imageId') imageId: string,
  ) {
    return this.listingsService.setCoverImage(ownerId, imageId);
  }
}
