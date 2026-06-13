import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import configuration from './config/configuration';
import { PrismaModule } from './shared/prisma/prisma.module';
import { RedisModule } from './shared/redis/redis.module';
import { CloudinaryModule } from './shared/cloudinary/cloudinary.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.THROTTLE_TTL, 10) || 60,
        limit: parseInt(process.env.THROTTLE_LIMIT, 10) || 100,
      },
    ]),
    PrismaModule,
    RedisModule,
    CloudinaryModule,
  ],
})
export class AppModule {}
