import { Body, Controller, Post } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { CreateReportDto } from './dto/create-report.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateReportDto) {
    return this.reportsService.create(user.id, dto);
  }
}
