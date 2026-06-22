import { MetadataRoute } from 'next';
import { prisma } from '@/lib/prisma';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'https://autotrust.dz';

  const cars = await prisma.car.findMany({
    where: { status: 'AVAILABLE' },
    select: { slug: true, updatedAt: true },
  }).catch(() => []);

  const staticPages: MetadataRoute.Sitemap = [
    { url: baseUrl,                  lastModified: new Date(), changeFrequency: 'daily',   priority: 1 },
    { url: `${baseUrl}/cars`,        lastModified: new Date(), changeFrequency: 'hourly',  priority: 0.9 },
    { url: `${baseUrl}/financing`,   lastModified: new Date(), changeFrequency: 'monthly', priority: 0.6 },
    { url: `${baseUrl}/about`,       lastModified: new Date(), changeFrequency: 'monthly', priority: 0.5 },
    { url: `${baseUrl}/contact`,     lastModified: new Date(), changeFrequency: 'monthly', priority: 0.5 },
    { url: `${baseUrl}/faq`,         lastModified: new Date(), changeFrequency: 'monthly', priority: 0.4 },
  ];

  const carPages: MetadataRoute.Sitemap = cars.map(car => ({
    url: `${baseUrl}/cars/${car.slug}`,
    lastModified: car.updatedAt,
    changeFrequency: 'weekly' as const,
    priority: 0.8,
  }));

  return [...staticPages, ...carPages];
}
