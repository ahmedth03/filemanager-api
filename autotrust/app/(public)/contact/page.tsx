import type { Metadata } from 'next';
import { Phone, Mail, MapPin, Clock } from 'lucide-react';
import ContactForm from '@/components/public/ContactForm';

export const metadata: Metadata = {
  title: 'Contactez-nous',
  description: 'Contactez l\'équipe AutoTrust pour toute question sur nos véhicules, financement ou service après-vente.',
};

export default function ContactPage() {
  return (
    <div className="pt-20">
      <div className="bg-dark py-20 text-center">
        <span className="text-primary-400 text-sm font-semibold uppercase tracking-wider">Nous joindre</span>
        <h1 className="font-heading font-black text-5xl text-white mt-3 mb-4">Contactez-nous</h1>
        <p className="text-gray-300 text-xl">Notre équipe est disponible pour répondre à toutes vos questions.</p>
      </div>

      <section className="py-16">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-5 gap-12">
            {/* Info */}
            <div className="lg:col-span-2 space-y-8">
              <div>
                <h2 className="font-heading font-bold text-2xl text-dark mb-6">Informations de contact</h2>
                <div className="space-y-5">
                  {[
                    { icon: Phone,  title: 'Téléphone',          value: '+213 555 123 456' },
                    { icon: Mail,   title: 'Email',              value: 'contact@autotrust.dz' },
                    { icon: MapPin, title: 'Adresse',            value: 'Alger, Algérie' },
                    { icon: Clock,  title: 'Heures d\'ouverture', value: 'Sam–Jeu: 8h30 – 18h00' },
                  ].map(({ icon: Icon, title, value }) => (
                    <div key={title} className="flex items-start gap-4">
                      <div className="w-11 h-11 bg-primary-50 rounded-xl flex items-center justify-center flex-shrink-0">
                        <Icon size={18} className="text-primary-500" />
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 mb-0.5">{title}</p>
                        <p className="font-semibold text-dark">{value}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Map placeholder */}
              <div className="bg-gray-100 rounded-2xl aspect-video flex items-center justify-center text-gray-400 overflow-hidden">
                <div className="text-center">
                  <MapPin size={40} className="mx-auto text-gray-300 mb-2" />
                  <p className="text-sm">Alger, Algérie</p>
                </div>
              </div>
            </div>

            {/* Form */}
            <div className="lg:col-span-3 bg-white rounded-2xl p-8 shadow-card">
              <h2 className="font-heading font-bold text-2xl text-dark mb-6">Envoyer un message</h2>
              <ContactForm />
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
