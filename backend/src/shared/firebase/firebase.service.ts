import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private initialized = false;

  constructor(private configService: ConfigService) {}

  onModuleInit(): void {
    this.initializeApp();
  }

  private initializeApp(): void {
    try {
      // Avoid re-initializing if an app already exists (e.g. during hot reload)
      if (admin.apps.length > 0) {
        this.initialized = true;
        return;
      }

      const serviceAccountPath = this.configService.get<string>(
        'firebase.serviceAccountPath',
      );

      if (serviceAccountPath) {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        const serviceAccount = require(serviceAccountPath);
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        this.initialized = true;
        this.logger.log('Firebase Admin SDK initialized via service account file');
        return;
      }

      const projectId = this.configService.get<string>('firebase.projectId');
      const clientEmail = this.configService.get<string>('firebase.clientEmail');
      const privateKey = this.configService.get<string>('firebase.privateKey');

      if (projectId && clientEmail && privateKey) {
        admin.initializeApp({
          credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
        });
        this.initialized = true;
        this.logger.log('Firebase Admin SDK initialized via environment variables');
        return;
      }

      this.logger.warn(
        'Firebase is not configured. Push notifications will be disabled. ' +
          'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY ' +
          'or FIREBASE_SERVICE_ACCOUNT_PATH to enable FCM.',
      );
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK', error);
      // Do not rethrow — app should still start without Firebase
    }
  }

  async sendPushNotification(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.initialized) {
      this.logger.debug('Firebase not initialized, skipping push notification');
      return;
    }

    try {
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: { title, body },
        ...(data && { data }),
        android: {
          priority: 'high',
          notification: { sound: 'default' },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      };

      const messageId = await admin.messaging().send(message);
      this.logger.debug(`Push notification sent, messageId: ${messageId}`);
    } catch (error) {
      this.logger.error(
        `Failed to send push notification to token ${fcmToken.slice(0, 10)}...`,
        error,
      );
      // Do not rethrow — notification failure is non-fatal
    }
  }

  async sendMulticast(
    fcmTokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.initialized) {
      this.logger.debug('Firebase not initialized, skipping multicast push notification');
      return;
    }

    if (!fcmTokens.length) {
      return;
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens: fcmTokens,
        notification: { title, body },
        ...(data && { data }),
        android: {
          priority: 'high',
          notification: { sound: 'default' },
        },
        apns: {
          payload: {
            aps: { sound: 'default', badge: 1 },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      this.logger.debug(
        `Multicast sent to ${fcmTokens.length} devices: ` +
          `${response.successCount} succeeded, ${response.failureCount} failed`,
      );

      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            this.logger.warn(
              `FCM delivery failed for token index ${idx}: ${resp.error?.message}`,
            );
          }
        });
      }
    } catch (error) {
      this.logger.error('Failed to send multicast push notification', error);
      // Do not rethrow — notification failure is non-fatal
    }
  }
}
