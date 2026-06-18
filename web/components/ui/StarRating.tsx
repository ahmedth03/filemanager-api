'use client'
import { Star } from 'lucide-react'
export default function StarRating({ value, onChange, readonly, size = 'md' }: { value: number; onChange?: (v: number) => void; readonly?: boolean; size?: 'sm' | 'md' | 'lg' }) {
  const s = { sm: 'w-4 h-4', md: 'w-5 h-5', lg: 'w-6 h-6' }[size]
  return (
    <div className="flex gap-0.5">
      {[1,2,3,4,5].map(i => (
        <button key={i} type="button" disabled={readonly} onClick={() => onChange?.(i)} className={readonly ? 'cursor-default' : 'hover:scale-110 transition-transform'}>
          <Star className={`${s} ${i <= value ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`} />
        </button>
      ))}
    </div>
  )
}
