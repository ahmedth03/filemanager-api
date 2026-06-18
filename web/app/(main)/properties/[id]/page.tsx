'use client'
import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { MapPin, Bed, Bath, Maximize, Calendar, MessageCircle, ArrowRight, Star, Flag, CheckCircle } from 'lucide-react'
import { api, unwrap } from '@/lib/api'
import { getWilayaName, formatPrice, formatDate, formatRelativeTime, PROPERTY_TYPE_LABELS } from '@/lib/utils'
import { isLoggedIn } from '@/lib/auth'
import StarRating from '@/components/ui/StarRating'
import Spinner from '@/components/ui/Spinner'
import toast from 'react-hot-toast'

export default function PropertyDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const [property, setProperty] = useState<any>(null)
  const [reviews, setReviews] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [imgIdx, setImgIdx] = useState(0)

  useEffect(() => {
    Promise.all([
      api.get(`/listings/${id}`).then(r => setProperty(unwrap<any>(r))),
      api.get(`/reviews/listing/${id}?page=1&limit=10`).then(r => {
        const d = r.data?.data
        setReviews(Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : [])
      }),
    ]).catch(() => {}).finally(() => setLoading(false))
  }, [id])

  const handleContact = async () => {
    if (!isLoggedIn()) { router.push('/login'); return }
    try {
      const res = await api.post('/chat/rooms', { participantId: property.ownerId })
      const room = unwrap<any>(res)
      router.push(`/chat/${room.id}`)
    } catch {
      toast.error('تعذر فتح المحادثة')
    }
  }

  if (loading) return <div className="flex justify-center py-20"><Spinner /></div>
  if (!property) return <div className="text-center py-20 text-gray-500">العقار غير موجود</div>

  const images = property.images ?? []

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <Link href="/properties" className="flex items-center gap-2 text-gray-500 hover:text-primary mb-6 text-sm">
        <ArrowRight className="w-4 h-4" /> العودة إلى العقارات
      </Link>

      {/* Image gallery */}
      <div className="mb-6">
        {images.length > 0 ? (
          <div>
            <img src={images[imgIdx]} alt={property.title} className="w-full h-72 object-cover rounded-2xl" />
            {images.length > 1 && (
              <div className="flex gap-2 mt-2 overflow-x-auto">
                {images.map((img: string, i: number) => (
                  <img key={i} src={img} alt="" onClick={() => setImgIdx(i)} className={`w-16 h-16 object-cover rounded-lg cursor-pointer border-2 transition-all ${i === imgIdx ? 'border-primary' : 'border-transparent'}`} />
                ))}
              </div>
            )}
          </div>
        ) : (
          <div className="w-full h-72 bg-gradient-to-br from-gray-100 to-gray-200 rounded-2xl flex items-center justify-center text-6xl">🏠</div>
        )}
      </div>

      {/* Details */}
      <div className="card mb-6">
        <div className="flex items-start justify-between gap-4 flex-wrap">
          <div>
            <span className="badge bg-primary/10 text-primary text-sm mb-2 inline-block">{PROPERTY_TYPE_LABELS[property.propertyType] ?? property.propertyType}</span>
            <h1 className="text-2xl font-bold text-gray-800">{property.title}</h1>
            <p className="text-3xl font-bold text-primary mt-2">{formatPrice(property.price)} <span className="text-gray-400 text-base font-normal">/ شهر</span></p>
          </div>
          {property.isAvailable === false && (
            <span className="badge bg-red-100 text-red-600">غير متاح</span>
          )}
        </div>

        <div className="flex items-center gap-1.5 text-gray-600 mt-3">
          <MapPin className="w-4 h-4" />
          {property.city ? `${property.city}، ` : ''}{getWilayaName(property.wilaya)}
        </div>

        <div className="flex flex-wrap gap-4 mt-4 text-sm text-gray-600">
          {property.bedrooms != null && <span className="flex items-center gap-1.5 bg-gray-50 px-3 py-1.5 rounded-lg"><Bed className="w-4 h-4" />{property.bedrooms} غرف نوم</span>}
          {property.bathrooms != null && <span className="flex items-center gap-1.5 bg-gray-50 px-3 py-1.5 rounded-lg"><Bath className="w-4 h-4" />{property.bathrooms} حمام</span>}
          {property.area != null && <span className="flex items-center gap-1.5 bg-gray-50 px-3 py-1.5 rounded-lg"><Maximize className="w-4 h-4" />{property.area} م²</span>}
          {property.isFurnished && <span className="flex items-center gap-1.5 bg-green-50 text-green-700 px-3 py-1.5 rounded-lg"><CheckCircle className="w-4 h-4" />مفروش</span>}
        </div>

        {property.description && (
          <p className="text-gray-600 mt-4 leading-relaxed">{property.description}</p>
        )}

        <div className="flex gap-3 mt-6">
          <button onClick={handleContact} className="btn-primary flex items-center gap-2 flex-1 justify-center">
            <MessageCircle className="w-4 h-4" /> تواصل مع المالك
          </button>
          {isLoggedIn() && (
            <Link href={`/report?targetId=${property.id}&type=LISTING`} className="btn-outline flex items-center gap-2">
              <Flag className="w-4 h-4" /> إبلاغ
            </Link>
          )}
        </div>
      </div>

      {/* Reviews */}
      <div>
        <h2 className="text-xl font-bold text-gray-800 mb-4">التقييمات ({reviews.length})</h2>
        {reviews.length === 0 ? (
          <div className="card text-center text-gray-400 py-8">لا توجد تقييمات بعد</div>
        ) : (
          <div className="space-y-4">
            {reviews.map((r: any) => (
              <div key={r.id} className="card">
                <div className="flex items-start gap-3">
                  <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold">
                    {r.reviewer?.firstName?.[0]}{r.reviewer?.lastName?.[0]}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <span className="font-medium text-gray-800">{r.reviewer?.firstName} {r.reviewer?.lastName}</span>
                      <span className="text-xs text-gray-400">{formatRelativeTime(r.createdAt)}</span>
                    </div>
                    <StarRating value={r.rating} readonly size="sm" />
                    {r.comment && <p className="text-gray-600 text-sm mt-2">{r.comment}</p>}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
        {isLoggedIn() && (
          <div className="mt-4">
            <Link href={`/reviews/add?listingId=${property.id}`} className="btn-outline w-full text-center block">
              + أضف تقييماً
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
