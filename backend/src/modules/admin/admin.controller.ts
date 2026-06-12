import {
  Controller,
  Get,
  Put,
  Patch,
  Param,
  Query,
  Body,
  UseGuards,
  DefaultValuePipe,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { AccountStatus, ListingStatus, ReportStatus } from '@prisma/client';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

class UpdateUserStatusDto {
  @ApiProperty({ enum: AccountStatus })
  @IsEnum(AccountStatus)
  status: AccountStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  adminNote?: string;
}

class UpdateListingStatusDto {
  @ApiProperty({ enum: ['ACTIVE', 'ARCHIVED', 'DRAFT'] })
  @IsEnum(['ACTIVE', 'ARCHIVED', 'DRAFT'])
  status: ListingStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  adminNote?: string;
}

class ResolveReportDto {
  @ApiProperty({ enum: ReportStatus })
  @IsEnum(ReportStatus)
  status: ReportStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  adminNote?: string;
}

class RejectCraftsmanDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  reason?: string;
}

@ApiTags('Admin')
@ApiBearerAuth('JWT')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@Controller({ path: 'admin', version: '1' })
export class AdminController {
  constructor(private adminService: AdminService) {}

  @Get('dashboard')
  @ApiOperation({ summary: 'Get dashboard statistics' })
  getDashboard() {
    return this.adminService.getDashboardStats();
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get platform-wide statistics' })
  getStats() {
    return this.adminService.getPlatformStats();
  }

  @Get('users')
  @ApiOperation({ summary: 'Get all users with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, enum: AccountStatus })
  @ApiQuery({ name: 'role', required: false })
  @ApiQuery({ name: 'search', required: false })
  getUsers(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
    @Query('role') role?: string,
    @Query('search') search?: string,
  ) {
    return this.adminService.getUsers(page, limit, status, role, search);
  }

  @Patch('users/:id/status')
  @ApiOperation({ summary: 'Update user status (ban/suspend/activate)' })
  updateUserStatus(@Param('id') id: string, @Body() dto: UpdateUserStatusDto) {
    return this.adminService.updateUserStatus(id, dto.status, dto.adminNote);
  }

  @Get('craftsmen')
  @ApiOperation({ summary: 'Get all craftsmen with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false })
  getCraftsmen(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
  ) {
    return this.adminService.getCraftsmen(page, limit, status);
  }

  @Put('craftsmen/:id/verify')
  @ApiOperation({ summary: 'Verify a craftsman profile' })
  verifyCraftsman(@Param('id') id: string) {
    return this.adminService.verifyCraftsman(id);
  }

  @Put('craftsmen/:id/reject')
  @ApiOperation({ summary: 'Reject a craftsman profile' })
  rejectCraftsman(@Param('id') id: string, @Body() dto: RejectCraftsmanDto) {
    return this.adminService.rejectCraftsman(id, dto.reason);
  }

  @Get('listings')
  @ApiOperation({ summary: 'Get all listings with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'wilaya', required: false })
  getListings(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
    @Query('wilaya') wilaya?: string,
  ) {
    return this.adminService.getListings(page, limit, status, wilaya);
  }

  @Patch('listings/:id/status')
  @ApiOperation({ summary: 'Update listing status (approve/archive/draft)' })
  updateListingStatus(@Param('id') id: string, @Body() dto: UpdateListingStatusDto) {
    return this.adminService.updateListingStatus(id, dto.status, dto.adminNote);
  }

  @Get('reports')
  @ApiOperation({ summary: 'Get all reports with pagination and filters' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'status', required: false, enum: ReportStatus })
  getReports(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
    @Query('status') status?: string,
  ) {
    return this.adminService.getReports(page, limit, status);
  }

  @Patch('reports/:id/resolve')
  @ApiOperation({ summary: 'Resolve or dismiss a report' })
  resolveReport(@Param('id') id: string, @Body() dto: ResolveReportDto) {
    return this.adminService.resolveReport(id, dto.status, dto.adminNote);
  }
}
