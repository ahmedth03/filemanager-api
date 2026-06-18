import type { Metadata } from 'next'
import { Cairo } from 'next/font/google'
import './globals.css'
import { Toaster } from 'react-hot-toast'

const cairo = Cairo({ subsets: ['arabic', 'latin'], variable: '--font-cairo' })

export const metadata: Metadata = {
  title: 'حرفي دار - ابحث عن حرفيين واستأجر عقارات',
  description: 'منصة حرفي دار الجزائرية لإيجاد أفضل الحرفيين وأجمل العقارات في الجزائر',
  keywords: 'حرفيين، عقارات، جزائر، إيجار، بناء',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body className={`${cairo.variable} font-cairo bg-gray-50 text-gray-900`}>
        <Toaster position="top-center" toastOptions={{ style: { fontFamily: 'Cairo, sans-serif', direction: 'rtl' } }} />
        {children}
      </body>
    </html>
  )
}
