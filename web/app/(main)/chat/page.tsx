'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { MessageCircle, ArrowLeft } from 'lucide-react'
import { api } from '@/lib/api'
import { getUser, isLoggedIn } from '@/lib/auth'
import { formatRelativeTime } from '@/lib/utils'
import Spinner from '@/components/ui/Spinner'
import EmptyState from '@/components/ui/EmptyState'

export default function ChatPage() {
  const router = useRouter()
  const [rooms, setRooms] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const currentUser = getUser()

  useEffect(() => {
    if (!isLoggedIn()) { router.push('/login'); return }
    api.get('/chat/rooms').then(r => {
      const d = r.data?.data
      setRooms(Array.isArray(d) ? d : [])
    }).catch(() => {}).finally(() => setLoading(false))
  }, [router])

  if (loading) return <div className="flex justify-center py-20"><Spinner /></div>

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <h1 className="text-2xl font-bold text-gray-800 mb-6 flex items-center gap-2">
        <MessageCircle className="w-6 h-6 text-primary" /> المحادثات
      </h1>
      {rooms.length === 0 ? (
        <EmptyState title="لا توجد محادثات" description="ابدأ محادثة من صفحة حرفي أو عقار" icon="💬" />
      ) : (
        <div className="space-y-2">
          {rooms.map((room: any) => {
            const other = room.participants?.find((p: any) => p.id !== currentUser?.id)
            const lastMsg = room.lastMessage
            return (
              <Link key={room.id} href={`/chat/${room.id}`} className="card hover:shadow-md transition-all flex items-center gap-4">
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold shrink-0">
                  {other?.firstName?.[0]}{other?.lastName?.[0]}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <span className="font-semibold text-gray-800 truncate">{other?.firstName} {other?.lastName}</span>
                    {lastMsg && <span className="text-xs text-gray-400 shrink-0">{formatRelativeTime(lastMsg.createdAt)}</span>}
                  </div>
                  {lastMsg && <p className="text-sm text-gray-500 truncate mt-0.5">{lastMsg.content}</p>}
                </div>
                <ArrowLeft className="w-4 h-4 text-gray-400 shrink-0" />
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
