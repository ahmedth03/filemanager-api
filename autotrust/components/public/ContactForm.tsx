'use client';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { CheckCircle, Loader2 } from 'lucide-react';

interface FormData { name: string; email: string; phone: string; subject: string; message: string; }

export default function ContactForm() {
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>();
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');

  async function onSubmit(data: FormData) {
    setStatus('loading');
    try {
      const res = await fetch('/api/contact', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) });
      if (!res.ok) throw new Error();
      setStatus('success');
      reset();
    } catch {
      setStatus('error');
    }
  }

  if (status === 'success') {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <CheckCircle size={56} className="text-green-500 mb-4" />
        <h3 className="font-heading font-bold text-2xl text-dark mb-2">Message envoyé !</h3>
        <p className="text-gray-500 mb-6">Nous vous répondrons dans les plus brefs délais.</p>
        <button onClick={() => setStatus('idle')} className="btn-primary text-sm px-6 py-2.5">Envoyer un autre message</button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
      <div className="grid sm:grid-cols-2 gap-5">
        <div>
          <label className="block text-sm font-semibold text-dark mb-1.5">Nom complet *</label>
          <input {...register('name', { required: true })} placeholder="Votre nom" className={`input ${errors.name ? 'border-red-400 focus:ring-red-400' : ''}`} />
        </div>
        <div>
          <label className="block text-sm font-semibold text-dark mb-1.5">Téléphone *</label>
          <input {...register('phone', { required: true })} placeholder="+213 5XX XX XX XX" className={`input ${errors.phone ? 'border-red-400 focus:ring-red-400' : ''}`} />
        </div>
      </div>

      <div>
        <label className="block text-sm font-semibold text-dark mb-1.5">Email</label>
        <input {...register('email')} type="email" placeholder="votre@email.com" className="input" />
      </div>

      <div>
        <label className="block text-sm font-semibold text-dark mb-1.5">Sujet *</label>
        <select {...register('subject', { required: true })} className={`input ${errors.subject ? 'border-red-400' : ''}`}>
          <option value="">Sélectionner...</option>
          <option>Renseignement sur un véhicule</option>
          <option>Demande de financement</option>
          <option>Reprise de véhicule</option>
          <option>Service après-vente</option>
          <option>Autre</option>
        </select>
      </div>

      <div>
        <label className="block text-sm font-semibold text-dark mb-1.5">Message *</label>
        <textarea {...register('message', { required: true })} rows={5} placeholder="Décrivez votre demande..." className={`input resize-none ${errors.message ? 'border-red-400' : ''}`} />
      </div>

      {status === 'error' && <p className="text-red-500 text-sm bg-red-50 p-3 rounded-lg">Une erreur est survenue. Veuillez réessayer.</p>}

      <button type="submit" disabled={status === 'loading'} className="btn-primary w-full flex items-center justify-center gap-2 disabled:opacity-60">
        {status === 'loading' ? <><Loader2 size={18} className="animate-spin" /> Envoi en cours...</> : 'Envoyer le message →'}
      </button>
    </form>
  );
}
