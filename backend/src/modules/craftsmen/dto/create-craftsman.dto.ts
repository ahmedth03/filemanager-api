import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  Matches,
} from 'class-validator';
import { WilayaCode } from '@prisma/client';

export class CreateCraftsmanDto {
  @ApiProperty({ description: 'Specialty ID' })
  @IsString()
  @IsNotEmpty()
  specialtyId: string;

  @ApiPropertyOptional({ description: 'Bio / description' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  bio?: string;

  @ApiProperty({ description: 'Years of experience', minimum: 0, maximum: 50 })
  @IsInt()
  @Min(0)
  @Max(50)
  yearsExperience: number;

  @ApiProperty({ enum: WilayaCode, description: 'Wilaya code (W01-W58)' })
  @IsEnum(WilayaCode)
  wilaya: WilayaCode;

  @ApiProperty({ description: 'City name' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  city: string;

  @ApiPropertyOptional({ description: 'Full address' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  address?: string;

  @ApiPropertyOptional({ description: 'WhatsApp number' })
  @IsOptional()
  @IsString()
  @Matches(/^\+?[1-9]\d{8,14}$/, { message: 'Invalid WhatsApp number' })
  whatsappNumber?: string;

  @ApiPropertyOptional({ description: 'Business phone' })
  @IsOptional()
  @IsString()
  @Matches(/^\+?[1-9]\d{8,14}$/, { message: 'Invalid phone number' })
  businessPhone?: string;

  @ApiPropertyOptional({ description: 'Business name' })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  businessName?: string;

  @ApiPropertyOptional({ description: 'Is currently available for work' })
  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;
}
