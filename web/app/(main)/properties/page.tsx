'use client'
import { useState, useEffect, useCallback } from 'react'
import { Search } from 'lucide-react'
import { api, unwrapPaginated } from '@/lib/api'
import { WILAYA_NAMES, PROPERTY_TYPE_LABELS } from '@/lib/utils'
import PropertyCard from '@/components/cards/PropertyCard'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'

const TYPES = ['الكل', ...Object.keys(PROPERTY_TYPE_LABELS)]

export default function PropertiesPage() {
  const [properties, setProperties] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [propertyType, setPropertyType] = useState('الكل')
  const [wilaya, setWilaya] = useState('')
  const [page, setPage] = useState(1)
  const [meta, setMeta] = useState<any>({})

  const fetchProperties = useCallback(async () => {
    setLoading(true)
    try {
      const params: any = { page, limit: 12 }
      if (search) params.search = search
      if (propertyType !== 'الكل') params.propertyType = propertyType
      if (wilaya) params.wilaya = wilaya
      const res = await api.get('/listings', { params })
      const { data, meta } = unwrapPaginated<any>(res)
      setProperties(data)
      setMeta(meta)
    } catch {
      setProperties([])
    } finally {
      setLoading(false)
    }
  }, [search, propertyType, wilaya, page])

  useEffect(() => { fetchProperties() }, [fetchProperties])

  return (
    <div className="max-w-7xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">العقارات</h1>

      <div className="flex flex-col gap-4 mb-6">
        <div className="relative">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input className="input pr-10" placeholder="ابحث عن عقار..." value={search} onChange={e => { setSearch(e.target.value); setPage(1) }} />
        </div>
        <div className="flex gap-3 flex-wrap">
          <select className="input w-auto" value={wilaya} onChange={e => { setWilaya(e.target.value); setPage(1) }}>
            <option value="">كل الولايات</option>
            {Object.entries(WILAYA_NAMES).map(([code, name]) => (
              <option key={code} value={code}>{name}</option>
            ))}
          </select>
        </div>
        <div className="flex gap-2 flex-wrap">
          {TYPES.map(t => (
            <button key={t} onClick={() => { setPropertyType(t); setPage(1) }}
              className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${propertyType === t ? 'bg-accent text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
              {t === 'الكل' ? 'الكل' : (PROPERTY_TYPE_LABELS[t] ?? t)}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="flex justify-center py-20"><Spinner /></div>
      ) : properties.length === 0 ? (
        <EmptyState title="لا توجد عقارات" description="جرب تغيير معايير البحث" icon="🏠" />
      ) : (
        <>
          <p className="text-sm text-gray-500 mb-4">تم العثور على {meta.total ?? properties.length} عقار</p>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {properties.map(p => <PropertyCard key={p.id} property={p} />)}
          </div>
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
