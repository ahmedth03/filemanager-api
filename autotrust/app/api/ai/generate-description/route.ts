import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { generateCarDescription, suggestMarketPrice, generateSeoMeta } from '@/lib/ai';

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const data = await req.json();
  const { action = 'description' } = data;

  if (action === 'price') {
    const result = await suggestMarketPrice(data);
    return NextResponse.json({ success: true, ...result });
  }

  if (action === 'seo') {
    const result = await generateSeoMeta(data);
    return NextResponse.json({ success: true, ...result });
  }

  const description = await generateCarDescription(data);
  return NextResponse.json({ success: true, description });
}
