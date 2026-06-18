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
  email: z.string().email('بريد إلكتروني غير صالح'),
  password: z.string().min(6, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
})
type FormData = z.infer<typeof schema>

export default function LoginPage() {
  const router = useRouter()
  const [showPass, setShowPass] = useState(false)
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({ resolver: zodResolver(schema) })

  const onSubmit = async (data: FormData) => {
    try {
      const res = await api.post('/auth/login', data)
      const { accessToken, refreshToken, user } = unwrap<any>(res)
      setAuth(accessToken, refreshToken, user)
      toast.success(`مرحباً ${user.firstName}!`)
      router.push('/')
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'بيانات الدخول غير صحيحة')
    }
  }

  return (
    <div className="card">
      <h2 className="text-xl font-bold text-gray-800 mb-6 text-center">تسجيل الدخول</h2>
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">البريد الإلكتروني</label>
          <input {...register('email')} type="email" className="input" placeholder="example@email.com" dir="ltr" />
          {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
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
        <button type="submit" disabled={isSubmitting} className="btn-primary w-full flex items-center justify-center gap-2">
          {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
          دخول
        </button>
      </form>
      <p className="text-center text-sm text-gray-500 mt-4">
        ليس لديك حساب؟{' '}
        <Link href="/register" className="text-primary font-medium hover:underline">سجّل الآن</Link>
      </p>
    </div>
  )
}
