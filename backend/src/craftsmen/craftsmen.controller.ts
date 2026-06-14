import { Controller, Get, Param, Query } from '@nestjs/common';
import { CraftsmenService } from './craftsmen.service';
import { CraftsmanFilterDto } from './dto/craftsman-filter.dto';
import { Public } from '../common/decorators/public.decorator';

@Controller('craftsmen')
export class CraftsmenController {
  constructor(private readonly craftsmenService: CraftsmenService) {}

  @Public()
  @Get('specialties')
  getSpecialties() {
    return this.craftsmenService.getSpecialties();
  }

  @Public()
  @Get()
  findAll(@Query() filter: CraftsmanFilterDto) {
    return this.craftsmenService.findAll(filter);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.craftsmenService.findOne(id);
  }
}
