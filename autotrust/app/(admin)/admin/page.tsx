import { prisma } from '@/lib/prisma';
import AdminHeader from '@/components/admin/AdminHeader';
import DashboardStats from '@/components/admin/DashboardStats';
import { relativeTime, formatPrice, leadStatusLabel } from '@/lib/utils';
import Link from 'next/link';
import Image from 'next/image';
import { Car, MessageSquare, ChevronRight } from 'lucide-react';

export default async function AdminDashboard() {
  const [totalCars, availableCars, totalLeads, newLeads, totalViews, soldCars, recentLeads, recentCars] = await Promise.all([
    prisma.car.count(),
    prisma.car.count({ where: { status: 'AVAILABLE' } }),
    prisma.lead.count(),
    prisma.lead.count({ where: { status: 'NEW' } }),
    prisma.car.aggregate({ _sum: { viewCount: true } }).then(r => r._sum.viewCount ?? 0),
    prisma.car.count({ where: { status: 'SOLD', updatedAt: { gte: new Date(new Date().setDate(1)) } } }),
    prisma.lead.findMany({ take: 5, orderBy: { createdAt: 'desc' }, include: { car: { select: { make: true, model: true, year: true } } } }),
    prisma.car.findMany({ take: 5, orderBy: { createdAt: 'desc' }, include: { images: { where: { isPrimary: true }, take: 1 } } }),
  ]).catch(() => [0, 0, 0, 0, 0, 0, [], []]);

  const leadStatusColors: Record<string, string> = {
    NEW: 'bg-blue-100 text-blue-700',
    CONTACTED: 'bg-yellow-100 text-yellow-700',
    QUALIFIED: 'bg-purple-100 text-purple-700',
    NEGOTIATING: 'bg-orange-100 text-orange-700',
    CLOSED_WON: 'bg-green-100 text-green-700',
    CLOSED_LOST: 'bg-red-100 text-red-700',
  };

  return (
    <div>
      <AdminHeader title="Tableau de bord" />
      <div className="p-6 space-y-6">
        {/* Stats */}
        <DashboardStats stats={{ totalCars: totalCars as number, availableCars: availableCars as number, totalLeads: totalLeads as number, newLeads: newLeads as number, totalViews: totalViews as number, soldThisMonth: soldCars as number }} />

        <div className="grid lg:grid-cols-2 gap-6">
          {/* Recent Leads */}
          <div className="bg-white rounded-2xl shadow-card">
            <div className="flex items-center justify-between p-5 border-b border-gray-100">
              <h3 className="font-heading font-bold text-dark flex items-center gap-2">
                <MessageSquare size={18} className="text-primary-500" /> Derniers leads
              </h3>
              <Link href="/admin/leads" className="text-xs text-primary-500 font-semibold hover:underline flex items-center gap-1">
                Voir tout <ChevronRight size={12} />
              </Link>
            </div>
            <div className="divide-y divide-gray-50">
              {(recentLeads as { id: string; name: string; phone: string; status: string; createdAt: Date; car?: { make: string; model: string; year: number } | null }[]).map(lead => (
                <Link key={lead.id} href={`/admin/leads`} className="flex items-center gap-4 p-4 hover:bg-gray-50 transition-colors">
                  <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold text-sm flex-shrink-0">
                    {lead.name[0]}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-dark text-sm truncate">{lead.name}</p>
                    <p className="text-gray-400 text-xs">{lead.car ? `${lead.car.make} ${lead.car.model} ${lead.car.year}` : 'Sans véhicule'} • {relativeTime(lead.createdAt)}</p>
                  </div>
                  <span className={`text-xs font-semibold px-2 py-1 rounded-full whitespace-nowrap ${leadStatusColors[lead.status] ?? 'bg-gray-100 text-gray-600'}`}>
                    {leadStatusLabel(lead.status)}
                  </span>
                </Link>
              ))}
              {(recentLeads as unknown[]).length === 0 && <p className="text-gray-400 text-sm text-center py-8">Aucun lead</p>}
            </div>
          </div>

          {/* Recent Cars */}
          <div className="bg-white rounded-2xl shadow-card">
            <div className="flex items-center justify-between p-5 border-b border-gray-100">
              <h3 className="font-heading font-bold text-dark flex items-center gap-2">
                <Car size={18} className="text-primary-500" /> Derniers véhicules
              </h3>
              <Link href="/admin/cars" className="text-xs text-primary-500 font-semibold hover:underline flex items-center gap-1">
                Voir tout <ChevronRight size={12} />
              </Link>
            </div>
            <div className="divide-y divide-gray-50">
              {(recentCars as { id: string; slug: string; make: string; model: string; year: number; price: number; status: string; images: { url: string }[] }[]).map(car => (
                <Link key={car.id} href={`/admin/cars`} className="flex items-center gap-4 p-4 hover:bg-gray-50 transition-colors">
                  <div className="w-14 h-10 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                    {car.images[0] ? <img src={car.images[0].url} alt="" className="w-full h-full object-cover" /> : <div className="w-full h-full flex items-center justify-center"><Car size={16} className="text-gray-300" /></div>}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-dark text-sm truncate">{car.make} {car.model} {car.year}</p>
                    <p className="text-primary-500 text-xs font-semibold">{formatPrice(car.price)}</p>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-full font-semibold ${car.status === 'AVAILABLE' ? 'badge-available' : car.status === 'SOLD' ? 'badge-sold' : 'badge-reserved'}`}>
                    {car.status === 'AVAILABLE' ? 'Dispo' : car.status === 'SOLD' ? 'Vendue' : 'Réservée'}
                  </span>
                </Link>
              ))}
              {(recentCars as unknown[]).length === 0 && <p className="text-gray-400 text-sm text-center py-8">Aucun véhicule</p>}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-white rounded-2xl shadow-card p-5">
          <h3 className="font-heading font-bold text-dark mb-4">Actions rapides</h3>
          <div className="flex flex-wrap gap-3">
            <Link href="/admin/cars/new" className="btn-primary text-sm px-5 py-2.5">+ Ajouter un véhicule</Link>
            <Link href="/admin/leads" className="btn-dark text-sm px-5 py-2.5">Gérer les leads</Link>
            <Link href="/cars" target="_blank" className="border border-gray-200 text-dark hover:border-primary-400 text-sm px-5 py-2.5 rounded-lg font-semibold transition-all">Voir le site →</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
