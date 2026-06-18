import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatPrice(price: number): string {
  return new Intl.NumberFormat('ar-DZ').format(price) + ' دج'
}

export function formatDate(date: string): string {
  return new Date(date).toLocaleDateString('ar-DZ', { year: 'numeric', month: 'long', day: 'numeric' })
}

export function formatRelativeTime(date: string): string {
  const now = new Date()
  const d = new Date(date)
  const diff = now.getTime() - d.getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'الآن'
  if (mins < 60) return `منذ ${mins} دقيقة`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `منذ ${hours} ساعة`
  const days = Math.floor(hours / 24)
  if (days < 7) return `منذ ${days} يوم`
  return formatDate(date)
}

export const WILAYA_NAMES: Record<string, string> = {
  W01:'أدرار', W02:'الشلف', W03:'الأغواط', W04:'أم البواقي', W05:'باتنة',
  W06:'بجاية', W07:'بسكرة', W08:'بشار', W09:'البليدة', W10:'البويرة',
  W11:'تمنراست', W12:'تبسة', W13:'تلمسان', W14:'تيارت', W15:'تيزي وزو',
  W16:'الجزائر', W17:'الجلفة', W18:'جيجل', W19:'سطيف', W20:'سعيدة',
  W21:'سكيكدة', W22:'سيدي بلعباس', W23:'عنابة', W24:'قالمة', W25:'قسنطينة',
  W26:'المدية', W27:'مستغانم', W28:'المسيلة', W29:'معسكر', W30:'ورقلة',
  W31:'وهران', W32:'البيض', W33:'إليزي', W34:'برج بوعريريج', W35:'بومرداس',
  W36:'الطارف', W37:'تندوف', W38:'تيسمسيلت', W39:'الوادي', W40:'خنشلة',
  W41:'سوق أهراس', W42:'تيبازة', W43:'ميلة', W44:'عين الدفلى', W45:'النعامة',
  W46:'عين تيموشنت', W47:'غرداية', W48:'غليزان',
}

export function getWilayaName(code: string): string {
  return WILAYA_NAMES[code] ?? code
}

export const PROPERTY_TYPE_LABELS: Record<string, string> = {
  APARTMENT: 'شقة', HOUSE: 'بيت', STUDIO: 'استوديو', VILLA: 'فيلا', COMMERCIAL: 'محل تجاري'
}

export const SPECIALTY_ICONS: Record<string, string> = {
  'سباكة': '🔧', 'كهرباء': '⚡', 'دهان': '🎨', 'تبليط وسيراميك': '🏠',
  'نجارة': '🪚', 'تكييف وتبريد': '❄️', 'بناء وجدران': '🧱',
  'حدادة ولحام': '🔩', 'تنظيف وصيانة': '🧹', 'ألومنيوم وزجاج': '🪟',
}
