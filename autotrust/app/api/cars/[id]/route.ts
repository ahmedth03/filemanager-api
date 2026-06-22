import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import { uploadCarImage, deleteCarImage } from '@/lib/cloudinary';

export async function GET(_: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const car = await prisma.car.findFirst({
    where: { OR: [{ id }, { slug: id }] },
    include: { images: { orderBy: { order: 'asc' } } },
  });
  if (!car) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  return NextResponse.json({ success: true, data: car });
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { id } = await params;
  const formData = await req.formData();
  const imageFiles = formData.getAll('images') as File[];

  const car = await prisma.car.update({
    where: { id },
    data: {
      make:         formData.get('make') as string,
      model:        formData.get('model') as string,
      year:         parseInt(formData.get('year') as string),
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
      status:       formData.get('status') as 'AVAILABLE',
      metaTitle:    formData.get('metaTitle') as string | null,
      metaDesc:     formData.get('metaDesc') as string | null,
    },
  });

  if (imageFiles.length > 0) {
    const existing = await prisma.carImage.findMany({ where: { carId: id } });
    for (const img of existing) {
      if (img.publicId) await deleteCarImage(img.publicId).catch(() => {});
    }
    await prisma.carImage.deleteMany({ where: { carId: id } });

    for (let i = 0; i < imageFiles.length; i++) {
      const file   = imageFiles[i];
      const buffer = Buffer.from(await file.arrayBuffer());
      const result = await uploadCarImage(buffer).catch(() => null);
      if (result) {
        await prisma.carImage.create({
          data: { carId: id, url: result.url, thumbnailUrl: result.thumbnailUrl, publicId: result.publicId, isPrimary: i === 0, order: i },
        });
      }
    }
  }

  return NextResponse.json({ success: true, data: car });
}

export async function DELETE(_: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const session = await getServerSession(authOptions);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { id } = await params;
  const images = await prisma.carImage.findMany({ where: { carId: id } });
  for (const img of images) {
    if (img.publicId) await deleteCarImage(img.publicId).catch(() => {});
  }

  await prisma.car.delete({ where: { id } });
  return NextResponse.json({ success: true });
}
