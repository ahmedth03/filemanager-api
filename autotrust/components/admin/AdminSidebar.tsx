'use client';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname } from 'next/navigation';
import { signOut } from 'next-auth/react';
import {
  LayoutDashboard, Car, Users, MessageSquare, Settings,
  LogOut, ChevronRight, ExternalLink
} from 'lucide-react';

const nav = [
  { href: '/admin',          icon: LayoutDashboard, label: 'Tableau de bord' },
  { href: '/admin/cars',     icon: Car,             label: 'Véhicules' },
  { href: '/admin/leads',    icon: MessageSquare,   label: 'Leads' },
  { href: '/admin/users',    icon: Users,           label: 'Utilisateurs' },
  { href: '/admin/settings', icon: Settings,        label: 'Paramètres' },
];

export default function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-dark h-screen flex flex-col flex-shrink-0 sticky top-0">
      {/* Logo */}
      <div className="p-6 border-b border-white/10">
        <div className="relative w-32 h-9">
          <Image src="/images/logo.png" alt="AutoTrust" fill style={{ objectFit: 'contain', objectPosition: 'left' }} />
        </div>
        <p className="text-white/40 text-xs mt-1">Administration</p>
      </div>

      {/* Nav */}
      <nav className="flex-1 p-4 space-y-1">
        {nav.map(({ href, icon: Icon, label }) => {
          const active = href === '/admin' ? pathname === '/admin' : pathname.startsWith(href);
          return (
            <Link key={href} href={href} className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200 group ${active ? 'bg-primary-500 text-white' : 'text-white/60 hover:text-white hover:bg-white/8'}`}>
              <Icon size={18} />
              <span>{label}</span>
              {active && <ChevronRight size={14} className="ml-auto" />}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-white/10 space-y-2">
        <Link href="/" target="_blank" className="flex items-center gap-3 px-4 py-2.5 text-white/50 hover:text-white text-sm transition-colors rounded-xl hover:bg-white/5">
          <ExternalLink size={16} /> Voir le site
        </Link>
        <button onClick={() => signOut({ callbackUrl: '/auth/login' })} className="flex items-center gap-3 px-4 py-2.5 text-white/50 hover:text-red-400 text-sm transition-colors w-full rounded-xl hover:bg-white/5">
          <LogOut size={16} /> Déconnexion
        </button>
      </div>
    </aside>
  );
}
