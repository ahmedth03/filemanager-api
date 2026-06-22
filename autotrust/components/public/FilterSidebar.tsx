'use client';
import { useRouter, useSearchParams } from 'next/navigation';
import { useState, useCallback } from 'react';
import { X, SlidersHorizontal } from 'lucide-react';

const makes = ['Toyota', 'BMW', 'Mercedes-Benz', 'Hyundai', 'Volkswagen', 'Kia', 'Renault', 'Audi', 'Peugeot', 'Citroën'];

export default function FilterSidebar() {
  const router       = useRouter();
  const searchParams = useSearchParams();
  const [open, setOpen] = useState(false);

  const get  = (k: string) => searchParams.get(k) ?? '';
  const apply = useCallback((updates: Record<string, string>) => {
    const p = new URLSearchParams(searchParams.toString());
    Object.entries(updates).forEach(([k, v]) => v ? p.set(k, v) : p.delete(k));
    p.delete('page');
    router.push(`/cars?${p.toString()}`);
  }, [router, searchParams]);

  const clear = () => router.push('/cars');

  const content = (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h3 className="font-heading font-bold text-dark flex items-center gap-2">
          <SlidersHorizontal size={18} className="text-primary-500" /> Filtres
        </h3>
        <button onClick={clear} className="text-xs text-primary-500 hover:underline font-medium">Réinitialiser</button>
      </div>

      {/* Make */}
      <div>
        <label className="block text-sm font-semibold text-dark mb-2">Marque</label>
        <select value={get('make')} onChange={e => apply({ make: e.target.value })} className="input text-sm">
          <option value="">Toutes</option>
          {makes.map(m => <option key={m} value={m}>{m}</option>)}
        </select>
      </div>

      {/* Condition */}
      <div>
        <label className="block text-sm font-semibold text-dark mb-2">État</label>
        <div className="flex gap-2">
          {[['', 'Tous'], ['NEW', 'Neuve'], ['USED', 'Occasion']].map(([v, l]) => (
            <button key={v} onClick={() => apply({ condition: v })} className={`flex-1 text-xs py-2 rounded-lg border font-medium transition-all ${get('condition') === v ? 'bg-primary-500 text-white border-primary-500' : 'border-gray-200 text-gray-600 hover:border-primary-300'}`}>
              {l}
            </button>
          ))}
        </div>
      </div>

      {/* Fuel */}
      <div>
        <label className="block text-sm font-semibold text-dark mb-2">Carburant</label>
        <select value={get('fuel')} onChange={e => apply({ fuel: e.target.value })} className="input text-sm">
          <option value="">Tous</option>
          {[['ESSENCE', 'Essence'], ['DIESEL', 'Diesel'], ['HYBRIDE', 'Hybride'], ['ELECTRIQUE', 'Électrique'], ['GPL', 'GPL']].map(([v, l]) => (
            <option key={v} value={v}>{l}</option>
          ))}
        </select>
      </div>

      {/* Transmission */}
      <div>
        <label className="block text-sm font-semibold text-dark mb-2">Boîte de vitesses</label>
        <div className="flex gap-2">
          {[['', 'Toutes'], ['AUTOMATIQUE', 'Auto'], ['MANUELLE', 'Manu']].map(([v, l]) => (
            <button key={v} onClick={() => apply({ transmission: v })} className={`flex-1 text-xs py-2 rounded-lg border font-medium transition-all ${get('transmission') === v ? 'bg-primary-500 text-white border-primary-500' : 'border-gray-200 text-gray-600 hover:border-primary-300'}`}>
              {l}
            </button>
          ))}
        </div>
      </div>

      {/* Price */}
      <div>
        <label className="block text-sm font-semibold text-dark mb-2">Budget maximum</label>
        <select value={get('priceMax')} onChange={e => apply({ priceMax: e.target.value })} className="input text-sm">
          <option value="">Illimité</option>
          {[2000000, 4000000, 6000000, 8000000, 10000000].map(v => (
            <option key={v} value={v}>{(v / 1000000).toLocaleString()} M DA</option>
          ))}
        </select>
      </div>

      {/* Year */}
      <div>
        <label className="block text-sm font-semibold text-dark mb-2">Année</label>
        <div className="flex gap-2">
          <select value={get('yearMin')} onChange={e => apply({ yearMin: e.target.value })} className="input text-sm flex-1">
            <option value="">De</option>
            {Array.from({ length: 15 }, (_, i) => new Date().getFullYear() - i).map(y => <option key={y} value={y}>{y}</option>)}
          </select>
          <select value={get('yearMax')} onChange={e => apply({ yearMax: e.target.value })} className="input text-sm flex-1">
            <option value="">À</option>
            {Array.from({ length: 5 }, (_, i) => new Date().getFullYear() + 1 - i).map(y => <option key={y} value={y}>{y}</option>)}
          </select>
        </div>
      </div>
    </div>
  );

  return (
    <>
      {/* Mobile trigger */}
      <button onClick={() => setOpen(true)} className="lg:hidden flex items-center gap-2 btn-dark text-sm mb-4">
        <SlidersHorizontal size={16} /> Filtres
      </button>

      {/* Mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div className="absolute inset-0 bg-black/50" onClick={() => setOpen(false)} />
          <div className="absolute left-0 top-0 bottom-0 w-80 bg-white p-6 overflow-y-auto shadow-2xl">
            <button onClick={() => setOpen(false)} className="absolute top-4 right-4 text-gray-400 hover:text-dark">
              <X size={20} />
            </button>
            {content}
          </div>
        </div>
      )}

      {/* Desktop sidebar */}
      <div className="hidden lg:block w-64 flex-shrink-0 bg-white rounded-2xl p-6 shadow-card h-fit sticky top-24">
        {content}
      </div>
    </>
  );
}
