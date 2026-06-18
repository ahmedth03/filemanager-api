'use client'
import { useState, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { Loader2, Flag } from 'lucide-react'
import { api } from '@/lib/api'
import { isLoggedIn } from '@/lib/auth'
import toast from 'react-hot-toast'

const REASONS = ['محتوى غير لائق', 'احتيال أو نصب', 'بيانات مزيفة', 'سلوك مسيء', 'أخرى']

function ReportContent() {
  const router = useRouter()
  const params = useSearchParams()
  const targetId = params.get('targetId') ?? ''
  const type = params.get('type') ?? 'USER'
  const [reason, setReason] = useState('')
  const [description, setDescription] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleSubmit = async () => {
    if (!isLoggedIn()) { router.push('/login'); return }
    if (!reason) { toast.error('يرجى تحديد سبب البلاغ'); return }
    setSubmitting(true)
    try {
      await api.post('/reports', { targetId, type, reason, description })
      toast.success('تم إرسال البلاغ بنجاح')
      router.back()
    } catch {
      toast.error('فشل إرسال البلاغ')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="max-w-lg mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
        <Flag className="w-6 h-6 text-red-500" /> إرسال بلاغ
      </h1>
      <div className="card space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">سبب البلاغ</label>
          <select className="input" value={reason} onChange={e => setReason(e.target.value)}>
            <option value="">اختر السبب...</option>
            {REASONS.map(r => <option key={r} value={r}>{r}</option>)}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            تفاصيل إضافية <span className="text-gray-400 font-normal">(اختياري)</span>
          </label>
          <textarea
            className="input min-h-[100px] resize-none"
            placeholder="اشرح المشكلة..."
            value={description}
            onChange={e => setDescription(e.target.value)}
          />
        </div>
        <button
          onClick={handleSubmit}
          disabled={submitting || !reason}
          className="btn-primary w-full flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Flag className="w-4 h-4" />}
          إرسال البلاغ
        </button>
      </div>
    </div>
  )
}

export default function ReportPage() {
  return (
    <Suspense fallback={<div className="flex justify-center py-20"><div className="w-8 h-8 border-4 border-primary/20 border-t-primary rounded-full animate-spin" /></div>}>
      <ReportContent />
    </Suspense>
  )
}
