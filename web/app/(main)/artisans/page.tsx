'use client'
import { useState, useEffect, useCallback } from 'react'
import { Search, Filter, SlidersHorizontal } from 'lucide-react'
import { api, unwrapPaginated } from '@/lib/api'
import { getWilayaName, WILAYA_NAMES } from '@/lib/utils'
import CraftsmanCard from '@/components/cards/CraftsmanCard'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'

const SPECIALTIES = ['الكل', 'سباكة', 'كهرباء', 'دهان', 'تبليط وسيراميك', 'نجارة', 'تكييف وتبريد', 'بناء وجدران', 'حدادة ولحام', 'تنظيف وصيانة', 'ألومنيوم وزجاج']

export default function ArtisansPage() {
  const [craftsmen, setCraftsmen] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [specialty, setSpecialty] = useState('الكل')
  const [wilaya, setWilaya] = useState('')
  const [page, setPage] = useState(1)
  const [meta, setMeta] = useState<any>({})

  const fetchCraftsmen = useCallback(async () => {
    setLoading(true)
    try {
      const params: any = { page, limit: 12 }
      if (search) params.search = search
      if (specialty !== 'الكل') params.specialty = specialty
      if (wilaya) params.wilaya = wilaya
      const res = await api.get('/craftsmen', { params })
      const { data, meta } = unwrapPaginated<any>(res)
      setCraftsmen(data)
      setMeta(meta)
    } catch (e) {
      setCraftsmen([])
    } finally {
      setLoading(false)
    }
  }, [search, specialty, wilaya, page])

  useEffect(() => { fetchCraftsmen() }, [fetchCraftsmen])

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">الحرفيون</h1>

      {/* Search + Filters */}
      <div className="flex flex-col gap-4 mb-6">
        <div className="relative">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            className="input pr-10"
            placeholder="ابحث عن حرفي..."
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1) }}
          />
        </div>
        <div className="flex gap-3 flex-wrap items-center">
          <select className="input w-auto" value={wilaya} onChange={e => { setWilaya(e.target.value); setPage(1) }}>
            <option value="">كل الولايات</option>
            {Object.entries(WILAYA_NAMES).map(([code, name]) => (
              <option key={code} value={code}>{name}</option>
            ))}
          </select>
        </div>
        {/* Specialty pills */}
        <div className="flex gap-2 flex-wrap">
          {SPECIALTIES.map(s => (
            <button
              key={s}
              onClick={() => { setSpecialty(s); setPage(1) }}
              className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${specialty === s ? 'bg-primary text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {/* Results */}
      {loading ? (
        <div className="flex justify-center py-20"><Spinner /></div>
      ) : craftsmen.length === 0 ? (
        <EmptyState title="لا يوجد حرفيون" description="جرب تغيير معايير البحث" />
      ) : (
        <>
          <p className="text-sm text-gray-500 mb-4">تم العثور على {meta.total ?? craftsmen.length} حرفي</p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {craftsmen.map(c => <CraftsmanCard key={c.id} craftsman={c} />)}
          </div>
          {/* Pagination */}
          {meta.totalPages > 1 && (
            <div className="flex justify-center gap-2 mt-8">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-outline px-4 py-2 disabled:opacity-40">السابق</button>
              <span className="flex items-center px-4 text-sm text-gray-600">صفحة {page} من {meta.totalPages}</span>
              <button onClick={() => setPage(p => p + 1)} disabled={page >= meta.totalPages} className="btn-outline px-4 py-2 disabled:opacity-40">التالي</button>
            </div>
          )}
        </>
      )}
    </div>
  )
}
