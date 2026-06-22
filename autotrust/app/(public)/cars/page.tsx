import type { Metadata } from 'next';
import { Suspense } from 'react';
import { prisma } from '@/lib/prisma';
import CarCard from '@/components/public/CarCard';
import FilterSidebar from '@/components/public/FilterSidebar';
import { Car, CarFilters } from '@/types';
import { Grid3X3, List, ChevronLeft, ChevronRight } from 'lucide-react';
import Link from 'next/link';

export const metadata: Metadata = {
  title: 'Voitures à vendre en Algérie',
  description: 'Découvrez notre sélection de voitures neuves et d\'occasion en Algérie. Filtrez par marque, modèle, prix et plus.',
};

interface PageProps { searchParams: Promise<Record<string, string>> }

async function getCars(filters: CarFilters) {
  const { make, model, yearMin, yearMax, priceMin, priceMax, condition, fuel, transmission, status = 'AVAILABLE', featured, search, page = 1, limit = 12, sortBy = 'createdAt', sortOrder = 'desc' } = filters;

  const where = {
    ...(status && { status: status as 'AVAILABLE' }),
    ...(make && { make: { contains: make, mode: 'insensitive' as const } }),
    ...(model && { model: { contains: model, mode: 'insensitive' as const } }),
    ...(condition && { condition: condition as 'NEW' | 'USED' }),
    ...(fuel && { fuel: fuel as 'ESSENCE' }),
    ...(transmission && { transmission: transmission as 'AUTOMATIQUE' }),
    ...(featured !== undefined && { featured }),
    ...(search && {
      OR: [
        { make:  { contains: search, mode: 'insensitive' as const } },
        { model: { contains: search, mode: 'insensitive' as const } },
        { description: { contains: search, mode: 'insensitive' as const } },
      ],
    }),
    ...(yearMin || yearMax ? { year: { ...(yearMin && { gte: yearMin }), ...(yearMax && { lte: yearMax }) } } : {}),
    ...(priceMin || priceMax ? { price: { ...(priceMin && { gte: priceMin }), ...(priceMax && { lte: priceMax }) } } : {}),
  };

  const [total, cars] = await Promise.all([
    prisma.car.count({ where }),
    prisma.car.findMany({
      where,
      include: { images: { orderBy: { order: 'asc' } } },
      orderBy: { [sortBy]: sortOrder },
      skip: (page - 1) * limit,
      take: limit,
    }),
  ]);

  return { cars, total, page, limit, totalPages: Math.ceil(total / limit) };
}

export default async function CarsPage({ searchParams }: PageProps) {
  const sp = await searchParams;
  const filters: CarFilters = {
    make:        sp.make,
    model:       sp.model,
    condition:   sp.condition as 'NEW' | 'USED' | undefined,
    fuel:        sp.fuel as 'ESSENCE' | undefined,
    transmission: sp.transmission as 'AUTOMATIQUE' | undefined,
    search:      sp.search,
    yearMin:     sp.yearMin  ? parseInt(sp.yearMin)  : undefined,
    yearMax:     sp.yearMax  ? parseInt(sp.yearMax)  : undefined,
    priceMin:    sp.priceMin ? parseInt(sp.priceMin) : undefined,
    priceMax:    sp.priceMax ? parseInt(sp.priceMax) : undefined,
    featured:    sp.featured === 'true' ? true : undefined,
    page:        sp.page    ? parseInt(sp.page)    : 1,
    sortBy:      (sp.sortBy as 'price' | 'year' | 'createdAt') ?? 'createdAt',
    sortOrder:   (sp.sortOrder as 'asc' | 'desc') ?? 'desc',
  };

  const { cars, total, page, totalPages } = await getCars(filters).catch(() => ({ cars: [], total: 0, page: 1, totalPages: 0 }));

  function buildUrl(overrides: Record<string, string | number>) {
    const params = new URLSearchParams(Object.fromEntries(Object.entries(sp).filter(([, v]) => v)));
    Object.entries(overrides).forEach(([k, v]) => params.set(k, String(v)));
    return `/cars?${params.toString()}`;
  }

  return (
    <div className="pt-20 min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-dark py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h1 className="font-heading font-black text-3xl text-white">Nos Véhicules</h1>
          <p className="text-gray-400 mt-2">{total} véhicule{total !== 1 ? 's' : ''} disponible{total !== 1 ? 's' : ''}</p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex gap-8">
          {/* Sidebar */}
          <Suspense fallback={null}>
            <FilterSidebar />
          </Suspense>

          {/* Main */}
          <div className="flex-1 min-w-0">
            {/* Toolbar */}
            <div className="flex items-center justify-between mb-6 bg-white rounded-xl px-4 py-3 shadow-card">
              <p className="text-sm text-gray-500"><span className="font-semibold text-dark">{total}</span> résultat{total !== 1 ? 's' : ''}</p>
              <div className="flex items-center gap-3">
                <select
                  defaultValue={`${sp.sortBy ?? 'createdAt'}-${sp.sortOrder ?? 'desc'}`}
                  onChange={e => {
                    const [by, order] = e.target.value.split('-');
                    window.location.href = buildUrl({ sortBy: by, sortOrder: order, page: 1 });
                  }}
                  className="text-sm border border-gray-200 rounded-lg px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-primary-500"
                >
                  <option value="createdAt-desc">Plus récents</option>
                  <option value="price-asc">Prix croissant</option>
                  <option value="price-desc">Prix décroissant</option>
                  <option value="year-desc">Année (récente)</option>
                </select>
              </div>
            </div>

            {/* Grid */}
            {cars.length === 0 ? (
              <div className="text-center py-20">
                <div className="text-6xl mb-4">🚗</div>
                <h3 className="font-heading font-bold text-xl text-dark mb-2">Aucun véhicule trouvé</h3>
                <p className="text-gray-500 mb-6">Essayez de modifier vos filtres de recherche.</p>
                <Link href="/cars" className="btn-primary inline-block">Réinitialiser les filtres</Link>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                {(cars as unknown as Car[]).map(car => <CarCard key={car.id} car={car} />)}
              </div>
            )}

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-center gap-2 mt-10">
                {page > 1 && (
                  <Link href={buildUrl({ page: page - 1 })} className="p-2 bg-white rounded-xl border border-gray-200 hover:border-primary-400 transition-colors">
                    <ChevronRight size={18} />
                  </Link>
                )}
                {Array.from({ length: Math.min(totalPages, 7) }, (_, i) => i + 1).map(p => (
                  <Link key={p} href={buildUrl({ page: p })} className={`w-10 h-10 rounded-xl text-sm font-semibold flex items-center justify-center transition-all ${p === page ? 'bg-primary-500 text-white' : 'bg-white border border-gray-200 text-dark hover:border-primary-400'}`}>
                    {p}
                  </Link>
                ))}
                {page < totalPages && (
                  <Link href={buildUrl({ page: page + 1 })} className="p-2 bg-white rounded-xl border border-gray-200 hover:border-primary-400 transition-colors">
                    <ChevronLeft size={18} />
                  </Link>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
