import Link from 'next/link'
import { MapPin, Bed, Bath, Maximize } from 'lucide-react'
import { formatPrice, getWilayaName, PROPERTY_TYPE_LABELS } from '@/lib/utils'

interface Props {
  property: {
    id: string
    title: string
    description?: string
    price: number
    wilaya: string
    city?: string
    propertyType: string
    bedrooms?: number
    bathrooms?: number
    area?: number
    images?: string[]
    isFurnished?: boolean
    isAvailable?: boolean
  }
}

export default function PropertyCard({ property }: Props) {
  const img = property.images?.[0]
  return (
    <Link href={`/properties/${property.id}`} className="card p-0 overflow-hidden hover:shadow-lg transition-all group block">
      <div className="relative">
        {img ? (
          <img src={img} alt={property.title} className="w-full h-48 object-cover" />
        ) : (
          <div className="w-full h-48 bg-gradient-to-br from-gray-100 to-gray-200 flex items-center justify-center text-4xl">🏠</div>
        )}
        <span className="absolute top-3 right-3 badge bg-white text-gray-700 shadow text-xs">
          {PROPERTY_TYPE_LABELS[property.propertyType] ?? property.propertyType}
        </span>
        {property.isAvailable === false && (
          <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
            <span className="text-white font-bold text-lg">غير متاح</span>
          </div>
        )}
      </div>
      <div className="p-4">
        <h3 className="font-bold text-gray-800 group-hover:text-primary transition-colors line-clamp-1">{property.title}</h3>
        <p className="text-primary font-bold text-lg mt-1">{formatPrice(property.price)} <span className="text-gray-400 text-sm font-normal">/ شهر</span></p>
        <div className="flex items-center gap-1 text-sm text-gray-500 mt-1">
          <MapPin className="w-3.5 h-3.5" />
          {property.city ? `${property.city}، ` : ''}{getWilayaName(property.wilaya)}
        </div>
        <div className="flex items-center gap-3 mt-3 text-sm text-gray-500">
          {property.bedrooms != null && (
            <span className="flex items-center gap-1"><Bed className="w-4 h-4" />{property.bedrooms} غرف</span>
          )}
          {property.bathrooms != null && (
            <span className="flex items-center gap-1"><Bath className="w-4 h-4" />{property.bathrooms} حمام</span>
          )}
          {property.area != null && (
            <span className="flex items-center gap-1"><Maximize className="w-4 h-4" />{property.area} م²</span>
          )}
        </div>
      </div>
    </Link>
  )
}
