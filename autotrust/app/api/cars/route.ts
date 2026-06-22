import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { uploadCarImage } from '@/lib/cloudinary';
import { generateSlug } from '@/lib/utils';

export async function GET(req: NextRequest) {
  const sp = req.nextUrl.searchParams;
  const page  = parseInt(sp.get('page') ?? '1');
  const limit = parseInt(sp.get('limit') ?? '12');

  const where = {
    ...(sp.get('status') && { status: sp.get('status') as 'AVAILABLE' }),
    ...(sp.get('make')   && { make: { contains: sp.get('make')!, mode: 'insensitive' as const } }),
    ...(sp.get('condition') && { condition: sp.get('condition') as 'NEW' }),
    ...(sp.get('fuel')   && { fuel: sp.get('fuel') as 'ESSENCE' }),
    ...(sp.get('featured') === 'true' && { featured: true }),
    ...(sp.get('search') && {
      OR: [
        { make:  { contains: sp.get('search')!, mode: 'insensitive' as const } },
        { model: { contains: sp.get('search')!, mode: 'insensitive' as const } },
      ],
    }),
  };

  const [total, data] = await Promise.all([
    prisma.car.count({ where }),
    prisma.car.findMany({
      where,
      include: { images: { orderBy: { order: 'asc' } } },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
  ]);

  return NextResponse.json({ success: true, data, total, page, limit, totalPages: Math.ceil(total / limit) });
}

export async function POST(req: NextRequest) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const formData = await req.formData();
  const imageFiles = formData.getAll('images') as File[];

  const make         = formData.get('make') as string;
  const model        = formData.get('model') as string;
  const year         = parseInt(formData.get('year') as string);
  const baseSlug     = generateSlug(make, model, year);

  // Ensure unique slug
  let slug = baseSlug;
  let counter = 1;
  while (await prisma.car.findUnique({ where: { slug } })) {
    slug = `${baseSlug}-${counter++}`;
  }

  const car = await prisma.car.create({
    data: {
      make,
      model,
      year,
      price:        parseFloat(formData.get('price') as string),
      mileage:      parseInt(formData.get('mileage') as string ?? '0'),
      condition:    (formData.get('condition') as 'NEW') ?? 'NEW',
      fuel:         (formData.get('fuel') as 'ESSENCE') ?? 'ESSENCE',
      transmission: (formData.get('transmission') as 'AUTOMATIQUE') ?? 'AUTOMATIQUE',
      color:        formData.get('color') as string | null,
      doors:        parseInt(formData.get('doors') as string ?? '5'),
      seats:        parseInt(formData.get('seats') as string ?? '5'),
      power:        formData.get('power') ? parseInt(formData.get('power') as string) : null,
      engineSize:   formData.get('engineSize') ? parseFloat(formData.get('engineSize') as string) : null,
      description:  formData.get('description') as string | null,
      featured:     formData.get('featured') === 'true',
      status:       (formData.get('status') as 'AVAILABLE') ?? 'AVAILABLE',
      metaTitle:    formData.get('metaTitle') as string | null,
      metaDesc:     formData.get('metaDesc') as string | null,
      slug,
    },
  });

  // Upload images
  if (imageFiles.length > 0) {
    for (let i = 0; i < imageFiles.length; i++) {
      const file   = imageFiles[i];
      const buffer = Buffer.from(await file.arrayBuffer());
      const result = await uploadCarImage(buffer).catch(() => null);
      if (result) {
        await prisma.carImage.create({
          data: { carId: car.id, url: result.url, thumbnailUrl: result.thumbnailUrl, publicId: result.publicId, isPrimary: i === 0, order: i },
        });
      }
    }
  }

  return NextResponse.json({ success: true, data: car }, { status: 201 });
}
