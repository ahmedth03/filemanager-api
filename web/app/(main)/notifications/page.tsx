'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Bell, CheckCheck } from 'lucide-react'
import { api } from '@/lib/api'
import { isLoggedIn } from '@/lib/auth'
import { formatRelativeTime } from '@/lib/utils'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'

export default function NotificationsPage() {
  const router = useRouter()
  const [notifications, setNotifications] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!isLoggedIn()) { router.push('/login'); return }
    api.get('/notifications?page=1&limit=30').then(r => {
      const d = r.data?.data
      setNotifications(Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : [])
    }).catch(() => {}).finally(() => setLoading(false))
  }, [router])

  const markRead = async (id: string) => {
    await api.patch(`/notifications/${id}/read`).catch(() => {})
    setNotifications(n => n.map(notif => notif.id === id ? { ...notif, isRead: true } : notif))
  }

  const markAll = async () => {
    await api.patch('/notifications/read-all').catch(() => {})
    setNotifications(n => n.map(notif => ({ ...notif, isRead: true })))
  }

  if (loading) return <div className="flex justify-center py-20"><Spinner /></div>

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
          <Bell className="w-6 h-6 text-primary" /> الإشعارات
        </h1>
        {notifications.some(n => !n.isRead) && (
          <button onClick={markAll} className="text-sm text-primary hover:underline flex items-center gap-1">
            <CheckCheck className="w-4 h-4" /> تعليم الكل كمقروء
          </button>
        )}
      </div>
      {notifications.length === 0 ? (
        <EmptyState title="لا توجد إشعارات" description="ستظهر الإشعارات هنا" icon="🔔" />
      ) : (
        <div className="space-y-2">
          {notifications.map((n: any) => (
            <div key={n.id} onClick={() => markRead(n.id)}
              className={`card cursor-pointer transition-all hover:shadow-md ${!n.isRead ? 'border-r-4 border-primary' : ''}`}>
              <div className="flex items-start gap-3">
                <div className={`w-2 h-2 rounded-full mt-2 shrink-0 ${n.isRead ? 'bg-gray-300' : 'bg-primary'}`} />
                <div className="flex-1">
                  <p className={`text-sm ${n.isRead ? 'text-gray-500' : 'text-gray-800 font-medium'}`}>
                    {n.message || n.content || n.title}
                  </p>
                  <p className="text-xs text-gray-400 mt-1">{formatRelativeTime(n.createdAt)}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
