import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export interface LeadEmailData {
  leadName: string;
  leadPhone: string;
  leadEmail?: string;
  carName?: string;
  message?: string;
}

export async function sendLeadNotification(data: LeadEmailData) {
  if (!process.env.RESEND_API_KEY) return;

  await resend.emails.send({
    from: process.env.EMAIL_FROM ?? 'AutoTrust <noreply@autotrust.dz>',
    to:   [process.env.NOTIFICATION_EMAIL ?? 'contact@autotrust.dz'],
    subject: `🚗 Nouveau Lead — ${data.leadName}`,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;background:#fff;border:1px solid #eee;border-radius:12px;overflow:hidden">
        <div style="background:#E30613;padding:24px 32px">
          <h1 style="color:#fff;margin:0;font-size:22px">🚗 Nouveau Lead AutoTrust</h1>
        </div>
        <div style="padding:32px">
          <table style="width:100%;border-collapse:collapse">
            <tr><td style="padding:10px 0;color:#666;width:140px"><strong>Nom</strong></td><td style="padding:10px 0">${data.leadName}</td></tr>
            <tr><td style="padding:10px 0;color:#666"><strong>Téléphone</strong></td><td style="padding:10px 0">${data.leadPhone}</td></tr>
            ${data.leadEmail ? `<tr><td style="padding:10px 0;color:#666"><strong>Email</strong></td><td style="padding:10px 0">${data.leadEmail}</td></tr>` : ''}
            ${data.carName ? `<tr><td style="padding:10px 0;color:#666"><strong>Véhicule</strong></td><td style="padding:10px 0">${data.carName}</td></tr>` : ''}
            ${data.message ? `<tr><td style="padding:10px 0;color:#666"><strong>Message</strong></td><td style="padding:10px 0">${data.message}</td></tr>` : ''}
          </table>
          <a href="${process.env.NEXTAUTH_URL}/admin/leads" style="display:inline-block;margin-top:24px;background:#E30613;color:#fff;padding:12px 24px;border-radius:8px;text-decoration:none;font-weight:700">
            Voir dans le Dashboard →
          </a>
        </div>
        <div style="background:#f5f5f5;padding:16px 32px;color:#999;font-size:12px">
          AutoTrust — Drive With Confidence | autotrust.dz
        </div>
      </div>
    `,
  });
}

export async function sendContactEmail(data: { name: string; email: string; subject: string; message: string }) {
  if (!process.env.RESEND_API_KEY) return;

  await resend.emails.send({
    from: process.env.EMAIL_FROM ?? 'AutoTrust <noreply@autotrust.dz>',
    to:   [process.env.NOTIFICATION_EMAIL ?? 'contact@autotrust.dz'],
    replyTo: data.email,
    subject: `📧 Contact: ${data.subject}`,
    html: `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto">
        <h2 style="color:#E30613">Nouveau message de contact</h2>
        <p><strong>De:</strong> ${data.name} (${data.email})</p>
        <p><strong>Sujet:</strong> ${data.subject}</p>
        <hr/>
        <p>${data.message.replace(/\n/g, '<br/>')}</p>
      </div>
    `,
  });
}
