import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { CloudinaryService } from '../../shared/cloudinary/cloudinary.service';

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB

export interface UploadResult {
  url: string;
  publicId: string;
}

@Injectable()
export class UploadService {
  private readonly logger = new Logger(UploadService.name);

  constructor(private readonly cloudinary: CloudinaryService) {}

  // ─── Single ───────────────────────────────────────────────────────────────────

  async uploadSingle(file: Express.Multer.File, folder: string): Promise<UploadResult> {
    if (!file) throw new BadRequestException('No file provided');
    this.validateFile(file);

    const result = await this.cloudinary.uploadImage(file, folder);
    this.logger.log(`Uploaded single file to ${folder}: ${result.publicId}`);

    return { url: result.url, publicId: result.publicId };
  }

  // ─── Multiple ─────────────────────────────────────────────────────────────────

  async uploadMultiple(files: Express.Multer.File[], folder: string): Promise<UploadResult[]> {
    if (!files || files.length === 0) throw new BadRequestException('No files provided');
    files.forEach((f) => this.validateFile(f));

    const results = await this.cloudinary.uploadMultipleImages(files, folder);
    this.logger.log(`Uploaded ${results.length} files to ${folder}`);

    return results.map((r) => ({ url: r.url, publicId: r.publicId }));
  }

  // ─── Delete ───────────────────────────────────────────────────────────────────

  async deleteFile(publicId: string): Promise<{ message: string }> {
    if (!publicId || publicId.trim() === '') {
      throw new BadRequestException('publicId is required');
    }

    await this.cloudinary.deleteImage(publicId);
    this.logger.log(`Deleted file: ${publicId}`);

    return { message: 'File deleted successfully' };
  }

  // ─── Validation ───────────────────────────────────────────────────────────────

  private validateFile(file: Express.Multer.File): void {
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `File "${file.originalname}" has unsupported type "${file.mimetype}". ` +
          `Allowed types: ${ALLOWED_MIME_TYPES.join(', ')}`,
      );
    }

    if (file.size > MAX_FILE_SIZE_BYTES) {
      const sizeMB = (file.size / (1024 * 1024)).toFixed(1);
      throw new BadRequestException(
        `File "${file.originalname}" is ${sizeMB} MB. Maximum allowed size is 10 MB.`,
      );
    }
  }
}
