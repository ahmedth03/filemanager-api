import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import configuration from './config/configuration';
import { PrismaModule } from './shared/prisma/prisma.module';
import { RedisModule } from './shared/redis/redis.module';
import { CloudinaryModule } from './shared/cloudinary/cloudinary.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CraftsmenModule } from './craftsmen/craftsmen.module';
import { ListingsModule } from './listings/listings.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { FavoritesModule } from './favorites/favorites.module';
import { ReviewsModule } from './reviews/reviews.module';
import { NotificationsModule } from './notifications/notifications.module';
import { ReportsModule } from './reports/reports.module';
import { ChatModule } from './chat/chat.module';

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
    AuthModule,
    UsersModule,
    CraftsmenModule,
    ListingsModule,
    FavoritesModule,
    ReviewsModule,
    NotificationsModule,
    ReportsModule,
    ChatModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
