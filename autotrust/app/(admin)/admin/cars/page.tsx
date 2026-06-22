import { prisma } from '@/lib/prisma';
import AdminHeader from '@/components/admin/AdminHeader';
import Link from 'next/link';
import { formatPrice, formatMileage, conditionLabel, statusLabel } from '@/lib/utils';
import { Plus, Pencil, Eye, Trash2, Star } from 'lucide-react';

export default async function AdminCarsPage() {
  const cars = await prisma.car.findMany({
    orderBy: { createdAt: 'desc' },
    include: { images: { where: { isPrimary: true }, take: 1 }, _count: { select: { leads: true } } },
  }).catch(() => []);

  const statusColor: Record<string, string> = {
    AVAILABLE: 'badge-available', SOLD: 'badge-sold', RESERVED: 'badge-reserved', COMING_SOON: 'bg-gray-100 text-gray-600',
  };

  return (
    <div>
      <AdminHeader title="Gestion des véhicules" />
      <div className="p-6">
        <div className="flex items-center justify-between mb-6">
          <p className="text-gray-500 text-sm">{cars.length} véhicule{cars.length !== 1 ? 's' : ''}</p>
          <Link href="/admin/cars/new" className="btn-primary flex items-center gap-2 text-sm px-5 py-2.5">
            <Plus size={16} /> Ajouter un véhicule
          </Link>
        </div>

        <div className="bg-white rounded-2xl shadow-card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-100">
                  <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Véhicule</th>
                  <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Prix</th>
                  <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">État</th>
                  <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Statut</th>
                  <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Vues</th>
                  <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">Leads</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {cars.map(car => (
                  <tr key={car.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-12 h-9 rounded-lg overflow-hidden bg-gray-100 flex-shrink-0">
                          {car.images[0] ? <img src={car.images[0].url} alt="" className="w-full h-full object-cover" /> : null}
                        </div>
                        <div>
                          <p className="font-semibold text-dark flex items-center gap-1.5">
                            {car.make} {car.model} {car.year}
                            {car.featured && <Star size={12} fill="#E30613" className="text-primary-500" />}
                          </p>
                          <p className="text-gray-400 text-xs">{formatMileage(car.mileage)}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 font-semibold text-dark">{formatPrice(car.price)}</td>
                    <td className="px-4 py-3">
                      <span className={car.condition === 'NEW' ? 'badge-new' : 'badge-used'}>{conditionLabel(car.condition)}</span>
                    </td>
                    <td className="px-4 py-3">
                      <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${statusColor[car.status] ?? 'bg-gray-100 text-gray-600'}`}>
                        {statusLabel(car.status)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-gray-500">{car.viewCount.toLocaleString()}</td>
                    <td className="px-4 py-3 text-gray-500">{car._count.leads}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2 justify-end">
                        <Link href={`/cars/${car.slug}`} target="_blank" className="p-1.5 text-gray-400 hover:text-dark hover:bg-gray-100 rounded-lg transition-colors">
                          <Eye size={15} />
                        </Link>
                        <Link href={`/admin/cars/${car.id}/edit`} className="p-1.5 text-gray-400 hover:text-primary-500 hover:bg-primary-50 rounded-lg transition-colors">
                          <Pencil size={15} />
                        </Link>
                        <DeleteCarButton carId={car.id} />
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {cars.length === 0 && (
              <div className="text-center py-16">
                <p className="text-gray-400 mb-4">Aucun véhicule</p>
                <Link href="/admin/cars/new" className="btn-primary text-sm inline-block">Ajouter le premier véhicule</Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function DeleteCarButton({ carId }: { carId: string }) {
  return (
    <form action={`/api/cars/${carId}`} method="DELETE">
      <button type="submit" className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors" onClick={e => { if (!confirm('Supprimer ce véhicule ?')) e.preventDefault(); }}>
        <Trash2 size={15} />
      </button>
    </form>
  );
}
