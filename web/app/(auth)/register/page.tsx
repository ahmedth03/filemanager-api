'use client'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { Eye, EyeOff, Loader2 } from 'lucide-react'
import toast from 'react-hot-toast'
import { api, unwrap } from '@/lib/api'
import { setAuth } from '@/lib/auth'

const schema = z.object({
  firstName: z.string().min(2, 'الاسم الأول مطلوب'),
  lastName: z.string().min(2, 'اسم العائلة مطلوب'),
  email: z.string().email('بريد إلكتروني غير صالح'),
  phone: z.string().optional(),
  password: z.string().min(8, 'كلمة المرور 8 أحرف على الأقل'),
  role: z.enum(['USER', 'CRAFTSMAN']),
})
type FormData = z.infer<typeof schema>

export default function RegisterPage() {
  const router = useRouter()
  const [showPass, setShowPass] = useState(false)
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { role: 'USER' }
  })

  const onSubmit = async (data: FormData) => {
    try {
      const res = await api.post('/auth/register', data)
      const { accessToken, refreshToken, user } = unwrap<any>(res)
      setAuth(accessToken, refreshToken, user)
      toast.success('تم إنشاء الحساب بنجاح!')
      router.push('/')
    } catch (err: any) {
      const msg = err.response?.data?.message
      toast.error(Array.isArray(msg) ? msg[0] : (msg || 'حدث خطأ'))
    }
  }

  return (
    <div className="card">
      <h2 className="text-xl font-bold text-gray-800 mb-6 text-center">إنشاء حساب جديد</h2>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">الاسم الأول</label>
            <input {...register('firstName')} className="input" placeholder="أحمد" />
            {errors.firstName && <p className="text-red-500 text-xs mt-1">{errors.firstName.message}</p>}
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">اسم العائلة</label>
            <input {...register('lastName')} className="input" placeholder="محمد" />
            {errors.lastName && <p className="text-red-500 text-xs mt-1">{errors.lastName.message}</p>}
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">البريد الإلكتروني</label>
          <input {...register('email')} type="email" className="input" placeholder="example@email.com" dir="ltr" />
          {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">رقم الهاتف <span className="text-gray-400 font-normal">(اختياري)</span></label>
          <input {...register('phone')} type="tel" className="input" placeholder="0555 123 456" dir="ltr" />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">كلمة المرور</label>
          <div className="relative">
            <input {...register('password')} type={showPass ? 'text' : 'password'} className="input pl-10" placeholder="••••••••" />
            <button type="button" onClick={() => setShowPass(!showPass)} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
              {showPass ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
            </button>
          </div>
          {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">نوع الحساب</label>
          <div className="grid grid-cols-2 gap-2">
            <label className="flex items-center gap-2 border rounded-xl p-3 cursor-pointer has-[:checked]:border-primary has-[:checked]:bg-primary/5">
              <input {...register('role')} type="radio" value="USER" className="text-primary" />
              <span className="text-sm">👤 مستخدم</span>
            </label>
            <label className="flex items-center gap-2 border rounded-xl p-3 cursor-pointer has-[:checked]:border-primary has-[:checked]:bg-primary/5">
              <input {...register('role')} type="radio" value="CRAFTSMAN" className="text-primary" />
              <span className="text-sm">🔧 حرفي</span>
            </label>
          </div>
        </div>
        <button type="submit" disabled={isSubmitting} className="btn-primary w-full flex items-center justify-center gap-2">
          {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
          إنشاء الحساب
        </button>
      </form>
      <p className="text-center text-sm text-gray-500 mt-4">
        لديك حساب بالفعل؟{' '}
        <Link href="/login" className="text-primary font-medium hover:underline">سجّل دخولك</Link>
      </p>
    </div>
  )
}
