import { Controller, Get, Post, Put, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { IsString, IsOptional, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SpecialtiesService } from './specialties.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Public } from '../auth/decorators/public.decorator';

class CreateSpecialtyDto {
  @ApiProperty({ description: 'Arabic name' })
  @IsString()
  nameAr: string;

  @ApiProperty({ description: 'French name' })
  @IsString()
  nameFr: string;

  @ApiProperty({ description: 'English name' })
  @IsString()
  nameEn: string;

  @ApiPropertyOptional({ description: 'Icon identifier or URL' })
  @IsOptional()
  @IsString()
  icon?: string;
}

class UpdateSpecialtyDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  nameAr?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  nameFr?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  nameEn?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

@ApiTags('Specialties')
@Controller({ path: 'specialties', version: '1' })
export class SpecialtiesController {
  constructor(private specialtiesService: SpecialtiesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Get all active specialties with craftsman count' })
  findAll() {
    return this.specialtiesService.findAll();
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get a specialty by ID' })
  findOne(@Param('id') id: string) {
    return this.specialtiesService.findById(id);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Create a new specialty (Admin only)' })
  create(@Body() dto: CreateSpecialtyDto) {
    return this.specialtiesService.create(dto);
  }

  @Put(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('ADMIN')
  @ApiBearerAuth('JWT')
  @ApiOperation({ summary: 'Update a specialty (Admin only)' })
  update(@Param('id') id: string, @Body() dto: UpdateSpecialtyDto) {
    return this.specialtiesService.update(id, dto);
  }
}
