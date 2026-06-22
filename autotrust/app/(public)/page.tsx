import type { Metadata } from 'next';
import Link from 'next/link';
import Image from 'next/image';
import { ChevronRight, Star, Shield, Headphones, CreditCard } from 'lucide-react';
import HeroSection from '@/components/public/HeroSection';
import CarCard from '@/components/public/CarCard';
import StatsSection from '@/components/public/StatsSection';
import FinancingCalculator from '@/components/public/FinancingCalculator';
import { prisma } from '@/lib/prisma';
import { Car } from '@/types';

export const metadata: Metadata = {
  title: 'AutoTrust — Drive With Confidence | Voitures Algérie',
  description: 'Découvrez notre sélection de voitures neuves et d\'occasion en Algérie. Financement facile, garantie AutoTrust.',
};

const testimonials = [
  { name: 'Mohamed Benali', city: 'Alger', rating: 5, text: 'Service exceptionnel ! J\'ai trouvé ma BMW X5 en moins d\'une semaine. Équipe professionnelle et prix transparent.' },
  { name: 'Fatima Hadj', city: 'Oran', rating: 5, text: 'AutoTrust m\'a aidé à financer ma Toyota Camry avec un taux avantageux. Très satisfaite de mon achat !' },
  { name: 'Karim Boussaad', city: 'Constantine', rating: 5, text: 'Excellent accompagnement depuis le choix du véhicule jusqu\'à la livraison. Je recommande vivement AutoTrust.' },
];

export default async function HomePage() {
  const featuredCars = await prisma.car.findMany({
    where: { featured: true, status: 'AVAILABLE' },
    include: { images: { orderBy: { order: 'asc' } } },
    orderBy: { createdAt: 'desc' },
    take: 6,
  }).catch(() => []);

  const latestCars = await prisma.car.findMany({
    where: { status: 'AVAILABLE' },
    include: { images: { orderBy: { order: 'asc' } } },
    orderBy: { createdAt: 'desc' },
    take: 8,
  }).catch(() => []);

  return (
    <>
      <HeroSection />

      {/* Stats */}
      <StatsSection />

      {/* Featured Cars */}
      {featuredCars.length > 0 && (
        <section className="py-20 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-end justify-between mb-10">
              <div>
                <span className="text-primary-500 text-sm font-semibold uppercase tracking-wider">Sélection</span>
                <h2 className="section-title mt-2">Véhicules Vedettes</h2>
              </div>
              <Link href="/cars?featured=true" className="flex items-center gap-1 text-primary-500 hover:text-primary-600 font-semibold text-sm transition-colors">
                Voir tout <ChevronRight size={16} />
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {(featuredCars as unknown as Car[]).map(car => <CarCard key={car.id} car={car} />)}
            </div>
          </div>
        </section>
      )}

      {/* Latest Cars */}
      {latestCars.length > 0 && (
        <section className="py-20 bg-gray-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-end justify-between mb-10">
              <div>
                <span className="text-primary-500 text-sm font-semibold uppercase tracking-wider">Nouveau</span>
                <h2 className="section-title mt-2">Dernières Annonces</h2>
              </div>
              <Link href="/cars" className="flex items-center gap-1 text-primary-500 hover:text-primary-600 font-semibold text-sm transition-colors">
                Voir tout <ChevronRight size={16} />
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
              {(latestCars as unknown as Car[]).map(car => <CarCard key={car.id} car={car} />)}
            </div>
          </div>
        </section>
      )}

      {/* Why AutoTrust */}
      <section className="py-20 bg-dark text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-14">
            <span className="text-primary-400 text-sm font-semibold uppercase tracking-wider">Notre engagement</span>
            <h2 className="font-heading font-black text-4xl text-white mt-2">Pourquoi choisir AutoTrust ?</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
            {[
              { icon: Shield,     title: 'Véhicules certifiés', desc: 'Chaque voiture est vérifiée et contrôlée par nos experts avant la mise en vente.' },
              { icon: CreditCard, title: 'Financement facile',  desc: 'Des solutions de financement flexibles avec les meilleures banques d\'Algérie.' },
              { icon: Star,       title: 'Meilleurs prix',      desc: 'Nous garantissons les prix les plus compétitifs du marché algérien.' },
              { icon: Headphones, title: 'Support 7j/7',        desc: 'Notre équipe est disponible 7j/7 pour répondre à toutes vos questions.' },
            ].map((item, i) => (
              <div key={i} className="text-center">
                <div className="w-14 h-14 bg-primary-500/20 rounded-2xl flex items-center justify-center mx-auto mb-5">
                  <item.icon size={26} className="text-primary-400" />
                </div>
                <h3 className="font-heading font-bold text-lg text-white mb-3">{item.title}</h3>
                <p className="text-gray-400 text-sm leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Financing Calculator */}
      <section className="py-20 bg-white">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10">
            <span className="text-primary-500 text-sm font-semibold uppercase tracking-wider">Financement</span>
            <h2 className="section-title mt-2">Calculez vos mensualités</h2>
            <p className="section-subtitle mx-auto mt-2">Simulez votre financement auto en quelques secondes</p>
          </div>
          <FinancingCalculator />
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <span className="text-primary-500 text-sm font-semibold uppercase tracking-wider">Avis clients</span>
            <h2 className="section-title mt-2">Ce que disent nos clients</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {testimonials.map((t, i) => (
              <div key={i} className="card p-6">
                <div className="flex gap-1 mb-4">
                  {Array.from({ length: t.rating }).map((_, j) => <Star key={j} size={16} fill="#E30613" className="text-primary-500" />)}
                </div>
                <p className="text-gray-600 text-sm leading-relaxed mb-5 italic">&ldquo;{t.text}&rdquo;</p>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary-500 rounded-full flex items-center justify-center text-white font-bold text-sm">{t.name[0]}</div>
                  <div>
                    <p className="font-semibold text-dark text-sm">{t.name}</p>
                    <p className="text-gray-400 text-xs">{t.city}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Banner */}
      <section className="py-20 bg-primary-500 relative overflow-hidden">
        <div className="absolute inset-0 opacity-10">
          <Image src="https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1600&q=60" alt="" fill style={{ objectFit: 'cover' }} />
        </div>
        <div className="relative z-10 max-w-4xl mx-auto px-4 text-center text-white">
          <h2 className="font-heading font-black text-4xl md:text-5xl mb-4">Prêt à conduire votre rêve ?</h2>
          <p className="text-white/85 text-xl mb-8">Parcourez notre catalogue et trouvez votre prochaine voiture dès aujourd&apos;hui.</p>
          <div className="flex flex-wrap gap-4 justify-center">
            <Link href="/cars" className="bg-white text-primary-500 font-bold px-8 py-4 rounded-xl hover:bg-gray-100 transition-colors">
              Explorer les voitures
            </Link>
            <Link href="/contact" className="btn-secondary">
              Nous contacter
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
