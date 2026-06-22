import Link from 'next/link';
import Image from 'next/image';
import { Heart, Fuel, Gauge, Calendar, Star } from 'lucide-react';
import { Car } from '@/types';
import { formatPrice, formatMileage, fuelLabel, transmissionLabel, conditionLabel, getCarPrimaryImage } from '@/lib/utils';

interface Props { car: Car; }

export default function CarCard({ car }: Props) {
  const primaryImage = getCarPrimaryImage(car);
  const isNew = car.condition === 'NEW';

  return (
    <Link href={`/cars/${car.slug}`} className="card group block overflow-hidden">
      {/* Image */}
      <div className="relative h-52 overflow-hidden bg-gray-100">
        <Image src={primaryImage} alt={`${car.make} ${car.model}`} fill style={{ objectFit: 'cover' }} className="group-hover:scale-105 transition-transform duration-500" sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw" />
        <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent" />

        {/* Badges */}
        <div className="absolute top-3 left-3 flex gap-2">
          <span className={isNew ? 'badge-new' : 'badge-used'}>{conditionLabel(car.condition)}</span>
          {car.featured && (
            <span className="bg-primary-500 text-white text-xs font-semibold px-2 py-0.5 rounded-full flex items-center gap-1">
              <Star size={10} fill="currentColor" /> Vedette
            </span>
          )}
        </div>

        {/* Wishlist */}
        <button className="absolute top-3 right-3 w-8 h-8 bg-white/90 rounded-full flex items-center justify-center hover:bg-white hover:text-primary-500 transition-all duration-200 opacity-0 group-hover:opacity-100" onClick={e => e.preventDefault()}>
          <Heart size={14} />
        </button>

        {/* Status overlay */}
        {car.status !== 'AVAILABLE' && (
          <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
            <span className="bg-white text-dark font-bold text-sm px-4 py-2 rounded-full">
              {car.status === 'SOLD' ? 'VENDUE' : car.status === 'RESERVED' ? 'RÉSERVÉE' : 'BIENTÔT'}
            </span>
          </div>
        )}
      </div>

      {/* Content */}
      <div className="p-4">
        <div className="flex items-start justify-between mb-2">
          <div>
            <h3 className="font-heading font-bold text-dark text-lg leading-tight">{car.make} {car.model}</h3>
            <p className="text-gray-500 text-sm">{car.year}</p>
          </div>
          <p className="font-heading font-bold text-primary-500 text-xl whitespace-nowrap">{formatPrice(car.price)}</p>
        </div>

        {/* Specs */}
        <div className="grid grid-cols-3 gap-2 mt-3 pt-3 border-t border-gray-100">
          <div className="flex items-center gap-1.5 text-gray-500">
            <Fuel size={13} className="text-gray-400" />
            <span className="text-xs">{fuelLabel(car.fuel)}</span>
          </div>
          <div className="flex items-center gap-1.5 text-gray-500">
            <Gauge size={13} className="text-gray-400" />
            <span className="text-xs">{formatMileage(car.mileage)}</span>
          </div>
          <div className="flex items-center gap-1.5 text-gray-500">
            <Calendar size={13} className="text-gray-400" />
            <span className="text-xs">{car.year}</span>
          </div>
        </div>

        <div className="mt-3 flex items-center justify-between">
          <span className="text-xs text-gray-400">{transmissionLabel(car.transmission)}</span>
          <span className="text-xs font-semibold text-primary-500 group-hover:underline">Voir détails →</span>
        </div>
      </div>
    </Link>
  );
}
