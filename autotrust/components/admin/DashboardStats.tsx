import { Car, MessageSquare, Eye, TrendingUp, ArrowUpRight, ArrowDownRight } from 'lucide-react';

interface Props {
  stats: {
    totalCars: number;
    availableCars: number;
    totalLeads: number;
    newLeads: number;
    totalViews: number;
    soldThisMonth: number;
  };
}

export default function DashboardStats({ stats }: Props) {
  const cards = [
    {
      title: 'Total Véhicules',
      value: stats.totalCars,
      sub: `${stats.availableCars} disponibles`,
      icon: Car,
      color: 'bg-blue-50 text-blue-600',
      trend: '+12%',
      up: true,
    },
    {
      title: 'Nouveaux Leads',
      value: stats.newLeads,
      sub: `${stats.totalLeads} au total`,
      icon: MessageSquare,
      color: 'bg-red-50 text-red-600',
      trend: '+8%',
      up: true,
    },
    {
      title: 'Vues Totales',
      value: stats.totalViews.toLocaleString(),
      sub: 'ce mois-ci',
      icon: Eye,
      color: 'bg-purple-50 text-purple-600',
      trend: '+23%',
      up: true,
    },
    {
      title: 'Vendues ce mois',
      value: stats.soldThisMonth,
      sub: 'véhicules vendus',
      icon: TrendingUp,
      color: 'bg-green-50 text-green-600',
      trend: '-3%',
      up: false,
    },
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5">
      {cards.map((c, i) => (
        <div key={i} className="bg-white rounded-2xl p-5 shadow-card">
          <div className="flex items-start justify-between mb-4">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${c.color}`}>
              <c.icon size={20} />
            </div>
            <span className={`flex items-center gap-1 text-xs font-semibold ${c.up ? 'text-green-600' : 'text-red-500'}`}>
              {c.up ? <ArrowUpRight size={14} /> : <ArrowDownRight size={14} />}
              {c.trend}
            </span>
          </div>
          <p className="font-heading font-black text-3xl text-dark">{c.value}</p>
          <p className="text-dark text-sm font-semibold mt-1">{c.title}</p>
          <p className="text-gray-400 text-xs mt-0.5">{c.sub}</p>
        </div>
      ))}
    </div>
  );
}
