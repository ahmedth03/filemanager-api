import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { sendLeadNotification } from '@/lib/resend';

export async function GET(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const sp     = req.nextUrl.searchParams;
  const status = sp.get('status');

  const leads = await prisma.lead.findMany({
    where: status ? { status: status as 'NEW' } : undefined,
    include: { car: { select: { make: true, model: true, year: true } } },
    orderBy: { createdAt: 'desc' },
  });

  return NextResponse.json({ success: true, data: leads, total: leads.length });
}

export async function POST(req: NextRequest) {
  const contentType = req.headers.get('content-type') ?? '';
  let data: Record<string, string>;

  if (contentType.includes('application/json')) {
    data = await req.json();
  } else {
    const fd = await req.formData();
    data = Object.fromEntries(Array.from(fd.entries()).map(([k, v]) => [k, String(v)]));
  }

  const { name, phone, email, carId, message, source } = data;
  if (!name || !phone) return NextResponse.json({ error: 'Name and phone required' }, { status: 400 });

  const lead = await prisma.lead.create({
    data: {
      name,
      phone,
      email: email || null,
      carId: carId || null,
      message: message || null,
      source: source ?? 'website',
    },
    include: { car: { select: { make: true, model: true, year: true } } },
  });

  // Send email notification (non-blocking)
  sendLeadNotification({
    leadName:  name,
    leadPhone: phone,
    leadEmail: email,
    carName:   lead.car ? `${lead.car.make} ${lead.car.model} ${lead.car.year}` : undefined,
    message,
  }).catch(console.error);

  // If form submission (not JSON), redirect back
  if (!contentType.includes('application/json')) {
    const referer = req.headers.get('referer') ?? '/';
    return NextResponse.redirect(new URL(`${referer}?success=1`, req.url));
  }

  return NextResponse.json({ success: true, data: lead }, { status: 201 });
}
