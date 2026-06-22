'use client';
import { useState, useEffect } from 'react';
import AdminHeader from '@/components/admin/AdminHeader';
import { relativeTime, leadStatusLabel } from '@/lib/utils';
import { Phone, Mail, MessageSquare, ChevronDown, Loader2 } from 'lucide-react';
import { Lead } from '@/types';

const statusColors: Record<string, string> = {
  NEW: 'bg-blue-100 text-blue-700',
  CONTACTED: 'bg-yellow-100 text-yellow-700',
  QUALIFIED: 'bg-purple-100 text-purple-700',
  NEGOTIATING: 'bg-orange-100 text-orange-700',
  CLOSED_WON: 'bg-green-100 text-green-700',
  CLOSED_LOST: 'bg-red-100 text-red-700',
};

const statuses = ['NEW', 'CONTACTED', 'QUALIFIED', 'NEGOTIATING', 'CLOSED_WON', 'CLOSED_LOST'];

export default function AdminLeadsPage() {
  const [leads,  setLeads]  = useState<Lead[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('');
  const [selected, setSelected] = useState<Lead | null>(null);

  useEffect(() => {
    fetch('/api/leads').then(r => r.json()).then(d => { setLeads(d.data ?? []); setLoading(false); }).catch(() => setLoading(false));
  }, []);

  async function updateStatus(id: string, status: string) {
    await fetch(`/api/leads/${id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ status }) });
    setLeads(prev => prev.map(l => l.id === id ? { ...l, status: status as Lead['status'] } : l));
  }

  const filtered = filter ? leads.filter(l => l.status === filter) : leads;

  return (
    <div>
      <AdminHeader title="Gestion des leads" />
      <div className="p-6">
        {/* Filter */}
        <div className="flex gap-2 mb-6 flex-wrap">
          <button onClick={() => setFilter('')} className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${!filter ? 'bg-dark text-white' : 'bg-white text-gray-600 border border-gray-200 hover:border-gray-300'}`}>
            Tous ({leads.length})
          </button>
          {statuses.map(s => {
            const count = leads.filter(l => l.status === s).length;
            return (
              <button key={s} onClick={() => setFilter(s)} className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${filter === s ? 'bg-dark text-white' : 'bg-white text-gray-600 border border-gray-200 hover:border-gray-300'}`}>
                {leadStatusLabel(s)} ({count})
              </button>
            );
          })}
        </div>

        <div className="grid lg:grid-cols-3 gap-6">
          {/* Leads list */}
          <div className="lg:col-span-2 bg-white rounded-2xl shadow-card overflow-hidden">
            {loading ? (
              <div className="flex items-center justify-center py-16"><Loader2 size={24} className="animate-spin text-primary-500" /></div>
            ) : filtered.length === 0 ? (
              <div className="text-center py-16 text-gray-400">Aucun lead</div>
            ) : (
              <div className="divide-y divide-gray-50">
                {filtered.map(lead => (
                  <div key={lead.id} onClick={() => setSelected(lead)} className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors ${selected?.id === lead.id ? 'bg-primary-50 border-r-2 border-primary-500' : ''}`}>
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-bold text-sm flex-shrink-0">
                          {lead.name[0]}
                        </div>
                        <div>
                          <p className="font-semibold text-dark text-sm">{lead.name}</p>
                          <p className="text-gray-400 text-xs">{lead.phone} • {relativeTime(lead.createdAt)}</p>
                          {lead.car && <p className="text-xs text-primary-500 mt-0.5">{(lead.car as { make: string; model: string; year: number }).make} {(lead.car as { make: string; model: string; year: number }).model} {(lead.car as { make: string; model: string; year: number }).year}</p>}
                        </div>
                      </div>
                      <div className="flex flex-col items-end gap-2">
                        <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${statusColors[lead.status]}`}>{leadStatusLabel(lead.status)}</span>
                        <span className="text-xs text-gray-400">{lead.source}</span>
                      </div>
                    </div>
                    {lead.message && <p className="text-gray-500 text-xs mt-2 pl-12 truncate">{lead.message}</p>}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Detail panel */}
          <div>
            {selected ? (
              <div className="bg-white rounded-2xl shadow-card p-5 sticky top-6">
                <div className="flex items-center gap-3 mb-5 pb-5 border-b border-gray-100">
                  <div className="w-12 h-12 bg-primary-500 rounded-full flex items-center justify-center text-white font-bold text-lg">
                    {selected.name[0]}
                  </div>
                  <div>
                    <p className="font-heading font-bold text-dark">{selected.name}</p>
                    <p className="text-gray-400 text-sm">{relativeTime(selected.createdAt)}</p>
                  </div>
                </div>

                <div className="space-y-4 mb-6">
                  <a href={`tel:${selected.phone}`} className="flex items-center gap-3 text-sm text-dark hover:text-primary-500 transition-colors">
                    <Phone size={16} className="text-primary-500" /> {selected.phone}
                  </a>
                  {selected.email && (
                    <a href={`mailto:${selected.email}`} className="flex items-center gap-3 text-sm text-dark hover:text-primary-500 transition-colors">
                      <Mail size={16} className="text-primary-500" /> {selected.email}
                    </a>
                  )}
                  {selected.message && (
                    <div className="flex items-start gap-3 text-sm text-gray-600">
                      <MessageSquare size={16} className="text-primary-500 mt-0.5" /> {selected.message}
                    </div>
                  )}
                </div>

                {/* Status update */}
                <div>
                  <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">Changer le statut</label>
                  <div className="relative">
                    <select value={selected.status} onChange={e => { updateStatus(selected.id, e.target.value); setSelected(prev => prev ? { ...prev, status: e.target.value as Lead['status'] } : null); }} className="w-full appearance-none bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-primary-500 pr-8">
                      {statuses.map(s => <option key={s} value={s}>{leadStatusLabel(s)}</option>)}
                    </select>
                    <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" />
                  </div>
                </div>

                <div className="mt-4 grid grid-cols-2 gap-2">
                  <a href={`tel:${selected.phone}`} className="flex items-center justify-center gap-2 py-2.5 bg-gray-50 hover:bg-gray-100 rounded-xl text-sm font-medium transition-colors">
                    <Phone size={14} /> Appeler
                  </a>
                  <a href={`https://wa.me/${selected.phone.replace(/\D/g, '')}?text=Bonjour ${selected.name}, je vous contacte de la part d'AutoTrust.`} target="_blank" rel="noopener noreferrer" className="flex items-center justify-center gap-2 py-2.5 bg-green-50 hover:bg-green-100 text-green-700 rounded-xl text-sm font-medium transition-colors">
                    <MessageSquare size={14} /> WhatsApp
                  </a>
                </div>
              </div>
            ) : (
              <div className="bg-white rounded-2xl shadow-card p-8 text-center text-gray-400">
                <MessageSquare size={32} className="mx-auto mb-3 text-gray-200" />
                <p className="text-sm">Sélectionnez un lead pour voir les détails</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
