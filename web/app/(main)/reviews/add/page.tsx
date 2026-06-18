'use client'
import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Loader2, Send } from 'lucide-react'
import { api } from '@/lib/api'
import { isLoggedIn } from '@/lib/auth'
import StarRating from '@/components/ui/StarRating'
import toast from 'react-hot-toast'

function AddReviewContent() {
  const router = useRouter()
  const params = useSearchParams()
  const craftsmanId = params.get('craftsmanId')
  const listingId = params.get('listingId')
  const [rating, setRating] = useState(0)
  const [comment, setComment] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async () => {
    if (!isLoggedIn()) { router.push('/login'); return }
    if (rating === 0) { toast.error('يرجى تحديد التقييم'); return }
    setSubmitting(true)
    try {
      await api.post('/reviews', {
        rating,
        ...(comment.trim() && { comment: comment.trim() }),
        ...(craftsmanId && { craftsmanId }),
        ...(listingId && { listingId }),
      })
      toast.success('تم إرسال التقييم بنجاح!')
      router.back()
    } catch (e: any) {
      toast.error(e.response?.data?.message || 'فشل إرسال التقييم')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="max-w-lg mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">إضافة تقييم</h1>
      <div className="card space-y-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">التقييم</label>
          <StarRating value={rating} onChange={setRating} size="lg" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            التعليق <span className="text-gray-400 font-normal">(اختياري)</span>
          </label>
          <textarea
            className="input min-h-[120px] resize-none"
            placeholder="شاركنا رأيك..."
            value={comment}
            onChange={e => setComment(e.target.value)}
          />
        </div>
        <button
          onClick={handleSubmit}
          disabled={submitting || rating === 0}
          className="btn-primary w-full flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
          إرسال التقييم
        </button>
      </div>
    </div>
  )
}

export default function AddReviewPage() {
  return (
    <Suspense fallback={<div className="flex justify-center py-20"><div className="w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin" /></div>}>
      <AddReviewContent />
    </Suspense>
  )
}
