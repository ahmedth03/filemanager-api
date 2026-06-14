import { Injectable } from '@nestjs/common';
import { PrismaService } from '../shared/prisma/prisma.service';
import { CreateReportDto } from './dto/create-report.dto';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(reportedById: string, dto: CreateReportDto) {
    return this.prisma.report.create({
      data: {
        reportedById,
        targetId: dto.targetId,
        type: dto.type as any,
        reason: dto.reason,
        description: dto.description,
        reportedUserId: dto.reportedUserId,
        status: 'PENDING',
      },
    });
  }
}
