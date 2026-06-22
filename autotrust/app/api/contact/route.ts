import { NextRequest, NextResponse } from 'next/server';
import { sendContactEmail } from '@/lib/resend';
import { prisma } from '@/lib/prisma';

// Simple rate limiting via DB (could use Redis in production)
const rateLimitMap = new Map<string, number>();

export async function POST(req: NextRequest) {
  const ip = req.headers.get('x-forwarded-for') ?? 'unknown';
  const now = Date.now();
  const last = rateLimitMap.get(ip) ?? 0;

  if (now - last < 60000) {
    return NextResponse.json({ error: 'Trop de requêtes. Attendez 1 minute.' }, { status: 429 });
  }
  rateLimitMap.set(ip, now);

  const data = await req.json();
  const { name, email, phone, subject, message } = data;

  if (!name || !message || !subject) {
    return NextResponse.json({ error: 'Champs requis manquants' }, { status: 400 });
  }

  // Save as lead
  await prisma.lead.create({
    data: { name, phone: phone ?? 'N/A', email: email ?? null, message: `[${subject}] ${message}`, source: 'contact_form' },
  }).catch(() => {});

  // Send email
  await sendContactEmail({ name, email, subject, message }).catch(console.error);

  return NextResponse.json({ success: true });
}
