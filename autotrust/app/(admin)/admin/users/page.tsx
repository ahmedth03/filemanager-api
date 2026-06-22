import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';
import { authOptions } from '@/lib/auth';
import { prisma } from '@/lib/prisma';
import AdminHeader from '@/components/admin/AdminHeader';
import { relativeTime } from '@/lib/utils';
import { Shield, User } from 'lucide-react';

export default async function AdminUsersPage() {
  const session = await getServerSession(authOptions);
  const userRole = (session?.user as { role?: string })?.role;
  if (userRole !== 'SUPER_ADMIN') redirect('/admin');

  const users = await prisma.user.findMany({ orderBy: { createdAt: 'desc' } }).catch(() => []);

  const roleColors: Record<string, string> = {
    SUPER_ADMIN: 'bg-red-100 text-red-700',
    ADMIN: 'bg-blue-100 text-blue-700',
    SALES_MANAGER: 'bg-purple-100 text-purple-700',
  };

  const roleLabels: Record<string, string> = {
    SUPER_ADMIN: 'Super Admin',
    ADMIN: 'Admin',
    SALES_MANAGER: 'Sales Manager',
  };

  return (
    <div>
      <AdminHeader title="Gestion des utilisateurs" />
      <div className="p-6">
        <div className="bg-white rounded-2xl shadow-card overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100">
                <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Utilisateur</th>
                <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Rôle</th>
                <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Statut</th>
                <th className="text-right px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Inscrit</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {users.map(user => (
                <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold text-sm flex-shrink-0">
                        {user.name?.[0] ?? <User size={14} />}
                      </div>
                      <div>
                        <p className="font-semibold text-dark">{user.name ?? '—'}</p>
                        <p className="text-gray-400 text-xs">{user.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-xs font-semibold px-2 py-1 rounded-full flex items-center gap-1 w-fit ${roleColors[user.role]}`}>
                      <Shield size={10} /> {roleLabels[user.role]}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${user.isActive ? 'badge-available' : 'badge-sold'}`}>
                      {user.isActive ? 'Actif' : 'Inactif'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-400 text-xs">{relativeTime(user.createdAt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          {users.length === 0 && <div className="text-center py-12 text-gray-400">Aucun utilisateur</div>}
        </div>
      </div>
    </div>
  );
}
