import type { Metadata } from 'next';
import FinancingCalculator from '@/components/public/FinancingCalculator';
import ContactForm from '@/components/public/ContactForm';
import { CheckCircle, Clock, FileText, CreditCard } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Financement Auto',
  description: 'Simulez et demandez votre financement auto en Algérie. Taux compétitifs, réponse rapide avec AutoTrust.',
};

const steps = [
  { icon: FileText,    title: 'Déposez votre demande', desc: 'Remplissez le formulaire en ligne en quelques minutes.' },
  { icon: Clock,       title: 'Étude de dossier',       desc: 'Nos conseillers analysent votre dossier sous 24h.' },
  { icon: CheckCircle, title: 'Accord de principe',     desc: 'Vous recevez une offre personnalisée par téléphone.' },
  { icon: CreditCard,  title: 'Déblocage des fonds',    desc: 'Les fonds sont débloqués directement chez nous.' },
];

export default function FinancingPage() {
  return (
    <div className="pt-20">
      {/* Header */}
      <div className="bg-dark py-20 text-center relative overflow-hidden">
        <div className="absolute inset-0 opacity-5 bg-[radial-gradient(circle_at_50%_50%,#E30613,transparent_70%)]" />
        <div className="relative z-10 max-w-3xl mx-auto px-4">
          <span className="text-primary-400 text-sm font-semibold uppercase tracking-wider">Solutions financières</span>
          <h1 className="font-heading font-black text-5xl text-white mt-3 mb-4">Financement Auto</h1>
          <p className="text-gray-300 text-xl">Des solutions adaptées à chaque budget avec les meilleures banques d&apos;Algérie.</p>
        </div>
      </div>

      {/* Steps */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-5xl mx-auto px-4">
          <h2 className="section-title text-center mb-12">Comment ça marche ?</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {steps.map((s, i) => (
              <div key={i} className="text-center">
                <div className="relative w-16 h-16 bg-primary-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <s.icon size={28} className="text-white" />
                  <span className="absolute -top-2 -right-2 w-7 h-7 bg-dark text-white text-xs font-bold rounded-full flex items-center justify-center">{i + 1}</span>
                </div>
                <h3 className="font-bold text-dark mb-2">{s.title}</h3>
                <p className="text-gray-500 text-sm">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Calculator */}
      <section className="py-16 bg-white">
        <div className="max-w-4xl mx-auto px-4">
          <h2 className="section-title text-center mb-8">Simulez vos mensualités</h2>
          <FinancingCalculator />
        </div>
      </section>

      {/* Advantages */}
      <section className="py-16 bg-primary-500 text-white">
        <div className="max-w-5xl mx-auto px-4 text-center">
          <h2 className="font-heading font-black text-3xl mb-10">Nos avantages</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-8">
            {[
              ['Taux dès 8%', 'Les meilleurs taux du marché algérien'],
              ['Jusqu\'à 60 mois', 'Des durées flexibles selon votre capacité'],
              ['Réponse 24h', 'Traitement rapide de votre dossier'],
            ].map(([title, desc]) => (
              <div key={title}>
                <p className="font-heading font-black text-2xl mb-2">{title}</p>
                <p className="text-white/80 text-sm">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Request Form */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-2xl mx-auto px-4">
          <h2 className="section-title text-center mb-4">Demander un financement</h2>
          <p className="section-subtitle text-center mb-8">Un conseiller vous contactera dans les 24h.</p>
          <div className="bg-white rounded-2xl p-8 shadow-card">
            <ContactForm />
          </div>
        </div>
      </section>
    </div>
  );
}
