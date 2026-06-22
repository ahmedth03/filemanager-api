import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatPrice(price: number): string {
  return new Intl.NumberFormat('fr-DZ', {
    style: 'decimal',
    maximumFractionDigits: 0,
  }).format(price) + ' DA';
}

export function formatMileage(km: number): string {
  return new Intl.NumberFormat('fr-DZ').format(km) + ' km';
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[àáâãäå]/g, 'a')
    .replace(/[éèêë]/g, 'e')
    .replace(/[îï]/g, 'i')
    .replace(/[ôö]/g, 'o')
    .replace(/[ùûü]/g, 'u')
    .replace(/[ç]/g, 'c')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function generateSlug(make: string, model: string, year: number): string {
  return `${slugify(make)}-${slugify(model)}-${year}`;
}

export function fuelLabel(fuel: string): string {
  const map: Record<string, string> = {
    ESSENCE: 'Essence', DIESEL: 'Diesel', HYBRIDE: 'Hybride',
    ELECTRIQUE: 'Électrique', GPL: 'GPL',
  };
  return map[fuel] ?? fuel;
}

export function transmissionLabel(t: string): string {
  return t === 'AUTOMATIQUE' ? 'Automatique' : 'Manuelle';
}

export function conditionLabel(c: string): string {
  return c === 'NEW' ? 'Neuve' : 'Occasion';
}

export function statusLabel(s: string): string {
  const map: Record<string, string> = {
    AVAILABLE: 'Disponible', SOLD: 'Vendue', RESERVED: 'Réservée', COMING_SOON: 'Bientôt',
  };
  return map[s] ?? s;
}

export function leadStatusLabel(s: string): string {
  const map: Record<string, string> = {
    NEW: 'Nouveau', CONTACTED: 'Contacté', QUALIFIED: 'Qualifié',
    NEGOTIATING: 'Négociation', CLOSED_WON: 'Gagné', CLOSED_LOST: 'Perdu',
  };
  return map[s] ?? s;
}

export function calculateMonthlyPayment(price: number, downPayment: number, months: number, rate: number): number {
  const principal = price - downPayment;
  if (principal <= 0) return 0;
  const monthlyRate = rate / 100 / 12;
  if (monthlyRate === 0) return principal / months;
  return (principal * monthlyRate * Math.pow(1 + monthlyRate, months)) / (Math.pow(1 + monthlyRate, months) - 1);
}

export function getCarPrimaryImage(car: { images?: Array<{ url: string; isPrimary: boolean }> }): string {
  if (!car.images?.length) return '/images/car-placeholder.jpg';
  return car.images.find(i => i.isPrimary)?.url ?? car.images[0]?.url ?? '/images/car-placeholder.jpg';
}

export function relativeTime(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  const now = new Date();
  const diff = Math.floor((now.getTime() - d.getTime()) / 1000);
  if (diff < 60) return 'À l\'instant';
  if (diff < 3600) return `Il y a ${Math.floor(diff / 60)} min`;
  if (diff < 86400) return `Il y a ${Math.floor(diff / 3600)}h`;
  if (diff < 2592000) return `Il y a ${Math.floor(diff / 86400)}j`;
  return d.toLocaleDateString('fr-DZ');
}
