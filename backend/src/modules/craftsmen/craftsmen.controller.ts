import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  UploadedFile,
  UseInterceptors,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
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
import { FileInterceptor } from '@nestjs/platform-express';
import { IsString, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CraftsmenService } from './craftsmen.service';
import { CreateCraftsmanDto } from './dto/create-craftsman.dto';
import { UpdateCraftsmanDto } from './dto/update-craftsman.dto';
import { SearchCraftsmanDto } from './dto/search-craftsman.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Public } from '../auth/decorators/public.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

class AddPortfolioItemDto {
  @ApiProperty({ description: 'Title of the portfolio item', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  title: string;

  @ApiPropertyOptional({ description: 'Optional description of the work', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}

@ApiTags('Craftsmen')
@UseGuards(JwtAuthGuard)
@Controller({ path: 'craftsmen', version: '1' })
export class CraftsmenController {
  constructor(private readonly craftsmenService: CraftsmenService) {}

  // ─── Public endpoints ─────────────────────────────────────────────────────────

  @Public()
  @Get()
  @ApiOperation({
    summary: 'Search craftsmen',
    description: 'Search and filter verified craftsmen with pagination support.',
  })
  @ApiResponse({ status: 200, description: 'Paginated list of craftsmen' })
  search(@Query() dto: SearchCraftsmanDto) {
    return this.craftsmenService.search(dto);
  }

  @Public()
  @Get('featured')
  @ApiOperation({
    summary: 'Get featured craftsmen',
    description: 'Returns top-rated, available craftsmen for the homepage.',
  })
  @ApiQuery({ name: 'limit', required: false, type: Number, description: 'Number of featured craftsmen to return (default 8)' })
  @ApiResponse({ status: 200, description: 'List of featured craftsmen' })
  getFeatured(@Query('limit') limit = 8) {
    return this.craftsmenService.getFeatured(+limit);
  }

  @Public()
  @Get(':id')
  @ApiOperation({
    summary: 'Get craftsman by ID',
    description: 'Returns full profile including portfolio and recent reviews.',
  })
  @ApiParam({ name: 'id', description: 'Craftsman ID' })
  @ApiResponse({ status: 200, description: 'Craftsman profile' })
  @ApiResponse({ status: 404, description: 'Craftsman not found' })
  findOne(@Param('id') id: string) {
    return this.craftsmenService.findById(id);
  }

  // ─── Authenticated endpoints ──────────────────────────────────────────────────

  @Get('user/me')
  @ApiBearerAuth('JWT')
  @ApiOperation({
    summary: 'Get my craftsman profile',
    description: 'Returns the craftsman profile linked to the authenticated user.',
  })
  @ApiResponse({ status: 200, description: 'My craftsman profile' })
  @ApiResponse({ status: 404, description: 'Profile not found' })
  getMyProfile(@CurrentUser('id') userId: string) {
    return this.craftsmenService.findByUserId(userId);
  }

  @Post()
  @ApiBearerAuth('JWT')
  @ApiOperation({
    summary: 'Create craftsman profile',
    description: 'Creates a craftsman profile for the authenticated user and upgrades their role to CRAFTSMAN.',
  })
  @ApiResponse({ status: 201, description: 'Profile created, status set to PENDING for admin review' })
  @ApiResponse({ status: 409, description: 'Profile already exists' })
  create(@CurrentUser('id') userId: string, @Body() dto: CreateCraftsmanDto) {
    return this.craftsmenService.createProfile(userId, dto);
  }

  @Put('profile')
  @ApiBearerAuth('JWT')
  @ApiOperation({
    summary: 'Update my craftsman profile',
    description: 'Update any field of the authenticated craftsman\'s profile.',
  })
  @ApiResponse({ status: 200, description: 'Updated craftsman profile' })
  @ApiResponse({ status: 404, description: 'Profile not found' })
  update(@CurrentUser('id') userId: string, @Body() dto: UpdateCraftsmanDto) {
    return this.craftsmenService.updateProfile(userId, dto);
  }

  @Post('portfolio')
  @ApiBearerAuth('JWT')
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('image'))
  @ApiOperation({
    summary: 'Add portfolio item',
    description: 'Upload an image and add it to the craftsman\'s work portfolio.',
  })
  @ApiResponse({ status: 201, description: 'Portfolio item added' })
  @ApiResponse({ status: 404, description: 'Craftsman profile not found' })
  addPortfolio(
    @CurrentUser('id') userId: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: AddPortfolioItemDto,
  ) {
    return this.craftsmenService.addPortfolioItem(userId, file, dto.title, dto.description);
  }

  @Delete('portfolio/:itemId')
  @ApiBearerAuth('JWT')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete portfolio item',
    description: 'Removes an image from the craftsman\'s portfolio and deletes it from Cloudinary.',
  })
  @ApiParam({ name: 'itemId', description: 'Portfolio item ID' })
  @ApiResponse({ status: 200, description: 'Portfolio item deleted' })
  @ApiResponse({ status: 404, description: 'Portfolio item not found' })
  deletePortfolio(
    @CurrentUser('id') userId: string,
    @Param('itemId') itemId: string,
  ) {
    return this.craftsmenService.deletePortfolioItem(userId, itemId);
  }
}
