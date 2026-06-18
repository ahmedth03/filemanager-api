'use client'
import { useEffect, useRef, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Send, ArrowRight } from 'lucide-react'
import { io, Socket } from 'socket.io-client'
import { api, unwrap } from '@/lib/api'
import { getUser, isLoggedIn } from '@/lib/auth'
import { formatRelativeTime } from '@/lib/utils'
import Cookies from 'js-cookie'
import Spinner from '@/components/ui/Spinner'

export default function ChatRoomPage() {
  const { roomId } = useParams<{ roomId: string }>()
  const router = useRouter()
  const [messages, setMessages] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [input, setInput] = useState('')
  const [room, setRoom] = useState<any>(null)
  const socketRef = useRef<Socket | null>(null)
  const bottomRef = useRef<HTMLDivElement>(null)
  const currentUser = getUser()

  useEffect(() => {
    if (!isLoggedIn()) { router.push('/login'); return }

    Promise.all([
      api.get(`/chat/rooms/${roomId}`).then(r => setRoom(unwrap<any>(r))).catch(() => {}),
      api.get(`/chat/rooms/${roomId}/messages`).then(r => {
        const d = r.data?.data
        setMessages(Array.isArray(d?.data) ? d.data : Array.isArray(d) ? d : [])
      }).catch(() => {}),
    ]).finally(() => setLoading(false))

    const token = Cookies.get('access_token') || Cookies.get('refresh_token')
    const SOCKET_URL = (process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1').replace('/api/v1', '')
    const socket = io(`${SOCKET_URL}/chat`, {
      auth: { token: `Bearer ${token}` },
      transports: ['websocket'],
    })
    socketRef.current = socket
    socket.emit('join_room', { roomId })
    socket.on('new_message', (msg: any) => {
      setMessages(prev => [...prev, msg])
    })
    return () => { socket.disconnect() }
  }, [roomId, router])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const sendMessage = () => {
    if (!input.trim()) return
    socketRef.current?.emit('send_message', { roomId, content: input.trim() })
    setInput('')
  }

  const other = room?.participants?.find((p: any) => p.id !== currentUser?.id)

  if (loading) return <div className="flex justify-center py-20"><Spinner /></div>

  return (
    <div className="max-w-2xl mx-auto px-4 py-4 flex flex-col" style={{ height: 'calc(100vh - 80px)' }}>
      <div className="flex items-center gap-3 mb-4">
        <button onClick={() => router.push('/chat')} className="text-gray-500 hover:text-primary">
          <ArrowRight className="w-5 h-5" />
        </button>
        <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold">
          {other?.firstName?.[0]}{other?.lastName?.[0]}
        </div>
        <h2 className="font-bold text-gray-800">{other?.firstName} {other?.lastName}</h2>
      </div>

      <div className="flex-1 overflow-y-auto space-y-3 pb-4">
        {messages.length === 0 && (
          <div className="text-center text-gray-400 py-8">ابدأ المحادثة...</div>
        )}
        {messages.map((msg: any, i: number) => {
          const isMe = msg.senderId === currentUser?.id || msg.sender?.id === currentUser?.id
          return (
            <div key={msg.id ?? i} className={`flex ${isMe ? 'justify-start' : 'justify-end'}`}>
              <div className={`max-w-[70%] rounded-2xl px-4 py-2 ${isMe ? 'bg-primary text-white rounded-tr-sm' : 'bg-gray-100 text-gray-800 rounded-tl-sm'}`}>
                <p className="text-sm">{msg.content}</p>
                <p className={`text-xs mt-1 ${isMe ? 'text-white/70' : 'text-gray-400'}`}>{formatRelativeTime(msg.createdAt)}</p>
              </div>
            </div>
          )
        })}
        <div ref={bottomRef} />
      </div>

      <div className="flex gap-2 mt-2">
        <input
          className="input flex-1"
          placeholder="اكتب رسالة..."
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && !e.shiftKey && sendMessage()}
        />
        <button onClick={sendMessage} disabled={!input.trim()} className="btn-primary px-4 flex items-center gap-1 disabled:opacity-50">
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  )
}
