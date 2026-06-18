'use client'
import Link from 'next/link'
import { useRouter, usePathname } from 'next/navigation'
import { useState, useEffect } from 'react'
import { User, LogOut, Menu, X, Home, Hammer, Building2, ChevronDown } from 'lucide-react'
import { getUser, clearAuth, type User as UserType } from '@/lib/auth'
import toast from 'react-hot-toast'

export default function Navbar() {
  const router = useRouter()
  const pathname = usePathname()
  const [user, setUser] = useState<UserType | null>(null)
  const [menuOpen, setMenuOpen] = useState(false)
  const [dropdownOpen, setDropdownOpen] = useState(false)

  useEffect(() => {
    setUser(getUser())
  }, [pathname])

  const handleLogout = () => {
    clearAuth()
    setUser(null)
    setDropdownOpen(false)
    toast.success('تم تسجيل الخروج بنجاح')
    router.push('/')
  }

  const navLinks = [
    { href: '/', label: 'الرئيسية', icon: Home },
    { href: '/artisans', label: 'الحرفيون', icon: Hammer },
    { href: '/properties', label: 'العقارات', icon: Building2 },
  ]

  return (
    <nav className="bg-white shadow-sm border-b border-gray-100 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2 text-primary font-bold text-xl">
            <span>🏠</span>
            <span>حرفي دار</span>
          </Link>

          {/* Desktop Nav Links */}
          <div className="hidden md:flex items-center gap-6">
            {navLinks.map(({ href, label }) => (
              <Link
                key={href}
                href={href}
                className={`text-sm font-medium transition-colors ${pathname === href ? 'text-primary' : 'text-gray-600 hover:text-primary'}`}
              >
                {label}
              </Link>
            ))}
          </div>

          {/* Auth */}
          <div className="hidden md:flex items-center gap-3">
            {user ? (
              <div className="relative">
                <button
                  onClick={() => setDropdownOpen(!dropdownOpen)}
                  className="flex items-center gap-2 text-sm font-medium text-gray-700 hover:text-primary transition-colors"
                >
                  <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-white text-xs font-bold">
                    {user.firstName?.[0]}{user.lastName?.[0]}
                  </div>
                  <span>{user.firstName} {user.lastName}</span>
                  <ChevronDown className="w-4 h-4" />
                </button>
                {dropdownOpen && (
                  <div className="absolute left-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-gray-100 py-1 z-50">
                    <Link href="/profile" className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50" onClick={() => setDropdownOpen(false)}>
                      <User className="w-4 h-4" /> الملف الشخصي
                    </Link>
                    <Link href="/my-listings" className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50" onClick={() => setDropdownOpen(false)}>
                      <Building2 className="w-4 h-4" /> إعلاناتي
                    </Link>
                    <hr className="my-1" />
                    <button onClick={handleLogout} className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 w-full text-right">
                      <LogOut className="w-4 h-4" /> تسجيل الخروج
                    </button>
                  </div>
                )}
              </div>
            ) : (
              <>
                <Link href="/login" className="btn-outline text-sm py-2 px-4">دخول</Link>
                <Link href="/register" className="btn-primary text-sm py-2 px-4">تسجيل</Link>
              </>
            )}
          </div>

          {/* Mobile hamburger */}
          <button className="md:hidden p-2" onClick={() => setMenuOpen(!menuOpen)}>
            {menuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {menuOpen && (
          <div className="md:hidden border-t border-gray-100 py-4 space-y-2">
            {navLinks.map(({ href, label, icon: Icon }) => (
              <Link
                key={href}
                href={href}
                className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 hover:text-primary"
                onClick={() => setMenuOpen(false)}
              >
                <Icon className="w-4 h-4" />
                {label}
              </Link>
            ))}
            <hr className="my-2" />
            {user ? (
              <>
                <Link href="/profile" className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700" onClick={() => setMenuOpen(false)}>
                  <User className="w-4 h-4" /> الملف الشخصي
                </Link>
                <button onClick={() => { handleLogout(); setMenuOpen(false) }} className="flex items-center gap-2 px-4 py-2 text-sm text-red-600 w-full">
                  <LogOut className="w-4 h-4" /> تسجيل الخروج
                </button>
              </>
            ) : (
              <div className="flex gap-2 px-4">
                <Link href="/login" className="btn-outline text-sm flex-1 text-center" onClick={() => setMenuOpen(false)}>دخول</Link>
                <Link href="/register" className="btn-primary text-sm flex-1 text-center" onClick={() => setMenuOpen(false)}>تسجيل</Link>
              </div>
            )}
          </div>
        )}
      </div>
    </nav>
  )
}
