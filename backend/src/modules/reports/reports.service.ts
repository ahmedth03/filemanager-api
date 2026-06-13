import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateReportDto } from './dto/create-report.dto';
import { ReportType } from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(reportedById: string, dto: CreateReportDto) {
    // Prevent self-reporting
    if (dto.reportedUserId && dto.reportedUserId === reportedById) {
      throw new BadRequestException('You cannot report yourself');
    }

    // Validate target exists based on type
    await this.validateTarget(dto.type, dto.targetId);

    // Prevent duplicate reports
    const existing = await this.prisma.report.findFirst({
      where: {
        reportedById,
        targetId: dto.targetId,
        type: dto.type,
      },
    });
    if (existing) {
      throw new BadRequestException('You have already reported this content');
    }

    return this.prisma.report.create({
      data: {
        reportedById,
        reportedUserId: dto.reportedUserId ?? null,
        targetId: dto.targetId,
        type: dto.type,
        reason: dto.reason,
        description: dto.description,
      },
      include: {
        reportedBy: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });
  }

  async getMyReports(userId: string) {
    return this.prisma.report.findMany({
      where: { reportedById: userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        targetId: true,
        type: true,
        reason: true,
        status: true,
        createdAt: true,
        resolvedAt: true,
        adminNote: true,
      },
    });
  }

  private async validateTarget(type: ReportType, targetId: string) {
    switch (type) {
      case ReportType.LISTING: {
        const listing = await this.prisma.propertyListing.findUnique({
          where: { id: targetId },
        });
        if (!listing) throw new NotFoundException('Listing not found');
        break;
      }
      case ReportType.CRAFTSMAN: {
        const craftsman = await this.prisma.craftsman.findUnique({
          where: { id: targetId },
        });
        if (!craftsman) throw new NotFoundException('Craftsman not found');
        break;
      }
      case ReportType.USER: {
        const user = await this.prisma.user.findUnique({
          where: { id: targetId },
        });
        if (!user) throw new NotFoundException('User not found');
        break;
      }
      case ReportType.MESSAGE: {
        const message = await this.prisma.message.findUnique({
          where: { id: targetId },
        });
        if (!message) throw new NotFoundException('Message not found');
        break;
      }
    }
  }
}
