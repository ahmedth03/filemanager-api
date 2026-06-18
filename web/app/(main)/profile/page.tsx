'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Mail, Phone, Edit2, Save, X, LogOut, Loader2 } from 'lucide-react'
import { api, unwrap } from '@/lib/api'
import { getUser, clearAuth } from '@/lib/auth'
import toast from 'react-hot-toast'
import Spinner from '@/components/ui/Spinner'

export default function ProfilePage() {
  const router = useRouter()
  const [user, setUser] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({ firstName: '', lastName: '', phone: '' })

  useEffect(() => {
    const localUser = getUser()
    if (!localUser) { router.push('/login'); return }
    api.get('/auth/me').then(r => {
      const u = unwrap<any>(r)
      setUser(u)
      setForm({ firstName: u.firstName, lastName: u.lastName, phone: u.phone ?? '' })
    }).catch(() => {
      router.push('/login')
    }).finally(() => setLoading(false))
  }, [router])

  const handleSave = async () => {
    setSaving(true)
    try {
      await api.patch('/users/me', form)
      setUser((u: any) => ({ ...u, ...form }))
      setEditing(false)
      toast.success('تم حفظ التغييرات')
    } catch {
      toast.error('فشل الحفظ')
    } finally {
      setSaving(false)
    }
  }

  const handleLogout = () => {
    clearAuth()
    toast.success('تم تسجيل الخروج')
    router.push('/')
  }

  if (loading) return <div className="flex justify-center py-20"><Spinner /></div>
  if (!user) return null

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6">الملف الشخصي</h1>

      <div className="card mb-4">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-20 h-20 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold text-2xl">
            {user.firstName?.[0]}{user.lastName?.[0]}
          </div>
          <div>
            <h2 className="text-xl font-bold text-gray-800">{user.firstName} {user.lastName}</h2>
            <p className="text-sm text-gray-500">
              {user.role === 'CRAFTSMAN' ? '🔧 حرفي' : user.role === 'ADMIN' ? '👑 مدير' : '👤 مستخدم'}
            </p>
          </div>
          {!editing && (
            <button onClick={() => setEditing(true)} className="mr-auto btn-outline flex items-center gap-2 text-sm">
              <Edit2 className="w-4 h-4" /> تعديل
            </button>
          )}
        </div>

        {editing ? (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">الاسم الأول</label>
                <input className="input" value={form.firstName} onChange={e => setForm(f => ({ ...f, firstName: e.target.value }))} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">اسم العائلة</label>
                <input className="input" value={form.lastName} onChange={e => setForm(f => ({ ...f, lastName: e.target.value }))} />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">رقم الهاتف</label>
              <input className="input" value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))} dir="ltr" />
            </div>
            <div className="flex gap-3">
              <button onClick={handleSave} disabled={saving} className="btn-primary flex items-center gap-2">
                {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />} حفظ
              </button>
              <button onClick={() => setEditing(false)} className="btn-outline flex items-center gap-2">
                <X className="w-4 h-4" /> إلغاء
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-3">
            <div className="flex items-center gap-3 text-gray-700">
              <Mail className="w-5 h-5 text-gray-400" />
              <span dir="ltr">{user.email}</span>
            </div>
            {user.phone && (
              <div className="flex items-center gap-3 text-gray-700">
                <Phone className="w-5 h-5 text-gray-400" />
                <span dir="ltr">{user.phone}</span>
              </div>
            )}
          </div>
        )}
      </div>

      <button onClick={handleLogout} className="w-full flex items-center justify-center gap-2 py-3 px-4 bg-red-50 text-red-600 rounded-xl hover:bg-red-100 transition-colors font-medium">
        <LogOut className="w-5 h-5" /> تسجيل الخروج
      </button>
    </div>
  )
}
