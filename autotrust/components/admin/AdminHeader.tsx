'use client';
import { useSession } from 'next-auth/react';
import { Bell, Search } from 'lucide-react';

export default function AdminHeader({ title }: { title: string }) {
  const { data: session } = useSession();

  return (
    <header className="bg-white border-b border-gray-100 px-6 py-4 flex items-center justify-between sticky top-0 z-10">
      <div>
        <h1 className="font-heading font-bold text-xl text-dark">{title}</h1>
      </div>
      <div className="flex items-center gap-4">
        <div className="relative hidden sm:block">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input placeholder="Rechercher..." className="pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 w-48 bg-gray-50" />
        </div>
        <button className="relative p-2 text-gray-500 hover:text-dark hover:bg-gray-100 rounded-lg transition-colors">
          <Bell size={18} />
          <span className="absolute top-1 right-1 w-2 h-2 bg-primary-500 rounded-full" />
        </button>
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-primary-500 rounded-full flex items-center justify-center text-white text-sm font-bold">
            {session?.user?.name?.[0] ?? 'A'}
          </div>
          <span className="text-sm font-medium text-dark hidden sm:block">{session?.user?.name ?? 'Admin'}</span>
        </div>
      </div>
    </header>
  );
}
