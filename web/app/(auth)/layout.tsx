'use client'
import Link from 'next/link'
export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary to-primary/80 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link href="/" className="inline-block">
            <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center mx-auto mb-3">
              <span className="text-3xl">🏠</span>
            </div>
            <h1 className="text-white text-2xl font-bold">حرفي دار</h1>
            <p className="text-white/70 text-sm mt-1">ابحث عن حرفيين • استأجر عقارات</p>
          </Link>
        </div>
        {children}
      </div>
    </div>
  )
}
