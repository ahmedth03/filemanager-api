import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import configuration from './config/configuration';
import { PrismaModule } from './shared/prisma/prisma.module';
import { RedisModule } from './shared/redis/redis.module';
import { CloudinaryModule } from './shared/cloudinary/cloudinary.module';
import { EmailModule } from './shared/email/email.module';
import { FirebaseModule } from './shared/firebase/firebase.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CraftsmenModule } from './modules/craftsmen/craftsmen.module';
import { ListingsModule } from './modules/listings/listings.module';
import { ChatModule } from './modules/chat/chat.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { FavoritesModule } from './modules/favorites/favorites.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AdminModule } from './modules/admin/admin.module';
import { UploadModule } from './modules/upload/upload.module';
import { SpecialtiesModule } from './modules/specialties/specialties.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
      envFilePath: ['.env.local', '.env'],
    }),
    ThrottlerModule.forRoot([
      { name: 'short', ttl: 1000, limit: 10 },
      { name: 'medium', ttl: 10000, limit: 50 },
      { name: 'long', ttl: 60000, limit: 200 },
    ]),
    PrismaModule,
    RedisModule,
    CloudinaryModule,
    EmailModule,
    FirebaseModule,
    AuthModule,
    UsersModule,
    CraftsmenModule,
    ListingsModule,
    ChatModule,
    ReviewsModule,
    FavoritesModule,
    NotificationsModule,
    AdminModule,
    UploadModule,
    SpecialtiesModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}
