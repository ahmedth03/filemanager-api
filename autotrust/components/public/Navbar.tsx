'use client';
import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Menu, X, Phone } from 'lucide-react';

const links = [
  { href: '/cars',       label: 'Nos Voitures' },
  { href: '/financing',  label: 'Financement' },
  { href: '/about',      label: 'Qui Sommes-Nous' },
  { href: '/faq',        label: 'FAQ' },
  { href: '/contact',    label: 'Contact' },
];

export default function Navbar() {
  const [open,     setOpen]     = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handler = () => setScrolled(window.scrollY > 60);
    window.addEventListener('scroll', handler, { passive: true });
    return () => window.removeEventListener('scroll', handler);
  }, []);

  return (
    <header className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${scrolled ? 'bg-dark/95 backdrop-blur-md shadow-lg py-2' : 'bg-transparent py-4'}`}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between">
        {/* Logo */}
        <Link href="/" className="flex items-center gap-2 flex-shrink-0">
          <div className="relative w-40 h-12">
            <Image src="/images/logo.png" alt="AutoTrust" fill style={{ objectFit: 'contain', objectPosition: 'left' }} priority />
          </div>
        </Link>

        {/* Desktop Links */}
        <nav className="hidden md:flex items-center gap-1">
          {links.map(l => (
            <Link key={l.href} href={l.href} className="text-white/80 hover:text-white hover:bg-white/10 px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200">
              {l.label}
            </Link>
          ))}
        </nav>

        {/* CTA */}
        <div className="hidden md:flex items-center gap-3">
          <a href={`tel:${process.env.NEXT_PUBLIC_WHATSAPP ?? '0555123456'}`} className="flex items-center gap-2 text-white/80 hover:text-white text-sm font-medium transition-colors">
            <Phone size={16} className="text-primary-500" />
            <span>+213 555 123 456</span>
          </a>
          <Link href="/cars" className="btn-primary text-sm px-5 py-2.5">
            Voir les voitures
          </Link>
        </div>

        {/* Mobile hamburger */}
        <button onClick={() => setOpen(!open)} className="md:hidden text-white p-2 rounded-lg hover:bg-white/10 transition-colors">
          {open ? <X size={22} /> : <Menu size={22} />}
        </button>
      </div>

      {/* Mobile menu */}
      {open && (
        <div className="md:hidden bg-dark/95 backdrop-blur-md border-t border-white/10 px-4 pb-6 pt-2">
          {links.map(l => (
            <Link key={l.href} href={l.href} onClick={() => setOpen(false)} className="block text-white/80 hover:text-white py-3 text-sm font-medium border-b border-white/5">
              {l.label}
            </Link>
          ))}
          <div className="mt-4 flex flex-col gap-3">
            <a href="tel:+213555123456" className="flex items-center gap-2 text-white/80 text-sm">
              <Phone size={16} className="text-primary-500" /> +213 555 123 456
            </a>
            <Link href="/cars" onClick={() => setOpen(false)} className="btn-primary text-center text-sm">
              Voir les voitures
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
