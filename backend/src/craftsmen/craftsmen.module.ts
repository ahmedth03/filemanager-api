import { Module } from '@nestjs/common';
import { CraftsmenService } from './craftsmen.service';
import { CraftsmenController } from './craftsmen.controller';

@Module({
  providers: [CraftsmenService],
  controllers: [CraftsmenController],
  exports: [CraftsmenService],
})
export class CraftsmenModule {}
