'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import { Search, ChevronDown } from 'lucide-react';

const makes = ['Toyota', 'BMW', 'Mercedes-Benz', 'Hyundai', 'Volkswagen', 'Kia', 'Renault', 'Audi', 'Peugeot', 'Citroën'];

export default function HeroSection() {
  const router = useRouter();
  const [make,      setMake]      = useState('');
  const [condition, setCondition] = useState('');
  const [priceMax,  setPriceMax]  = useState('');

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    const params = new URLSearchParams();
    if (make)      params.set('make', make);
    if (condition) params.set('condition', condition);
    if (priceMax)  params.set('priceMax', priceMax);
    router.push(`/cars?${params.toString()}`);
  }

  return (
    <section className="relative min-h-screen flex items-center overflow-hidden bg-dark">
      {/* Background */}
      <div className="absolute inset-0">
        <Image src="https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1920&q=80" alt="Hero" fill style={{ objectFit: 'cover' }} priority quality={90} className="opacity-40" />
        <div className="absolute inset-0 bg-gradient-to-r from-dark via-dark/80 to-transparent" />
        <div className="absolute inset-0 bg-gradient-to-t from-dark/60 via-transparent to-dark/20" />
      </div>

      {/* Red accent bar */}
      <div className="absolute top-0 left-0 w-2 h-full bg-primary-500" />

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-32">
        <div className="max-w-3xl">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 bg-primary-500/20 border border-primary-500/40 text-primary-400 px-4 py-2 rounded-full text-sm font-semibold mb-8 animate-fade-up">
            <span className="w-2 h-2 bg-primary-500 rounded-full animate-pulse" />
            N°1 des ventes auto en Algérie
          </div>

          {/* Title */}
          <h1 className="font-heading font-black text-white text-5xl md:text-6xl lg:text-7xl leading-tight mb-6 animate-fade-up animate-delay-100">
            Votre Prochaine<br />
            <span className="text-primary-500">Voiture</span> Vous<br />
            Attend.
          </h1>

          <p className="text-gray-300 text-xl mb-10 leading-relaxed animate-fade-up animate-delay-200">
            Des milliers de véhicules neufs et d&apos;occasion. Financement facile. Garantie AutoTrust.
          </p>

          {/* Search Bar */}
          <form onSubmit={handleSearch} className="bg-white rounded-2xl p-2 shadow-2xl animate-fade-up animate-delay-300">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-2">
              <div className="relative">
                <select value={make} onChange={e => setMake(e.target.value)} className="w-full appearance-none bg-gray-50 text-dark px-4 py-3.5 pr-10 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary-500 border-0">
                  <option value="">Toutes les marques</option>
                  {makes.map(m => <option key={m} value={m}>{m}</option>)}
                </select>
                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
              <div className="relative">
                <select value={condition} onChange={e => setCondition(e.target.value)} className="w-full appearance-none bg-gray-50 text-dark px-4 py-3.5 pr-10 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary-500 border-0">
                  <option value="">Neuve & Occasion</option>
                  <option value="NEW">Neuve</option>
                  <option value="USED">Occasion</option>
                </select>
                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
              <div className="relative">
                <select value={priceMax} onChange={e => setPriceMax(e.target.value)} className="w-full appearance-none bg-gray-50 text-dark px-4 py-3.5 pr-10 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary-500 border-0">
                  <option value="">Tout budget</option>
                  <option value="2000000">≤ 2 000 000 DA</option>
                  <option value="4000000">≤ 4 000 000 DA</option>
                  <option value="6000000">≤ 6 000 000 DA</option>
                  <option value="10000000">≤ 10 000 000 DA</option>
                </select>
                <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
              </div>
            </div>
            <button type="submit" className="mt-2 w-full bg-primary-500 hover:bg-primary-600 text-white font-bold py-3.5 rounded-xl flex items-center justify-center gap-2 transition-all duration-200 hover:shadow-red">
              <Search size={18} /> Rechercher une voiture
            </button>
          </form>

          {/* Quick links */}
          <div className="flex flex-wrap gap-3 mt-6 animate-fade-up animate-delay-400">
            {['Toyota', 'BMW', 'Mercedes', 'SUV', 'Occasion'].map(tag => (
              <button key={tag} onClick={() => router.push(`/cars?search=${tag}`)} className="text-white/70 hover:text-white text-sm border border-white/20 hover:border-white/50 px-3 py-1.5 rounded-full transition-all duration-200">
                {tag}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Scroll indicator */}
      <div className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-white/40 animate-bounce">
        <span className="text-xs">Défiler</span>
        <ChevronDown size={16} />
      </div>
    </section>
  );
}
