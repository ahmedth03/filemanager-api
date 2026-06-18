import Link from 'next/link'

export default function Footer() {
  return (
    <footer className="bg-primary text-white mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-1">
            <div className="flex items-center gap-2 text-xl font-bold mb-3">
              <span>🏠</span>
              <span>حرفي دار</span>
            </div>
            <p className="text-sm text-blue-200 leading-relaxed">
              منصة جزائرية تربط بين أصحاب المشاريع والحرفيين المهرة، وتوفر أفضل العروض العقارية في الجزائر.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="font-semibold mb-4 text-white">روابط سريعة</h3>
            <ul className="space-y-2 text-sm text-blue-200">
              <li><Link href="/" className="hover:text-white transition-colors">الرئيسية</Link></li>
              <li><Link href="/artisans" className="hover:text-white transition-colors">الحرفيون</Link></li>
              <li><Link href="/properties" className="hover:text-white transition-colors">العقارات</Link></li>
              <li><Link href="/contact" className="hover:text-white transition-colors">تواصل معنا</Link></li>
            </ul>
          </div>

          {/* For Artisans */}
          <div>
            <h3 className="font-semibold mb-4 text-white">للحرفيين</h3>
            <ul className="space-y-2 text-sm text-blue-200">
              <li><Link href="/register?role=artisan" className="hover:text-white transition-colors">سجّل كحرفي</Link></li>
              <li><Link href="/profile" className="hover:text-white transition-colors">إدارة ملفك</Link></li>
            </ul>
          </div>

          {/* Social */}
          <div>
            <h3 className="font-semibold mb-4 text-white">التواصل الاجتماعي</h3>
            <ul className="space-y-2 text-sm text-blue-200">
              <li><a href="#" className="hover:text-white transition-colors">فيسبوك</a></li>
              <li><a href="#" className="hover:text-white transition-colors">إنستغرام</a></li>
              <li><a href="#" className="hover:text-white transition-colors">تويتر</a></li>
            </ul>
          </div>
        </div>

        <div className="border-t border-blue-800 mt-8 pt-6 text-center text-sm text-blue-300">
          <p>© 2024 حرفي دار. جميع الحقوق محفوظة.</p>
        </div>
      </div>
    </footer>
  )
}
