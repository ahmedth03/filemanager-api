import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary, UploadApiOptions, UploadApiResponse } from 'cloudinary';
import { Readable } from 'stream';

export interface CloudinaryUploadResult {
  url: string;
  publicId: string;
  width?: number;
  height?: number;
  format?: string;
  size?: number;
}

@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);

  constructor(private configService: ConfigService) {
    cloudinary.config({
      cloud_name: this.configService.get<string>('cloudinary.cloudName'),
      api_key: this.configService.get<string>('cloudinary.apiKey'),
      api_secret: this.configService.get<string>('cloudinary.apiSecret'),
    });
  }

  async uploadImage(
    file: Express.Multer.File,
    folder: string,
    options?: Partial<UploadApiOptions>,
  ): Promise<CloudinaryUploadResult> {
    return new Promise((resolve, reject) => {
      const uploadOptions: UploadApiOptions = {
        folder: `harfidar/${folder}`,
        resource_type: 'image',
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        max_bytes: 5 * 1024 * 1024, // 5MB
        transformation: [
          { quality: 'auto:good' },
          { fetch_format: 'auto' },
        ],
        ...options,
      };

      const uploadStream = cloudinary.uploader.upload_stream(
        uploadOptions,
        (error, result) => {
          if (error) {
            this.logger.error('Cloudinary upload error:', error);
            reject(new BadRequestException('Failed to upload image'));
            return;
          }
          resolve({
            url: result.secure_url,
            publicId: result.public_id,
            width: result.width,
            height: result.height,
            format: result.format,
            size: result.bytes,
          });
        },
      );

      const readable = new Readable();
      readable.push(file.buffer);
      readable.push(null);
      readable.pipe(uploadStream);
    });
  }

  async uploadMultipleImages(
    files: Express.Multer.File[],
    folder: string,
  ): Promise<CloudinaryUploadResult[]> {
    const uploadPromises = files.map((file) => this.uploadImage(file, folder));
    return Promise.all(uploadPromises);
  }

  async deleteImage(publicId: string): Promise<void> {
    try {
      await cloudinary.uploader.destroy(publicId);
      this.logger.log(`Deleted image: ${publicId}`);
    } catch (error) {
      this.logger.error(`Failed to delete image ${publicId}:`, error);
    }
  }

  async deleteMultipleImages(publicIds: string[]): Promise<void> {
    if (publicIds.length === 0) return;
    try {
      await cloudinary.api.delete_resources(publicIds);
      this.logger.log(`Deleted ${publicIds.length} images`);
    } catch (error) {
      this.logger.error('Failed to delete images:', error);
    }
  }

  generateThumbnailUrl(publicId: string, width = 300, height = 200): string {
    return cloudinary.url(publicId, {
      width,
      height,
      crop: 'fill',
      quality: 'auto',
      fetch_format: 'auto',
      secure: true,
    });
  }

  generateOptimizedUrl(publicId: string, width?: number): string {
    const transformations: any = {
      quality: 'auto:good',
      fetch_format: 'auto',
      secure: true,
    };
    if (width) {
      transformations.width = width;
      transformations.crop = 'limit';
    }
    return cloudinary.url(publicId, transformations);
  }
}
