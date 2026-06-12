import {
  Controller,
  Post,
  Delete,
  Param,
  Query,
  UploadedFile,
  UploadedFiles,
  UseInterceptors,
  UseGuards,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiQuery,
  ApiParam,
} from '@nestjs/swagger';
import { memoryStorage } from 'multer';
import { UploadService } from './upload.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

const multerMemoryOptions = { storage: memoryStorage() };

@ApiTags('Upload')
@ApiBearerAuth('JWT')
@UseGuards(JwtAuthGuard)
@Controller({ path: 'upload', version: '1' })
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  // ─── Single ───────────────────────────────────────────────────────────────────

  @Post('single')
  @ApiOperation({ summary: 'Upload a single image (JPEG, PNG, WebP, GIF – max 10 MB)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: {
        file: { type: 'string', format: 'binary', description: 'Image file to upload' },
      },
    },
  })
  @ApiQuery({
    name: 'folder',
    required: false,
    description: 'Target Cloudinary sub-folder (default: general)',
    example: 'avatars',
  })
  @UseInterceptors(FileInterceptor('file', multerMemoryOptions))
  uploadSingle(
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 10 * 1024 * 1024 }),
          new FileTypeValidator({ fileType: /^image\/(jpeg|png|webp|gif)$/ }),
        ],
        fileIsRequired: true,
      }),
    )
    file: Express.Multer.File,
    @Query('folder') folder = 'general',
  ) {
    return this.uploadService.uploadSingle(file, folder);
  }

  // ─── Multiple ─────────────────────────────────────────────────────────────────

  @Post('multiple')
  @ApiOperation({ summary: 'Upload multiple images in one request (max 10 files, 10 MB each)' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['files'],
      properties: {
        files: {
          type: 'array',
          items: { type: 'string', format: 'binary' },
          description: 'Image files to upload (max 10)',
        },
      },
    },
  })
  @ApiQuery({
    name: 'folder',
    required: false,
    description: 'Target Cloudinary sub-folder (default: listings)',
    example: 'listings',
  })
  @UseInterceptors(FilesInterceptor('files', 10, multerMemoryOptions))
  uploadMultiple(
    @UploadedFiles() files: Express.Multer.File[],
    @Query('folder') folder = 'listings',
  ) {
    return this.uploadService.uploadMultiple(files, folder);
  }

  // ─── Delete ───────────────────────────────────────────────────────────────────

  @Delete(':publicId')
  @ApiOperation({
    summary: 'Delete an uploaded file by its Cloudinary public ID',
    description:
      'The publicId must be URL-encoded when it contains slashes (e.g. harfidar%2Flistings%2Fxyz).',
  })
  @ApiParam({
    name: 'publicId',
    description: 'URL-encoded Cloudinary public ID of the resource to delete',
    example: 'harfidar%2Flistings%2Fabc123',
  })
  deleteFile(@Param('publicId') publicId: string) {
    return this.uploadService.deleteFile(decodeURIComponent(publicId));
  }
}
