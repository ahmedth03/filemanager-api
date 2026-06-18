import Link from 'next/link'
import { MapPin, Star, Hammer } from 'lucide-react'
import { getWilayaName } from '@/lib/utils'

interface Props {
  craftsman: {
    id: string
    userId: string
    user: { firstName: string; lastName: string; avatarUrl?: string }
    specialty: { name: string }
    bio?: string
    wilaya: string
    city?: string
    rating: number
    reviewCount: number
    isAvailable: boolean
    yearsOfExperience?: number
  }
}

export default function CraftsmanCard({ craftsman }: Props) {
  const name = `${craftsman.user.firstName} ${craftsman.user.lastName}`
  const initials = `${craftsman.user.firstName[0]}${craftsman.user.lastName[0]}`
  return (
    <Link href={`/artisans/${craftsman.id}`} className="card hover:shadow-lg transition-all group block">
      <div className="flex items-start gap-4">
        <div className="flex-shrink-0">
          {craftsman.user.avatarUrl ? (
            <img src={craftsman.user.avatarUrl} alt={name} className="w-14 h-14 rounded-full object-cover" />
          ) : (
            <div className="w-14 h-14 bg-primary/10 rounded-full flex items-center justify-center text-primary font-bold text-lg">
              {initials}
            </div>
          )}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-2">
            <h3 className="font-bold text-gray-800 group-hover:text-primary transition-colors truncate">{name}</h3>
            {craftsman.isAvailable ? (
              <span className="badge bg-green-100 text-green-700 text-xs shrink-0">متاح</span>
            ) : (
              <span className="badge bg-gray-100 text-gray-500 text-xs shrink-0">مشغول</span>
            )}
          </div>
          <div className="flex items-center gap-1 mt-0.5">
            <Hammer className="w-3.5 h-3.5 text-primary" />
            <span className="text-sm text-primary font-medium">{craftsman.specialty.name}</span>
          </div>
          {craftsman.bio && (
            <p className="text-gray-500 text-sm mt-1 line-clamp-2">{craftsman.bio}</p>
          )}
          <div className="flex items-center gap-3 mt-2 text-sm text-gray-500">
            <span className="flex items-center gap-1">
              <MapPin className="w-3.5 h-3.5" />
              {craftsman.city ? `${craftsman.city}، ` : ''}{getWilayaName(craftsman.wilaya)}
            </span>
            <span className="flex items-center gap-1">
              <Star className="w-3.5 h-3.5 text-yellow-400 fill-yellow-400" />
              {craftsman.rating.toFixed(1)} ({craftsman.reviewCount})
            </span>
          </div>
        </div>
      </div>
    </Link>
  )
}
