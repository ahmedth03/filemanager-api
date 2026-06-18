'use client'
import Link from 'next/link'
import { useEffect, useState } from 'react'
import { Hammer, Building2, Star, ArrowLeft, Search } from 'lucide-react'
import { getUser, type User } from '@/lib/auth'

export default function HomePage() {
  const [user, setUser] = useState<User | null>(null)
  useEffect(() => { setUser(getUser()) }, [])

  return (
    <div>
      {/* Hero */}
      <section className="bg-gradient-to-br from-primary to-primary/80 text-white py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          {user ? (
            <h1 className="text-4xl font-bold mb-3">مرحباً، {user.firstName}! 👋</h1>
          ) : (
            <h1 className="text-4xl font-bold mb-3">حرفي دار</h1>
          )}
          <p className="text-white/80 text-lg mb-8">ابحث عن أفضل الحرفيين واستأجر أرقى العقارات في الجزائر</p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link href="/artisans" className="bg-white text-primary font-bold px-8 py-3 rounded-2xl hover:bg-white/90 transition-colors flex items-center justify-center gap-2">
              <Hammer className="w-5 h-5" />
              ابحث عن حرفي
            </Link>
            <Link href="/properties" className="bg-white/20 text-white font-bold px-8 py-3 rounded-2xl hover:bg-white/30 transition-colors flex items-center justify-center gap-2 border border-white/30">
              <Building2 className="w-5 h-5" />
              استأجر عقاراً
            </Link>
          </div>
        </div>
      </section>

      {/* Features */}
      <section className="py-16 px-4 max-w-7xl mx-auto">
        <h2 className="text-2xl font-bold text-center text-gray-800 mb-10">لماذا حرفي دار؟</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[
            { icon: '🔍', title: 'بحث سهل وسريع', desc: 'ابحث عن الحرفيين والعقارات حسب الولاية والتخصص' },
            { icon: '⭐', title: 'تقييمات حقيقية', desc: 'اقرأ تجارب المستخدمين الحقيقيين قبل اختيارك' },
            { icon: '💬', title: 'تواصل مباشر', desc: 'تحدّث مباشرة مع الحرفيين وأصحاب العقارات' },
          ].map((f, i) => (
            <div key={i} className="card text-center hover:shadow-md transition-shadow">
              <div className="text-4xl mb-3">{f.icon}</div>
              <h3 className="font-bold text-gray-800 mb-2">{f.title}</h3>
              <p className="text-gray-500 text-sm">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTAs */}
      <section className="bg-gray-50 py-16 px-4">
        <div className="max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-8">
          <Link href="/artisans" className="card hover:shadow-lg transition-shadow group">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center">
                <Hammer className="w-8 h-8 text-primary" />
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-gray-800">الحرفيون</h3>
                <p className="text-gray-500 text-sm">سباك، كهربائي، نجار وأكثر...</p>
              </div>
              <ArrowLeft className="w-5 h-5 text-gray-400 group-hover:text-primary transition-colors" />
            </div>
          </Link>
          <Link href="/properties" className="card hover:shadow-lg transition-shadow group">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 bg-accent/10 rounded-2xl flex items-center justify-center">
                <Building2 className="w-8 h-8 text-accent" />
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-bold text-gray-800">العقارات</h3>
                <p className="text-gray-500 text-sm">شقق، منازل، فيلات للإيجار</p>
              </div>
              <ArrowLeft className="w-5 h-5 text-gray-400 group-hover:text-accent transition-colors" />
            </div>
          </Link>
        </div>
      </section>
    </div>
  )
}
