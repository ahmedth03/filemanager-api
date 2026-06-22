import Link from 'next/link';
import Image from 'next/image';
import { Phone, Mail, MapPin, Facebook, Instagram, Linkedin } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-dark text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10">
          {/* Brand */}
          <div className="space-y-4">
            <div className="relative w-36 h-10">
              <Image src="/images/logo.png" alt="AutoTrust" fill style={{ objectFit: 'contain', objectPosition: 'left' }} />
            </div>
            <p className="text-gray-400 text-sm leading-relaxed">
              La plateforme N°1 de vente de voitures neuves et d&apos;occasion en Algérie. Drive With Confidence.
            </p>
            <div className="flex gap-3">
              {[
                { icon: Facebook,  href: '#' },
                { icon: Instagram, href: '#' },
                { icon: Linkedin,  href: '#' },
              ].map(({ icon: Icon, href }, i) => (
                <a key={i} href={href} className="w-9 h-9 bg-white/10 rounded-lg flex items-center justify-center hover:bg-primary-500 transition-colors duration-200">
                  <Icon size={16} />
                </a>
              ))}
            </div>
          </div>

          {/* Links */}
          <div>
            <h4 className="font-heading font-bold text-sm uppercase tracking-wider text-silver mb-5">Naviguer</h4>
            <ul className="space-y-3">
              {[['/', 'Accueil'], ['/cars', 'Nos Voitures'], ['/financing', 'Financement'], ['/about', 'Qui Sommes-Nous'], ['/faq', 'FAQ']].map(([href, label]) => (
                <li key={href}>
                  <Link href={href} className="text-gray-400 hover:text-white text-sm transition-colors">{label}</Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Services */}
          <div>
            <h4 className="font-heading font-bold text-sm uppercase tracking-wider text-silver mb-5">Services</h4>
            <ul className="space-y-3 text-gray-400 text-sm">
              <li>Voitures Neuves</li>
              <li>Voitures d&apos;Occasion</li>
              <li>Financement Auto</li>
              <li>Reprise Véhicule</li>
              <li>Service Après-Vente</li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="font-heading font-bold text-sm uppercase tracking-wider text-silver mb-5">Contact</h4>
            <ul className="space-y-4">
              <li className="flex items-start gap-3">
                <Phone size={16} className="text-primary-500 mt-0.5 flex-shrink-0" />
                <span className="text-gray-400 text-sm">+213 555 123 456</span>
              </li>
              <li className="flex items-start gap-3">
                <Mail size={16} className="text-primary-500 mt-0.5 flex-shrink-0" />
                <span className="text-gray-400 text-sm">contact@autotrust.dz</span>
              </li>
              <li className="flex items-start gap-3">
                <MapPin size={16} className="text-primary-500 mt-0.5 flex-shrink-0" />
                <span className="text-gray-400 text-sm">Alger, Algérie</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-white/10 mt-12 pt-8 flex flex-col sm:flex-row justify-between items-center gap-4 text-sm text-gray-500">
          <p>© {new Date().getFullYear()} AutoTrust. Tous droits réservés.</p>
          <div className="flex gap-6">
            <Link href="#" className="hover:text-white transition-colors">Confidentialité</Link>
            <Link href="#" className="hover:text-white transition-colors">CGU</Link>
            <Link href="/contact" className="hover:text-white transition-colors">Contact</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
