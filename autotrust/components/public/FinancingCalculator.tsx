'use client';
import { useState, useMemo } from 'react';
import { Calculator } from 'lucide-react';
import { formatPrice, calculateMonthlyPayment } from '@/lib/utils';

export default function FinancingCalculator({ defaultPrice = 3000000 }: { defaultPrice?: number }) {
  const [price,       setPrice]       = useState(defaultPrice);
  const [downPayment, setDownPayment] = useState(Math.floor(defaultPrice * 0.2));
  const [months,      setMonths]      = useState(36);
  const [rate,        setRate]        = useState(8.5);

  const monthly = useMemo(() => calculateMonthlyPayment(price, downPayment, months, rate), [price, downPayment, months, rate]);
  const total   = useMemo(() => monthly * months + downPayment, [monthly, months, downPayment]);
  const interest = useMemo(() => total - price, [total, price]);

  return (
    <div className="bg-white rounded-2xl shadow-card p-6 md:p-8">
      <div className="flex items-center gap-3 mb-6">
        <div className="w-10 h-10 bg-primary-50 rounded-xl flex items-center justify-center">
          <Calculator size={20} className="text-primary-500" />
        </div>
        <h3 className="font-heading font-bold text-xl text-dark">Calculateur de financement</h3>
      </div>

      <div className="grid md:grid-cols-2 gap-8">
        {/* Inputs */}
        <div className="space-y-5">
          <div>
            <label className="block text-sm font-semibold text-dark mb-2">Prix du véhicule</label>
            <input type="number" value={price} onChange={e => setPrice(Number(e.target.value))} className="input" min={500000} max={50000000} step={50000} />
            <p className="text-xs text-gray-400 mt-1">{formatPrice(price)}</p>
          </div>

          <div>
            <label className="block text-sm font-semibold text-dark mb-2">
              Apport initial — {Math.round((downPayment / price) * 100)}%
            </label>
            <input type="range" value={downPayment} onChange={e => setDownPayment(Number(e.target.value))} min={0} max={price * 0.8} step={50000} className="w-full accent-primary-500" />
            <div className="flex justify-between text-xs text-gray-400 mt-1">
              <span>0 DA</span>
              <span className="font-semibold text-dark">{formatPrice(downPayment)}</span>
              <span>{formatPrice(price * 0.8)}</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-dark mb-2">Durée — {months} mois</label>
            <input type="range" value={months} onChange={e => setMonths(Number(e.target.value))} min={6} max={60} step={6} className="w-full accent-primary-500" />
            <div className="flex justify-between text-xs text-gray-400 mt-1">
              <span>6 mois</span>
              <span className="font-semibold text-dark">{months} mois</span>
              <span>60 mois</span>
            </div>
          </div>

          <div>
            <label className="block text-sm font-semibold text-dark mb-2">Taux annuel — {rate}%</label>
            <input type="range" value={rate} onChange={e => setRate(Number(e.target.value))} min={4} max={20} step={0.5} className="w-full accent-primary-500" />
            <div className="flex justify-between text-xs text-gray-400 mt-1">
              <span>4%</span>
              <span className="font-semibold text-dark">{rate}%</span>
              <span>20%</span>
            </div>
          </div>
        </div>

        {/* Results */}
        <div className="bg-gray-50 rounded-xl p-6 space-y-4">
          <div className="text-center pb-4 border-b border-gray-200">
            <p className="text-gray-500 text-sm mb-1">Mensualité estimée</p>
            <p className="font-heading font-black text-4xl text-primary-500">{formatPrice(Math.round(monthly))}</p>
            <p className="text-gray-400 text-xs mt-1">/ mois pendant {months} mois</p>
          </div>

          <div className="space-y-3">
            {[
              ['Montant emprunté',   formatPrice(price - downPayment)],
              ['Coût total du crédit', formatPrice(Math.round(interest))],
              ['Montant total à payer', formatPrice(Math.round(total))],
            ].map(([label, value]) => (
              <div key={label} className="flex justify-between items-center text-sm">
                <span className="text-gray-500">{label}</span>
                <span className="font-semibold text-dark">{value}</span>
              </div>
            ))}
          </div>

          <p className="text-xs text-gray-400 border-t border-gray-200 pt-3">
            * Simulation non contractuelle. Sous réserve d&apos;acceptation.
          </p>

          <a href="/financing" className="btn-primary w-full text-center block text-sm">
            Demander un financement →
          </a>
        </div>
      </div>
    </div>
  );
}
