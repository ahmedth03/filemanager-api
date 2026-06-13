import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { Transporter } from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: Transporter;

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('smtp.host'),
      port: this.configService.get<number>('smtp.port'),
      secure: this.configService.get<number>('smtp.port') === 465,
      auth: {
        user: this.configService.get<string>('smtp.user'),
        pass: this.configService.get<string>('smtp.pass'),
      },
    });
  }

  private get from(): string {
    return this.configService.get<string>('smtp.from', 'HarfiDar <noreply@harfidar.dz>');
  }

  private get frontendUrl(): string {
    return this.configService.get<string>('frontendUrl', 'http://localhost:8080');
  }

  async sendVerificationEmail(to: string, firstName: string, token: string): Promise<void> {
    const verificationLink = `${this.frontendUrl}/verify-email?token=${token}`;

    const html = `
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>تأكيد البريد الإلكتروني</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f4f6f9; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; direction: rtl; }
    .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1B4F72, #2980B9); padding: 40px 30px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 1px; }
    .header p { color: #AED6F1; margin: 8px 0 0; font-size: 14px; }
    .body { padding: 40px 30px; }
    .greeting { font-size: 18px; color: #1B4F72; font-weight: 700; margin-bottom: 16px; }
    .text { font-size: 15px; color: #4a4a4a; line-height: 1.8; margin-bottom: 16px; }
    .btn-wrapper { text-align: center; margin: 32px 0; }
    .btn { display: inline-block; background: #F39C12; color: #ffffff !important; text-decoration: none; padding: 14px 36px; border-radius: 8px; font-size: 16px; font-weight: 700; letter-spacing: 0.5px; }
    .divider { border: none; border-top: 1px solid #eaeaea; margin: 30px 0; }
    .link-fallback { font-size: 13px; color: #7f8c8d; word-break: break-all; text-align: center; }
    .footer { background: #f4f6f9; padding: 20px 30px; text-align: center; font-size: 12px; color: #95a5a6; }
    .footer a { color: #1B4F72; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HarfiDar</h1>
      <p>منصة الحرفيين الجزائريين</p>
    </div>
    <div class="body">
      <p class="greeting">مرحباً ${firstName}،</p>
      <p class="text">شكراً لتسجيلك في منصة <strong>HarfiDar</strong>. أنت على بُعد خطوة واحدة من الوصول إلى حسابك.</p>
      <p class="text">يرجى الضغط على الزر أدناه لتأكيد عنوان بريدك الإلكتروني. هذا الرابط صالح لمدة <strong>24 ساعة</strong>.</p>
      <div class="btn-wrapper">
        <a href="${verificationLink}" class="btn">تأكيد البريد الإلكتروني</a>
      </div>
      <hr class="divider" />
      <p class="link-fallback">إذا لم يعمل الزر، انسخ الرابط التالي والصقه في متصفحك:</p>
      <p class="link-fallback"><a href="${verificationLink}" style="color:#1B4F72;">${verificationLink}</a></p>
      <p class="text" style="margin-top:24px;">إذا لم تقم بإنشاء هذا الحساب، يمكنك تجاهل هذا البريد بأمان.</p>
    </div>
    <div class="footer">
      <p>© ${new Date().getFullYear()} HarfiDar — جميع الحقوق محفوظة</p>
      <p><a href="${this.frontendUrl}">harfidar.dz</a></p>
    </div>
  </div>
</body>
</html>
    `.trim();

    const text = [
      `مرحباً ${firstName}،`,
      '',
      'شكراً لتسجيلك في منصة HarfiDar. يرجى تأكيد بريدك الإلكتروني عبر الرابط التالي:',
      '',
      verificationLink,
      '',
      'هذا الرابط صالح لمدة 24 ساعة.',
      '',
      'إذا لم تقم بإنشاء هذا الحساب، يمكنك تجاهل هذا البريد.',
      '',
      '© HarfiDar',
    ].join('\n');

    try {
      await this.transporter.sendMail({
        from: this.from,
        to,
        subject: 'تأكيد بريدك الإلكتروني — HarfiDar',
        html,
        text,
      });
      this.logger.log(`Verification email sent to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send verification email to ${to}`, error);
      throw error;
    }
  }

  async sendPasswordResetEmail(to: string, firstName: string, token: string): Promise<void> {
    const resetLink = `${this.frontendUrl}/reset-password?token=${token}`;

    const html = `
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>إعادة تعيين كلمة المرور</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f4f6f9; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; direction: rtl; }
    .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1B4F72, #2980B9); padding: 40px 30px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 1px; }
    .header p { color: #AED6F1; margin: 8px 0 0; font-size: 14px; }
    .body { padding: 40px 30px; }
    .greeting { font-size: 18px; color: #1B4F72; font-weight: 700; margin-bottom: 16px; }
    .text { font-size: 15px; color: #4a4a4a; line-height: 1.8; margin-bottom: 16px; }
    .warning-box { background: #FEF9E7; border: 1px solid #F39C12; border-radius: 8px; padding: 14px 18px; margin-bottom: 24px; font-size: 13px; color: #7D6608; }
    .btn-wrapper { text-align: center; margin: 32px 0; }
    .btn { display: inline-block; background: #F39C12; color: #ffffff !important; text-decoration: none; padding: 14px 36px; border-radius: 8px; font-size: 16px; font-weight: 700; letter-spacing: 0.5px; }
    .divider { border: none; border-top: 1px solid #eaeaea; margin: 30px 0; }
    .link-fallback { font-size: 13px; color: #7f8c8d; word-break: break-all; text-align: center; }
    .footer { background: #f4f6f9; padding: 20px 30px; text-align: center; font-size: 12px; color: #95a5a6; }
    .footer a { color: #1B4F72; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HarfiDar</h1>
      <p>منصة الحرفيين الجزائريين</p>
    </div>
    <div class="body">
      <p class="greeting">مرحباً ${firstName}،</p>
      <p class="text">تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك على منصة <strong>HarfiDar</strong>.</p>
      <div class="warning-box">
        ⚠️ هذا الرابط صالح لمدة <strong>ساعة واحدة</strong> فقط. إذا لم تطلب هذا، يُرجى تجاهل هذا البريد — حسابك بأمان تام.
      </div>
      <p class="text">اضغط على الزر أدناه لإعادة تعيين كلمة مرورك:</p>
      <div class="btn-wrapper">
        <a href="${resetLink}" class="btn">إعادة تعيين كلمة المرور</a>
      </div>
      <hr class="divider" />
      <p class="link-fallback">إذا لم يعمل الزر، انسخ الرابط التالي والصقه في متصفحك:</p>
      <p class="link-fallback"><a href="${resetLink}" style="color:#1B4F72;">${resetLink}</a></p>
    </div>
    <div class="footer">
      <p>© ${new Date().getFullYear()} HarfiDar — جميع الحقوق محفوظة</p>
      <p><a href="${this.frontendUrl}">harfidar.dz</a></p>
    </div>
  </div>
</body>
</html>
    `.trim();

    const text = [
      `مرحباً ${firstName}،`,
      '',
      'تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك على HarfiDar.',
      '',
      'استخدم الرابط التالي لإعادة تعيين كلمة مرورك (صالح لمدة ساعة واحدة):',
      '',
      resetLink,
      '',
      'إذا لم تطلب هذا، يُرجى تجاهل هذا البريد — حسابك بأمان تام.',
      '',
      '© HarfiDar',
    ].join('\n');

    try {
      await this.transporter.sendMail({
        from: this.from,
        to,
        subject: 'إعادة تعيين كلمة المرور — HarfiDar',
        html,
        text,
      });
      this.logger.log(`Password reset email sent to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send password reset email to ${to}`, error);
      throw error;
    }
  }

  async sendWelcomeEmail(to: string, firstName: string): Promise<void> {
    const html = `
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>مرحباً بك في HarfiDar</title>
  <style>
    body { margin: 0; padding: 0; background-color: #f4f6f9; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; direction: rtl; }
    .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1B4F72, #2980B9); padding: 40px 30px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 1px; }
    .header p { color: #AED6F1; margin: 8px 0 0; font-size: 14px; }
    .hero { background: #F39C12; padding: 24px 30px; text-align: center; }
    .hero h2 { color: #ffffff; margin: 0; font-size: 22px; }
    .body { padding: 40px 30px; }
    .greeting { font-size: 18px; color: #1B4F72; font-weight: 700; margin-bottom: 16px; }
    .text { font-size: 15px; color: #4a4a4a; line-height: 1.8; margin-bottom: 16px; }
    .feature-list { list-style: none; padding: 0; margin: 20px 0; }
    .feature-list li { padding: 10px 0; border-bottom: 1px solid #f0f0f0; font-size: 14px; color: #4a4a4a; }
    .feature-list li:last-child { border-bottom: none; }
    .feature-list li::before { content: "✓ "; color: #F39C12; font-weight: bold; }
    .btn-wrapper { text-align: center; margin: 32px 0; }
    .btn { display: inline-block; background: #1B4F72; color: #ffffff !important; text-decoration: none; padding: 14px 36px; border-radius: 8px; font-size: 16px; font-weight: 700; }
    .footer { background: #f4f6f9; padding: 20px 30px; text-align: center; font-size: 12px; color: #95a5a6; }
    .footer a { color: #1B4F72; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>HarfiDar</h1>
      <p>منصة الحرفيين الجزائريين</p>
    </div>
    <div class="hero">
      <h2>🎉 أهلاً وسهلاً بك!</h2>
    </div>
    <div class="body">
      <p class="greeting">مرحباً ${firstName}،</p>
      <p class="text">يسعدنا انضمامك إلى مجتمع <strong>HarfiDar</strong>! لقد تم التحقق من بريدك الإلكتروني بنجاح وحسابك الآن نشط.</p>
      <p class="text">إليك ما يمكنك فعله الآن:</p>
      <ul class="feature-list">
        <li>تصفح مئات الحرفيين المحترفين في جميع أنحاء الجزائر</li>
        <li>نشر إعلانات العقارات والاستفادة من خدمات الحرفيين</li>
        <li>التواصل المباشر مع الحرفيين عبر المنصة</li>
        <li>تقييم ومشاركة تجاربك مع الآخرين</li>
      </ul>
      <div class="btn-wrapper">
        <a href="${this.frontendUrl}" class="btn">استكشف المنصة</a>
      </div>
    </div>
    <div class="footer">
      <p>© ${new Date().getFullYear()} HarfiDar — جميع الحقوق محفوظة</p>
      <p><a href="${this.frontendUrl}">harfidar.dz</a></p>
    </div>
  </div>
</body>
</html>
    `.trim();

    const text = [
      `مرحباً ${firstName}،`,
      '',
      'أهلاً وسهلاً بك في HarfiDar!',
      '',
      'لقد تم التحقق من بريدك الإلكتروني بنجاح وحسابك الآن نشط.',
      '',
      'يمكنك الآن الدخول إلى المنصة واستكشاف الحرفيين والعقارات:',
      this.frontendUrl,
      '',
      '© HarfiDar',
    ].join('\n');

    try {
      await this.transporter.sendMail({
        from: this.from,
        to,
        subject: 'أهلاً بك في HarfiDar! 🎉',
        html,
        text,
      });
      this.logger.log(`Welcome email sent to ${to}`);
    } catch (error) {
      this.logger.error(`Failed to send welcome email to ${to}`, error);
      // Welcome email failure is non-critical — log and continue
    }
  }
}
