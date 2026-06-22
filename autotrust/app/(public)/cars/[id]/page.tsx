import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { Phone, MessageCircle, Calendar, Gauge, Fuel, Settings, Users, Zap, Car, MapPin, Shield, ChevronRight } from 'lucide-react';
import { prisma } from '@/lib/prisma';
import { formatPrice, formatMileage, fuelLabel, transmissionLabel, conditionLabel, statusLabel, getCarPrimaryImage } from '@/lib/utils';
import FinancingCalculator from '@/components/public/FinancingCalculator';

interface Props { params: Promise<{ id: string }> }

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const car = await prisma.car.findUnique({ where: { slug: id } }).catch(() => null);
  if (!car) return { title: 'Véhicule non trouvé' };
  return {
    title: car.metaTitle ?? `${car.make} ${car.model} ${car.year} — AutoTrust`,
    description: car.metaDesc ?? car.description ?? undefined,
    openGraph: { title: car.metaTitle ?? `${car.make} ${car.model} ${car.year}`, description: car.metaDesc ?? undefined },
  };
}

export default async function CarDetailPage({ params }: Props) {
  const { id } = await params;
  const car = await prisma.car.findUnique({
    where: { slug: id },
    include: { images: { orderBy: { order: 'asc' } } },
  }).catch(() => null);

  if (!car) notFound();

  // Increment view count
  prisma.car.update({ where: { id: car.id }, data: { viewCount: { increment: 1 } } }).catch(() => {});

  const primaryImage = getCarPrimaryImage(car as { images: { url: string; isPrimary: boolean }[] });
  const whatsapp = process.env.NEXT_PUBLIC_WHATSAPP ?? '213555123456';
  const whatsappMsg = encodeURIComponent(`Bonjour, je suis intéressé par ${car.make} ${car.model} ${car.year} — ${formatPrice(car.price)}`);

  const specs = [
    { icon: Calendar,  label: 'Année',           value: car.year },
    { icon: Gauge,     label: 'Kilométrage',      value: formatMileage(car.mileage) },
    { icon: Fuel,      label: 'Carburant',        value: fuelLabel(car.fuel) },
    { icon: Settings,  label: 'Boîte de vitesse', value: transmissionLabel(car.transmission) },
    { icon: Users,     label: 'Nombre de places', value: `${car.seats} places` },
    { icon: Car,       label: 'Portes',           value: `${car.doors} portes` },
    ...(car.power ? [{ icon: Zap, label: 'Puissance', value: `${car.power} ch` }] : []),
    ...(car.engineSize ? [{ icon: Settings, label: 'Cylindrée', value: `${car.engineSize} L` }] : []),
    ...(car.color ? [{ icon: Car, label: 'Couleur', value: car.color }] : []),
  ];

  // Structured data
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Car',
    name: `${car.make} ${car.model} ${car.year}`,
    brand: { '@type': 'Brand', name: car.make },
    model: car.model,
    modelDate: car.year,
    offers: {
      '@type': 'Offer',
      price: car.price,
      priceCurrency: 'DZD',
      availability: car.status === 'AVAILABLE' ? 'https://schema.org/InStock' : 'https://schema.org/SoldOut',
      seller: { '@type': 'Organization', name: 'AutoTrust' },
    },
    mileageFromOdometer: { '@type': 'QuantitativeValue', value: car.mileage, unitCode: 'KMT' },
  };

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />

      <div className="pt-20 min-h-screen bg-gray-50">
        {/* Breadcrumb */}
        <div className="bg-white border-b border-gray-100">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3">
            <div className="flex items-center gap-2 text-sm text-gray-500">
              <Link href="/" className="hover:text-primary-500">Accueil</Link>
              <ChevronRight size={14} />
              <Link href="/cars" className="hover:text-primary-500">Véhicules</Link>
              <ChevronRight size={14} />
              <span className="text-dark font-medium">{car.make} {car.model} {car.year}</span>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="grid lg:grid-cols-3 gap-8">
            {/* Left: Images & Description */}
            <div className="lg:col-span-2 space-y-6">
              {/* Main image */}
              <div className="relative aspect-video rounded-2xl overflow-hidden bg-gray-100 shadow-card">
                <Image src={primaryImage} alt={`${car.make} ${car.model}`} fill style={{ objectFit: 'cover' }} priority sizes="(max-width: 768px) 100vw, 60vw" className="hover:scale-105 transition-transform duration-700" />
                <div className="absolute top-4 left-4 flex gap-2">
                  <span className={car.condition === 'NEW' ? 'badge-new' : 'badge-used'}>{conditionLabel(car.condition)}</span>
                  <span className={car.status === 'AVAILABLE' ? 'badge-available' : 'badge-sold'}>{statusLabel(car.status)}</span>
                </div>
              </div>

              {/* Thumbnails */}
              {car.images.length > 1 && (
                <div className="grid grid-cols-5 gap-2">
                  {car.images.map((img, i) => (
                    <div key={img.id} className={`relative aspect-video rounded-xl overflow-hidden cursor-pointer border-2 ${img.isPrimary ? 'border-primary-500' : 'border-transparent'}`}>
                      <Image src={img.url} alt={`Photo ${i + 1}`} fill style={{ objectFit: 'cover' }} sizes="120px" />
                    </div>
                  ))}
                </div>
              )}

              {/* Description */}
              <div className="bg-white rounded-2xl p-6 shadow-card">
                <h2 className="font-heading font-bold text-xl text-dark mb-4">Description</h2>
                <p className="text-gray-600 leading-relaxed whitespace-pre-line">{car.aiDescription ?? car.description ?? 'Contactez-nous pour plus d\'informations sur ce véhicule.'}</p>
              </div>

              {/* Specs */}
              <div className="bg-white rounded-2xl p-6 shadow-card">
                <h2 className="font-heading font-bold text-xl text-dark mb-5">Caractéristiques techniques</h2>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                  {specs.map(({ icon: Icon, label, value }) => (
                    <div key={label} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                      <div className="w-9 h-9 bg-primary-50 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Icon size={16} className="text-primary-500" />
                      </div>
                      <div>
                        <p className="text-xs text-gray-400">{label}</p>
                        <p className="text-sm font-semibold text-dark">{String(value)}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Financing */}
              <FinancingCalculator defaultPrice={car.price} />
            </div>

            {/* Right: Purchase Card */}
            <div className="space-y-5">
              <div className="bg-white rounded-2xl p-6 shadow-card sticky top-24">
                <h1 className="font-heading font-black text-2xl text-dark">{car.make} {car.model}</h1>
                <p className="text-gray-500 mt-1">{car.year} • {formatMileage(car.mileage)}</p>
                <div className="mt-4 mb-6">
                  <p className="text-4xl font-heading font-black text-primary-500">{formatPrice(car.price)}</p>
                  <p className="text-gray-400 text-sm mt-1">Prix TTC</p>
                </div>

                {car.status === 'AVAILABLE' && (
                  <>
                    {/* Lead Form */}
                    <LeadForm carId={car.id} carName={`${car.make} ${car.model} ${car.year}`} />

                    <div className="mt-4 flex flex-col gap-3">
                      <a href={`https://wa.me/${whatsapp}?text=${whatsappMsg}`} target="_blank" rel="noopener noreferrer" className="flex items-center justify-center gap-2 w-full py-3 rounded-xl bg-green-500 hover:bg-green-600 text-white font-semibold transition-colors text-sm">
                        <MessageCircle size={18} /> WhatsApp
                      </a>
                      <a href="tel:+213555123456" className="flex items-center justify-center gap-2 w-full py-3 rounded-xl border-2 border-dark text-dark hover:bg-dark hover:text-white font-semibold transition-colors text-sm">
                        <Phone size={18} /> Appeler
                      </a>
                    </div>
                  </>
                )}

                {car.status !== 'AVAILABLE' && (
                  <div className="text-center py-6">
                    <p className="text-lg font-bold text-gray-500">{statusLabel(car.status)}</p>
                    <Link href="/cars" className="btn-primary mt-4 inline-block text-sm">Voir d&apos;autres voitures</Link>
                  </div>
                )}

                {/* Trust badges */}
                <div className="mt-6 pt-5 border-t border-gray-100 grid grid-cols-2 gap-3">
                  {[
                    { icon: Shield, text: 'Vérifié AutoTrust' },
                    { icon: MapPin, text: 'Alger, Algérie' },
                  ].map(({ icon: Icon, text }) => (
                    <div key={text} className="flex items-center gap-2 text-gray-500">
                      <Icon size={14} className="text-primary-500 flex-shrink-0" />
                      <span className="text-xs">{text}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

// Lead form (client component inline)
function LeadForm({ carId, carName }: { carId: string; carName: string }) {
  return (
    <form action="/api/leads" method="POST" className="space-y-3">
      <input type="hidden" name="carId" value={carId} />
      <input type="hidden" name="source" value="car_detail" />
      <div className="grid grid-cols-2 gap-2">
        <input name="name" required placeholder="Nom *" className="input text-sm px-3 py-2.5 col-span-2" />
        <input name="phone" required placeholder="Téléphone *" className="input text-sm px-3 py-2.5 col-span-2" />
        <input name="email" type="email" placeholder="Email" className="input text-sm px-3 py-2.5 col-span-2" />
        <textarea name="message" rows={2} placeholder="Message..." defaultValue={`Intéressé par ${carName}`} className="input text-sm px-3 py-2.5 resize-none col-span-2" />
      </div>
      <button type="submit" className="btn-primary w-full text-sm py-3">
        🚗 Demander un essai / prix
      </button>
    </form>
  );
}
