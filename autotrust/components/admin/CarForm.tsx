'use client';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useRouter } from 'next/navigation';
import { Loader2, Sparkles, Upload } from 'lucide-react';
import { Car } from '@/types';

type FormValues = Omit<Car, 'id' | 'images' | 'createdAt' | 'updatedAt' | 'viewCount' | 'slug' | 'leads'>;

interface Props { car?: Car; }

export default function CarForm({ car }: Props) {
  const router = useRouter();
  const { register, handleSubmit, setValue, watch, formState: { errors, isSubmitting } } = useForm<FormValues>({
    defaultValues: car ? {
      make: car.make, model: car.model, year: car.year, price: car.price,
      mileage: car.mileage, condition: car.condition, fuel: car.fuel,
      transmission: car.transmission, color: car.color ?? '', doors: car.doors,
      seats: car.seats, power: car.power ?? undefined, engineSize: car.engineSize ?? undefined,
      description: car.description ?? '', featured: car.featured, status: car.status,
      metaTitle: car.metaTitle ?? '', metaDesc: car.metaDesc ?? '',
    } : { condition: 'NEW', fuel: 'ESSENCE', transmission: 'AUTOMATIQUE', status: 'AVAILABLE', doors: 5, seats: 5, year: new Date().getFullYear(), mileage: 0 },
  });

  const [aiLoading, setAiLoading] = useState(false);
  const [images, setImages]       = useState<File[]>([]);
  const [error, setError]         = useState('');

  const make  = watch('make');
  const model = watch('model');
  const year  = watch('year');

  async function generateAiDescription() {
    setAiLoading(true);
    try {
      const res = await fetch('/api/ai/generate-description', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ make, model, year, condition: watch('condition'), fuel: watch('fuel'), transmission: watch('transmission'), mileage: watch('mileage'), price: watch('price'), power: watch('power') }),
      });
      const data = await res.json();
      if (data.description) setValue('description', data.description);
    } finally {
      setAiLoading(false);
    }
  }

  async function onSubmit(data: FormValues) {
    setError('');
    const fd = new FormData();
    Object.entries(data).forEach(([k, v]) => v !== undefined && v !== null && fd.append(k, String(v)));
    images.forEach(f => fd.append('images', f));

    const res = await fetch(car ? `/api/cars/${car.id}` : '/api/cars', {
      method: car ? 'PUT' : 'POST',
      body: fd,
    });

    if (!res.ok) { setError('Une erreur est survenue.'); return; }
    router.push('/admin/cars');
    router.refresh();
  }

  const input = 'w-full px-4 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500';
  const label = 'block text-sm font-semibold text-dark mb-1.5';

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
      {error && <div className="bg-red-50 text-red-600 p-4 rounded-xl text-sm">{error}</div>}

      {/* Basic Info */}
      <div className="bg-white rounded-2xl p-6 shadow-card">
        <h3 className="font-heading font-bold text-dark mb-5">Informations générales</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          <div><label className={label}>Marque *</label><input {...register('make', { required: true })} className={input} placeholder="Toyota" /></div>
          <div><label className={label}>Modèle *</label><input {...register('model', { required: true })} className={input} placeholder="Camry" /></div>
          <div><label className={label}>Année *</label><input {...register('year', { required: true, valueAsNumber: true })} type="number" min={1990} max={new Date().getFullYear()+2} className={input} /></div>
          <div><label className={label}>Prix (DA) *</label><input {...register('price', { required: true, valueAsNumber: true })} type="number" min={0} className={input} /></div>
          <div><label className={label}>Kilométrage</label><input {...register('mileage', { valueAsNumber: true })} type="number" min={0} className={input} /></div>
          <div><label className={label}>Couleur</label><input {...register('color')} className={input} placeholder="Blanc" /></div>
        </div>
      </div>

      {/* Tech Specs */}
      <div className="bg-white rounded-2xl p-6 shadow-card">
        <h3 className="font-heading font-bold text-dark mb-5">Caractéristiques techniques</h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          <div>
            <label className={label}>État</label>
            <select {...register('condition')} className={input}>
              <option value="NEW">Neuve</option>
              <option value="USED">Occasion</option>
            </select>
          </div>
          <div>
            <label className={label}>Carburant</label>
            <select {...register('fuel')} className={input}>
              {[['ESSENCE','Essence'],['DIESEL','Diesel'],['HYBRIDE','Hybride'],['ELECTRIQUE','Électrique'],['GPL','GPL']].map(([v,l]) => <option key={v} value={v}>{l}</option>)}
            </select>
          </div>
          <div>
            <label className={label}>Boîte de vitesses</label>
            <select {...register('transmission')} className={input}>
              <option value="AUTOMATIQUE">Automatique</option>
              <option value="MANUELLE">Manuelle</option>
            </select>
          </div>
          <div><label className={label}>Portes</label><input {...register('doors', { valueAsNumber: true })} type="number" min={2} max={7} className={input} /></div>
          <div><label className={label}>Places</label><input {...register('seats', { valueAsNumber: true })} type="number" min={1} max={9} className={input} /></div>
          <div><label className={label}>Puissance (ch)</label><input {...register('power', { valueAsNumber: true })} type="number" min={0} className={input} /></div>
          <div><label className={label}>Cylindrée (L)</label><input {...register('engineSize', { valueAsNumber: true })} type="number" step="0.1" min={0} className={input} /></div>
          <div>
            <label className={label}>Statut</label>
            <select {...register('status')} className={input}>
              <option value="AVAILABLE">Disponible</option>
              <option value="RESERVED">Réservée</option>
              <option value="SOLD">Vendue</option>
              <option value="COMING_SOON">Bientôt</option>
            </select>
          </div>
          <div className="flex items-center gap-3 pt-6">
            <input {...register('featured')} type="checkbox" id="featured" className="w-4 h-4 accent-primary-500" />
            <label htmlFor="featured" className="text-sm font-medium text-dark">Véhicule vedette</label>
          </div>
        </div>
      </div>

      {/* Description */}
      <div className="bg-white rounded-2xl p-6 shadow-card">
        <div className="flex items-center justify-between mb-5">
          <h3 className="font-heading font-bold text-dark">Description</h3>
          <button type="button" onClick={generateAiDescription} disabled={aiLoading || !make || !model} className="flex items-center gap-2 text-sm text-purple-600 hover:text-purple-700 border border-purple-200 hover:border-purple-400 px-3 py-1.5 rounded-lg transition-all disabled:opacity-40">
            {aiLoading ? <Loader2 size={14} className="animate-spin" /> : <Sparkles size={14} />}
            Générer avec IA
          </button>
        </div>
        <textarea {...register('description')} rows={5} className={`${input} resize-none`} placeholder="Description du véhicule..." />
      </div>

      {/* Images */}
      <div className="bg-white rounded-2xl p-6 shadow-card">
        <h3 className="font-heading font-bold text-dark mb-5">Photos</h3>
        <label className="border-2 border-dashed border-gray-200 hover:border-primary-400 rounded-xl p-8 flex flex-col items-center gap-3 cursor-pointer transition-colors group">
          <Upload size={28} className="text-gray-300 group-hover:text-primary-400 transition-colors" />
          <p className="text-sm text-gray-400 group-hover:text-primary-500 font-medium">Cliquer pour ajouter des photos</p>
          <p className="text-xs text-gray-300">PNG, JPG, WEBP — 10 Mo max chacune</p>
          <input type="file" multiple accept="image/*" onChange={e => setImages(Array.from(e.target.files ?? []))} className="hidden" />
        </label>
        {images.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {images.map((f, i) => (
              <div key={i} className="w-20 h-20 bg-gray-100 rounded-lg overflow-hidden relative">
                <img src={URL.createObjectURL(f)} alt="" className="w-full h-full object-cover" />
              </div>
            ))}
          </div>
        )}
        {car?.images.length ? (
          <div className="mt-4">
            <p className="text-xs text-gray-400 mb-2">Photos actuelles</p>
            <div className="flex flex-wrap gap-2">
              {car.images.map(img => (
                <div key={img.id} className={`w-20 h-20 rounded-lg overflow-hidden border-2 ${img.isPrimary ? 'border-primary-500' : 'border-transparent'}`}>
                  <img src={img.url} alt="" className="w-full h-full object-cover" />
                </div>
              ))}
            </div>
          </div>
        ) : null}
      </div>

      {/* SEO */}
      <div className="bg-white rounded-2xl p-6 shadow-card">
        <h3 className="font-heading font-bold text-dark mb-5">SEO</h3>
        <div className="space-y-4">
          <div><label className={label}>Meta Title</label><input {...register('metaTitle')} className={input} placeholder="Toyota Camry 2024 — AutoTrust Algérie" /></div>
          <div><label className={label}>Meta Description</label><textarea {...register('metaDesc')} rows={3} className={`${input} resize-none`} placeholder="Description pour les moteurs de recherche..." /></div>
        </div>
      </div>

      {/* Submit */}
      <div className="flex gap-4">
        <button type="button" onClick={() => router.back()} className="flex-1 btn-dark text-sm py-3">Annuler</button>
        <button type="submit" disabled={isSubmitting} className="flex-1 btn-primary text-sm py-3 flex items-center justify-center gap-2">
          {isSubmitting ? <><Loader2 size={16} className="animate-spin" /> Enregistrement...</> : car ? 'Mettre à jour' : 'Ajouter le véhicule'}
        </button>
      </div>
    </form>
  );
}
