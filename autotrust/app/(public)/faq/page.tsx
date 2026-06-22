'use client';
import type { Metadata } from 'next';
import { useState } from 'react';
import { ChevronDown } from 'lucide-react';

const faqs = [
  { q: 'Comment puis-je acheter une voiture sur AutoTrust ?', a: 'Parcourez notre catalogue, choisissez votre véhicule, remplissez le formulaire de demande ou contactez-nous directement. Notre équipe vous guidera tout au long du processus.' },
  { q: 'Les véhicules sont-ils inspectés ?', a: 'Oui, tous nos véhicules d\'occasion passent par une inspection complète de 150 points réalisée par nos experts automobiles certifiés avant d\'être mis en vente.' },
  { q: 'Proposez-vous des solutions de financement ?', a: 'Absolument ! Nous travaillons avec plusieurs banques algériennes pour vous proposer les meilleures offres de crédit auto, avec des taux compétitifs et des durées jusqu\'à 60 mois.' },
  { q: 'Puis-je faire essayer le véhicule avant l\'achat ?', a: 'Bien sûr. Après votre demande, nous fixons un rendez-vous pour un essai du véhicule dans nos locaux ou dans un endroit convenu.' },
  { q: 'Quelle garantie offrez-vous ?', a: 'Tous nos véhicules certifiés bénéficient d\'une garantie AutoTrust de 6 mois à 1 an selon le type de véhicule. Les détails sont précisés sur chaque annonce.' },
  { q: 'Puis-je vendre ma voiture sur AutoTrust ?', a: 'Oui, nous acceptons les véhicules en reprise ou en vente consignée. Contactez-nous pour une évaluation gratuite de votre véhicule.' },
  { q: 'Comment puis-je vous contacter ?', a: 'Par téléphone au +213 555 123 456, par WhatsApp, par email à contact@autotrust.dz ou via le formulaire de contact sur notre site.' },
  { q: 'Les prix sont-ils négociables ?', a: 'Certains prix peuvent faire l\'objet d\'une négociation. N\'hésitez pas à nous contacter pour discuter de la meilleure offre possible.' },
];

function FaqItem({ q, a }: { q: string; a: string }) {
  const [open, setOpen] = useState(false);
  return (
    <div className={`border rounded-xl transition-all duration-200 ${open ? 'border-primary-300 shadow-md' : 'border-gray-200'}`}>
      <button onClick={() => setOpen(!open)} className="w-full flex items-center justify-between p-5 text-right gap-4">
        <span className="font-semibold text-dark text-sm text-right">{q}</span>
        <ChevronDown size={18} className={`text-primary-500 flex-shrink-0 transition-transform duration-200 ${open ? 'rotate-180' : ''}`} />
      </button>
      {open && <div className="px-5 pb-5 text-gray-600 text-sm leading-relaxed">{a}</div>}
    </div>
  );
}

export default function FaqPage() {
  return (
    <div className="pt-20">
      <div className="bg-dark py-20 text-center">
        <span className="text-primary-400 text-sm font-semibold uppercase tracking-wider">Centre d&apos;aide</span>
        <h1 className="font-heading font-black text-5xl text-white mt-3 mb-4">Questions Fréquentes</h1>
        <p className="text-gray-300 text-xl">Trouvez rapidement les réponses à vos questions.</p>
      </div>

      <section className="py-20 bg-gray-50">
        <div className="max-w-3xl mx-auto px-4">
          <div className="space-y-3">
            {faqs.map((f, i) => <FaqItem key={i} q={f.q} a={f.a} />)}
          </div>

          <div className="mt-12 text-center bg-white rounded-2xl p-8 shadow-card">
            <h3 className="font-heading font-bold text-xl text-dark mb-3">Vous n&apos;avez pas trouvé votre réponse ?</h3>
            <p className="text-gray-500 mb-6">Notre équipe est disponible pour vous aider.</p>
            <a href="/contact" className="btn-primary inline-block">Contactez-nous</a>
          </div>
        </div>
      </section>
    </div>
  );
}
