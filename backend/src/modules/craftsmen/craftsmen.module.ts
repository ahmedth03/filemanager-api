import { Module } from '@nestjs/common';
import { CraftsmenController } from './craftsmen.controller';
import { CraftsmenService } from './craftsmen.service';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { RedisModule } from '../../shared/redis/redis.module';
import { CloudinaryModule } from '../../shared/cloudinary/cloudinary.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, RedisModule, CloudinaryModule, AuthModule],
  controllers: [CraftsmenController],
  providers: [CraftsmenService],
  exports: [CraftsmenService],
})
export class CraftsmenModule {}
