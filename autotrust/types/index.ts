export type CarCondition = 'NEW' | 'USED';
export type FuelType = 'ESSENCE' | 'DIESEL' | 'HYBRIDE' | 'ELECTRIQUE' | 'GPL';
export type Transmission = 'MANUELLE' | 'AUTOMATIQUE';
export type CarStatus = 'AVAILABLE' | 'SOLD' | 'RESERVED' | 'COMING_SOON';
export type LeadStatus = 'NEW' | 'CONTACTED' | 'QUALIFIED' | 'NEGOTIATING' | 'CLOSED_WON' | 'CLOSED_LOST';
export type UserRole = 'SUPER_ADMIN' | 'ADMIN' | 'SALES_MANAGER';

export interface CarImage {
  id: string;
  url: string;
  thumbnailUrl?: string | null;
  publicId?: string | null;
  isPrimary: boolean;
  order: number;
}

export interface Car {
  id: string;
  make: string;
  model: string;
  year: number;
  price: number;
  mileage: number;
  condition: CarCondition;
  fuel: FuelType;
  transmission: Transmission;
  color?: string | null;
  doors: number;
  seats: number;
  power?: number | null;
  engineSize?: number | null;
  description?: string | null;
  aiDescription?: string | null;
  featured: boolean;
  status: CarStatus;
  images: CarImage[];
  videoUrl?: string | null;
  slug: string;
  metaTitle?: string | null;
  metaDesc?: string | null;
  viewCount: number;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface Lead {
  id: string;
  name: string;
  phone: string;
  email?: string | null;
  carId?: string | null;
  message?: string | null;
  status: LeadStatus;
  source: string;
  notes?: string | null;
  assignedTo?: string | null;
  car?: Pick<Car, 'id' | 'make' | 'model' | 'year'> | null;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export interface User {
  id: string;
  name?: string | null;
  email: string;
  role: UserRole;
  isActive: boolean;
  createdAt: Date | string;
}

export interface CarFilters {
  make?: string;
  model?: string;
  yearMin?: number;
  yearMax?: number;
  priceMin?: number;
  priceMax?: number;
  condition?: CarCondition;
  fuel?: FuelType;
  transmission?: Transmission;
  status?: CarStatus;
  featured?: boolean;
  search?: string;
  page?: number;
  limit?: number;
  sortBy?: 'price' | 'year' | 'createdAt' | 'viewCount';
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}
