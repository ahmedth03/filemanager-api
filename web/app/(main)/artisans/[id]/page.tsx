'use client'
import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { MapPin, Star, Hammer, Phone, MessageCircle, Calendar, ArrowRight, Flag } from 'lucide-react'
import { api, unwrap } from '@/lib/api'
import { getWilayaName, formatDate, formatRelativeTime } from '@/lib/utils'
import { getUser, isLoggedIn } from '@/lib/auth'
import StarRating from '@/components/ui/StarRating'
import Spinner from '@/components/ui/Spinner'
import toast from 'react-hot-toast'
import Link from 'next/link'

export default function CraftsmanDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const [craftsman, setCraftsman] = useState<any>(null)
  const [reviews, setReviews] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.get(`/craftsmen/${id}`).then(r => setCraftsman(unwrap<any>(r))),
      api.get(`/reviews/craftsman/${id}?page=1&limit=10`).then(r => {
        const d = r.data?.data
        setReviews(Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : [])
      }),
    ]).catch(() => {}).finally(() => setLoading(false))
  }, [id])

  const handleContact = async () => {
    if (!isLoggedIn()) { router.push('/login'); return }
    try {
      const res = await api.post('/chat/rooms', { participantId: craftsman.userId })
      const room = unwrap<any>(res)
      router.push(`/chat/${room.id}`)
    } catch {
      toast.error('تعذر فتح المحادثة')
    }
  }

  if (loading) return <div className="flex justify-center py-20"><Spinner /></div>
  if (!craftsman) return <div className="text-center py-20 text-gray-500">الحرفي غير موجود</div>

  const name = `${craftsman.user.firstName} ${craftsman.user.lastName}`

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <Link href="/artisans" className="flex items-center gap-2 text-gray-500 hover:text-primary mb-6 text-sm">
        <ArrowRight className="w-4 h-4" /> العودة إلى الحرفيون
      </Link>

      {/* Profile header */}
      <div className="card mb-6">
        <div className="flex flex-col sm:flex-row items-start gap-6">
          {craftsman.user.avatarUrl ? (
            <img src={craftsman.user.avatarUrl} alt={name} className="w-24 h-24 rounded-full object-cover" />
          ) : (
            <div className="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold text-3xl">
              {craftsman.user.firstName[0]}{craftsman.user.lastName[0]}
            </div>
          )}
          <div className="flex-1">
            <div className="flex items-start justify-between gap-4 flex-wrap">
              <div>
                <h1 className="text-2xl font-bold text-gray-800">{name}</h1>
                <div className="flex items-center gap-2 mt-1">
                  <Hammer className="w-4 h-4 text-primary" />
                  <span className="text-primary font-medium">{craftsman.specialty?.name}</span>
                </div>
              </div>
              <span className={`badge ${craftsman.isAvailable ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                {craftsman.isAvailable ? '✓ متاح الآن' : 'مشغول'}
              </span>
            </div>

            <div className="flex flex-wrap gap-4 mt-4 text-sm text-gray-600">
              <span className="flex items-center gap-1.5">
                <MapPin className="w-4 h-4" />
                {craftsman.city ? `${craftsman.city}، ` : ''}{getWilayaName(craftsman.wilaya)}
              </span>
              <span className="flex items-center gap-1.5">
                <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
                {craftsman.rating?.toFixed(1) ?? '0.0'} ({craftsman.reviewCount ?? 0} تقييم)
              </span>
              {craftsman.yearsOfExperience && (
                <span className="flex items-center gap-1.5">
                  <Calendar className="w-4 h-4" />
                  {craftsman.yearsOfExperience} سنوات خبرة
                </span>
              )}
            </div>

            {craftsman.bio && <p className="text-gray-600 mt-4 leading-relaxed">{craftsman.bio}</p>}
          </div>
        </div>

        <div className="flex gap-3 mt-6">
          <button onClick={handleContact} className="btn-primary flex items-center gap-2 flex-1 justify-center">
            <MessageCircle className="w-4 h-4" /> تواصل مع الحرفي
          </button>
          {isLoggedIn() && (
            <Link href={`/report?targetId=${craftsman.userId}&type=USER`} className="btn-outline flex items-center gap-2">
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
            <Link href={`/reviews/add?craftsmanId=${craftsman.id}`} className="btn-outline w-full text-center block">
              + أضف تقييماً
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}
