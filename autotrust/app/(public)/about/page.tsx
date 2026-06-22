import type { Metadata } from 'next';
import Image from 'next/image';
import { Target, Eye, Heart, Users } from 'lucide-react';

export const metadata: Metadata = {
  title: 'Qui Sommes-Nous',
  description: 'Découvrez l\'histoire et la mission d\'AutoTrust, la plateforme N°1 de vente automobile en Algérie.',
};

export default function AboutPage() {
  return (
    <div className="pt-20">
      {/* Hero */}
      <div className="relative bg-dark min-h-64 flex items-center overflow-hidden">
        <div className="absolute inset-0 opacity-30">
          <Image src="https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?w=1600&q=60" alt="About" fill style={{ objectFit: 'cover' }} />
        </div>
        <div className="relative z-10 max-w-4xl mx-auto px-4 py-24 text-center">
          <span className="text-primary-400 text-sm font-semibold uppercase tracking-wider">Notre histoire</span>
          <h1 className="font-heading font-black text-5xl text-white mt-3">Qui Sommes-Nous ?</h1>
        </div>
      </div>

      {/* Mission */}
      <section className="py-20 bg-white">
        <div className="max-w-5xl mx-auto px-4">
          <div className="grid md:grid-cols-2 gap-16 items-center">
            <div>
              <span className="text-primary-500 text-sm font-semibold uppercase tracking-wider">Notre mission</span>
              <h2 className="section-title mt-2">Rendre l&apos;achat auto simple, transparent et sécurisé</h2>
              <p className="text-gray-600 leading-relaxed mb-4">
                AutoTrust est née d&apos;une vision simple : simplifier l&apos;achat et la vente de véhicules en Algérie. Fondée par des passionnés d&apos;automobile, notre plateforme connecte acheteurs et vendeurs dans un environnement sécurisé et transparent.
              </p>
              <p className="text-gray-600 leading-relaxed">
                Chaque véhicule sur AutoTrust est soigneusement inspecté et certifié par nos experts. Nous travaillons avec les meilleures banques algériennes pour offrir des solutions de financement adaptées à chaque profil.
              </p>
            </div>
            <div className="relative aspect-square rounded-2xl overflow-hidden">
              <Image src="https://images.unsplash.com/photo-1560179707-f14e90ef3623?w=800&q=80" alt="AutoTrust team" fill style={{ objectFit: 'cover' }} />
            </div>
          </div>
        </div>
      </section>

      {/* Values */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-5xl mx-auto px-4">
          <h2 className="section-title text-center mb-12">Nos valeurs</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { icon: Target, title: 'Excellence',     desc: 'Nous visons l\'excellence dans chaque service que nous offrons.' },
              { icon: Eye,    title: 'Transparence',   desc: 'Aucun coût caché, aucune mauvaise surprise. Tout est clair.' },
              { icon: Heart,  title: 'Passion',        desc: 'Nous sommes des passionnés d\'automobile à votre service.' },
              { icon: Users,  title: 'Confiance',      desc: 'Votre satisfaction et confiance sont notre priorité absolue.' },
            ].map(({ icon: Icon, title, desc }) => (
              <div key={title} className="bg-white rounded-2xl p-6 text-center shadow-card">
                <div className="w-12 h-12 bg-primary-50 rounded-xl flex items-center justify-center mx-auto mb-4">
                  <Icon size={22} className="text-primary-500" />
                </div>
                <h3 className="font-bold text-dark mb-2">{title}</h3>
                <p className="text-gray-500 text-sm">{desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Team */}
      <section className="py-20 bg-white">
        <div className="max-w-5xl mx-auto px-4 text-center">
          <h2 className="section-title mb-4">Notre équipe</h2>
          <p className="section-subtitle mx-auto mb-12">Des professionnels passionnés à votre service</p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
            {[
              { name: 'Ahmed Benlakhdar',  role: 'CEO & Fondateur' },
              { name: 'Sara Meziani',      role: 'Directrice Commerciale' },
              { name: 'Karim Hadj',        role: 'Expert Automobile' },
              { name: 'Leila Boudiaf',     role: 'Responsable Finance' },
            ].map(m => (
              <div key={m.name} className="text-center">
                <div className="w-20 h-20 bg-primary-500 rounded-2xl flex items-center justify-center text-white font-black text-2xl mx-auto mb-3">
                  {m.name[0]}
                </div>
                <p className="font-semibold text-dark text-sm">{m.name}</p>
                <p className="text-gray-400 text-xs">{m.role}</p>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  );
}
