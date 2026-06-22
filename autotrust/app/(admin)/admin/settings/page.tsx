'use client';
import { useState, useEffect } from 'react';
import AdminHeader from '@/components/admin/AdminHeader';
import { Save, Loader2, CheckCircle } from 'lucide-react';

interface Setting { key: string; value: string; description?: string; }

const settingLabels: Record<string, string> = {
  site_name: 'Nom du site',
  phone: 'Téléphone',
  email: 'Email de contact',
  address: 'Adresse',
  whatsapp: 'Numéro WhatsApp',
  facebook: 'Facebook URL',
  instagram: 'Instagram URL',
  financing_rate: 'Taux de financement (%)',
  financing_max_months: 'Durée max financement (mois)',
};

export default function AdminSettingsPage() {
  const [settings, setSettings] = useState<Setting[]>([]);
  const [loading,  setLoading]  = useState(true);
  const [saving,   setSaving]   = useState(false);
  const [saved,    setSaved]    = useState(false);

  useEffect(() => {
    fetch('/api/settings').then(r => r.json()).then(d => { setSettings(d.data ?? []); setLoading(false); });
  }, []);

  function updateValue(key: string, value: string) {
    setSettings(prev => prev.map(s => s.key === key ? { ...s, value } : s));
  }

  async function handleSave() {
    setSaving(true);
    await fetch('/api/settings', { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(settings) });
    setSaving(false);
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  }

  const input = 'w-full px-4 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 bg-gray-50';

  return (
    <div>
      <AdminHeader title="Paramètres du site" />
      <div className="p-6 max-w-2xl">
        {loading ? (
          <div className="flex items-center justify-center py-20"><Loader2 size={24} className="animate-spin text-primary-500" /></div>
        ) : (
          <div className="space-y-6">
            <div className="bg-white rounded-2xl shadow-card p-6">
              <h3 className="font-heading font-bold text-dark mb-5">Informations générales</h3>
              <div className="space-y-4">
                {settings.map(s => (
                  <div key={s.key}>
                    <label className="block text-sm font-semibold text-dark mb-1.5">{settingLabels[s.key] ?? s.key}</label>
                    <input value={s.value} onChange={e => updateValue(s.key, e.target.value)} className={input} />
                    {s.description && <p className="text-xs text-gray-400 mt-1">{s.description}</p>}
                  </div>
                ))}
              </div>
            </div>

            <div className="flex items-center gap-4">
              <button onClick={handleSave} disabled={saving} className="btn-primary flex items-center gap-2 px-6 py-3 disabled:opacity-60">
                {saving ? <Loader2 size={16} className="animate-spin" /> : saved ? <CheckCircle size={16} /> : <Save size={16} />}
                {saving ? 'Enregistrement...' : saved ? 'Enregistré !' : 'Enregistrer'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
