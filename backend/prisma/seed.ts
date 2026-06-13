/**
 * HarfiDar Platform – Database Seed
 *
 * Seeds:
 *   1. All 58 Algeria wilayas
 *   2. 25 craftsmen specialties (AR / FR / EN)
 *   3. Admin user  (admin@harfidar.dz / Admin@123456)
 *   4. Default AppConfig entries
 */

import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

// ─── 1. Wilayas ───────────────────────────────────────────────────────────────
// Official list of the 58 Algerian wilayas (ordered by national code)
const WILAYAS: Array<{ id: number; code: string; nameAr: string; nameFr: string }> = [
  { id: 1,  code: 'W01', nameAr: 'أدرار',              nameFr: 'Adrar' },
  { id: 2,  code: 'W02', nameAr: 'الشلف',              nameFr: 'Chlef' },
  { id: 3,  code: 'W03', nameAr: 'الأغواط',            nameFr: 'Laghouat' },
  { id: 4,  code: 'W04', nameAr: 'أم البواقي',         nameFr: 'Oum El Bouaghi' },
  { id: 5,  code: 'W05', nameAr: 'باتنة',              nameFr: 'Batna' },
  { id: 6,  code: 'W06', nameAr: 'بجاية',              nameFr: 'Béjaïa' },
  { id: 7,  code: 'W07', nameAr: 'بسكرة',              nameFr: 'Biskra' },
  { id: 8,  code: 'W08', nameAr: 'بشار',               nameFr: 'Béchar' },
  { id: 9,  code: 'W09', nameAr: 'البليدة',            nameFr: 'Blida' },
  { id: 10, code: 'W10', nameAr: 'البويرة',            nameFr: 'Bouira' },
  { id: 11, code: 'W11', nameAr: 'تمنراست',            nameFr: 'Tamanrasset' },
  { id: 12, code: 'W12', nameAr: 'تبسة',               nameFr: 'Tébessa' },
  { id: 13, code: 'W13', nameAr: 'تلمسان',             nameFr: 'Tlemcen' },
  { id: 14, code: 'W14', nameAr: 'تيارت',              nameFr: 'Tiaret' },
  { id: 15, code: 'W15', nameAr: 'تيزي وزو',           nameFr: 'Tizi Ouzou' },
  { id: 16, code: 'W16', nameAr: 'الجزائر',            nameFr: 'Alger' },
  { id: 17, code: 'W17', nameAr: 'الجلفة',             nameFr: 'Djelfa' },
  { id: 18, code: 'W18', nameAr: 'جيجل',               nameFr: 'Jijel' },
  { id: 19, code: 'W19', nameAr: 'سطيف',               nameFr: 'Sétif' },
  { id: 20, code: 'W20', nameAr: 'سعيدة',              nameFr: 'Saïda' },
  { id: 21, code: 'W21', nameAr: 'سكيكدة',             nameFr: 'Skikda' },
  { id: 22, code: 'W22', nameAr: 'سيدي بلعباس',        nameFr: 'Sidi Bel Abbès' },
  { id: 23, code: 'W23', nameAr: 'عنابة',              nameFr: 'Annaba' },
  { id: 24, code: 'W24', nameAr: 'قالمة',              nameFr: 'Guelma' },
  { id: 25, code: 'W25', nameAr: 'قسنطينة',            nameFr: 'Constantine' },
  { id: 26, code: 'W26', nameAr: 'المدية',             nameFr: 'Médéa' },
  { id: 27, code: 'W27', nameAr: 'مستغانم',            nameFr: 'Mostaganem' },
  { id: 28, code: 'W28', nameAr: 'المسيلة',            nameFr: 'M\'Sila' },
  { id: 29, code: 'W29', nameAr: 'معسكر',              nameFr: 'Mascara' },
  { id: 30, code: 'W30', nameAr: 'ورقلة',              nameFr: 'Ouargla' },
  { id: 31, code: 'W31', nameAr: 'وهران',              nameFr: 'Oran' },
  { id: 32, code: 'W32', nameAr: 'البيض',              nameFr: 'El Bayadh' },
  { id: 33, code: 'W33', nameAr: 'إليزي',              nameFr: 'Illizi' },
  { id: 34, code: 'W34', nameAr: 'برج بوعريريج',       nameFr: 'Bordj Bou Arréridj' },
  { id: 35, code: 'W35', nameAr: 'بومرداس',            nameFr: 'Boumerdès' },
  { id: 36, code: 'W36', nameAr: 'الطارف',             nameFr: 'El Tarf' },
  { id: 37, code: 'W37', nameAr: 'تندوف',              nameFr: 'Tindouf' },
  { id: 38, code: 'W38', nameAr: 'تيسمسيلت',           nameFr: 'Tissemsilt' },
  { id: 39, code: 'W39', nameAr: 'الوادي',             nameFr: 'El Oued' },
  { id: 40, code: 'W40', nameAr: 'خنشلة',              nameFr: 'Khenchela' },
  { id: 41, code: 'W41', nameAr: 'سوق أهراس',          nameFr: 'Souk Ahras' },
  { id: 42, code: 'W42', nameAr: 'تيبازة',             nameFr: 'Tipaza' },
  { id: 43, code: 'W43', nameAr: 'ميلة',               nameFr: 'Mila' },
  { id: 44, code: 'W44', nameAr: 'عين الدفلى',         nameFr: 'Aïn Defla' },
  { id: 45, code: 'W45', nameAr: 'النعامة',            nameFr: 'Naâma' },
  { id: 46, code: 'W46', nameAr: 'عين تموشنت',         nameFr: 'Aïn Témouchent' },
  { id: 47, code: 'W47', nameAr: 'غرداية',             nameFr: 'Ghardaïa' },
  { id: 48, code: 'W48', nameAr: 'غليزان',             nameFr: 'Relizane' },
  { id: 49, code: 'W49', nameAr: 'تيميمون',            nameFr: 'Timimoun' },
  { id: 50, code: 'W50', nameAr: 'برج باجي مختار',     nameFr: 'Bordj Badji Mokhtar' },
  { id: 51, code: 'W51', nameAr: 'أولاد جلال',         nameFr: 'Ouled Djellal' },
  { id: 52, code: 'W52', nameAr: 'بني عباس',           nameFr: 'Béni Abbès' },
  { id: 53, code: 'W53', nameAr: 'عين صالح',           nameFr: 'In Salah' },
  { id: 54, code: 'W54', nameAr: 'عين قزام',           nameFr: 'In Guezzam' },
  { id: 55, code: 'W55', nameAr: 'توقرت',              nameFr: 'Touggourt' },
  { id: 56, code: 'W56', nameAr: 'جانت',               nameFr: 'Djanet' },
  { id: 57, code: 'W57', nameAr: 'المغير',             nameFr: 'El M\'Ghair' },
  { id: 58, code: 'W58', nameAr: 'المنيعة',            nameFr: 'El Meniaa' },
];

// ─── 2. Specialties ───────────────────────────────────────────────────────────
// 25 craftsman / service specialties common in the Algerian market
const SPECIALTIES: Array<{ nameAr: string; nameFr: string; nameEn: string; icon: string }> = [
  {
    nameAr: 'سباك',
    nameFr: 'Plombier',
    nameEn: 'Plumber',
    icon: 'plumbing',
  },
  {
    nameAr: 'كهربائي',
    nameFr: 'Électricien',
    nameEn: 'Electrician',
    icon: 'electrical_services',
  },
  {
    nameAr: 'نقاش / دهان',
    nameFr: 'Peintre',
    nameEn: 'Painter',
    icon: 'format_paint',
  },
  {
    nameAr: 'نجار',
    nameFr: 'Menuisier',
    nameEn: 'Carpenter',
    icon: 'carpenter',
  },
  {
    nameAr: 'بناء / مقاول',
    nameFr: 'Maçon / Entrepreneur',
    nameEn: 'Mason / Contractor',
    icon: 'construction',
  },
  {
    nameAr: 'فراش بلاط',
    nameFr: 'Carreleur',
    nameEn: 'Tiler',
    icon: 'grid_view',
  },
  {
    nameAr: 'جبصين / جابص',
    nameFr: 'Plâtrier',
    nameEn: 'Plasterer',
    icon: 'wall',
  },
  {
    nameAr: 'حداد / لحام',
    nameFr: 'Soudeur / Ferrailleur',
    nameEn: 'Welder / Metalworker',
    icon: 'hardware',
  },
  {
    nameAr: 'ميكانيكي سيارات',
    nameFr: 'Mécanicien automobile',
    nameEn: 'Auto Mechanic',
    icon: 'car_repair',
  },
  {
    nameAr: 'تقني تكييف وتبريد',
    nameFr: 'Technicien en climatisation',
    nameEn: 'AC & Refrigeration Technician',
    icon: 'ac_unit',
  },
  {
    nameAr: 'حداد أبواب / قفّال',
    nameFr: 'Serrurier',
    nameEn: 'Locksmith',
    icon: 'lock',
  },
  {
    nameAr: 'خدمة تنظيف',
    nameFr: 'Service de nettoyage',
    nameEn: 'Cleaning Service',
    icon: 'cleaning_services',
  },
  {
    nameAr: 'خدمة نقل عفش',
    nameFr: 'Déménageur',
    nameEn: 'Moving Service',
    icon: 'local_shipping',
  },
  {
    nameAr: 'بستاني / حدائق',
    nameFr: 'Jardinier / Paysagiste',
    nameEn: 'Gardener / Landscaper',
    icon: 'yard',
  },
  {
    nameAr: 'حداد ديكور / تزيين',
    nameFr: 'Ferronnier décorateur',
    nameEn: 'Decorative Ironwork',
    icon: 'design_services',
  },
  {
    nameAr: 'ألومنيوم وزجاج',
    nameFr: 'Aluminium et vitrerie',
    nameEn: 'Aluminium & Glazing',
    icon: 'window',
  },
  {
    nameAr: 'رخام وغرانيت',
    nameFr: 'Marbrerie / Graniterie',
    nameEn: 'Marble & Granite',
    icon: 'countertops',
  },
  {
    nameAr: 'طاقة شمسية',
    nameFr: 'Énergie solaire',
    nameEn: 'Solar Energy',
    icon: 'solar_power',
  },
  {
    nameAr: 'كاميرات مراقبة',
    nameFr: 'Vidéosurveillance / CCTV',
    nameEn: 'CCTV & Security Cameras',
    icon: 'videocam',
  },
  {
    nameAr: 'شبكات إنترنت',
    nameFr: 'Réseaux Internet',
    nameEn: 'Network & Internet',
    icon: 'router',
  },
  {
    nameAr: 'أنتينا وستلايت',
    nameFr: 'Antenne et satellite',
    nameEn: 'Antenna & Satellite',
    icon: 'satellite_alt',
  },
  {
    nameAr: 'هدم وتكسير',
    nameFr: 'Démolition',
    nameEn: 'Demolition',
    icon: 'delete_sweep',
  },
  {
    nameAr: 'حفر وتسوية',
    nameFr: 'Terrassement / Excavation',
    nameEn: 'Excavation & Earthwork',
    icon: 'agriculture',
  },
  {
    nameAr: 'عزل مائي وحراري',
    nameFr: 'Isolation hydrique et thermique',
    nameEn: 'Waterproofing & Insulation',
    icon: 'water_damage',
  },
  {
    nameAr: 'سباكة صحية / حمامات',
    nameFr: 'Plomberie sanitaire / Salles de bain',
    nameEn: 'Sanitary Plumbing / Bathrooms',
    icon: 'bathroom',
  },
];

// ─── 3. Admin credentials ─────────────────────────────────────────────────────
const ADMIN_EMAIL = 'admin@harfidar.dz';
const ADMIN_PASSWORD = 'Admin@123456';
const ADMIN_FIRST = 'HarfiDar';
const ADMIN_LAST = 'Admin';

// ─── 4. Default AppConfig entries ────────────────────────────────────────────
const APP_CONFIG: Array<{ key: string; value: string }> = [
  { key: 'platform.name',               value: 'HarfiDar' },
  { key: 'platform.nameAr',             value: 'حرفي دار' },
  { key: 'platform.version',            value: '1.0.0' },
  { key: 'platform.supportEmail',       value: 'support@harfidar.dz' },
  { key: 'platform.contactPhone',       value: '+213 XXX XXX XXX' },
  { key: 'listing.maxImagesPerListing', value: '10' },
  { key: 'listing.expiryDays',          value: '90' },
  { key: 'craftsman.maxPortfolioItems', value: '20' },
  { key: 'review.minRating',            value: '1' },
  { key: 'review.maxRating',            value: '5' },
  { key: 'pagination.defaultLimit',     value: '20' },
  { key: 'pagination.maxLimit',         value: '100' },
  { key: 'upload.maxFileSizeMb',        value: '10' },
  { key: 'upload.allowedMimeTypes',     value: 'image/jpeg,image/png,image/webp,image/gif' },
  { key: 'features.chatEnabled',        value: 'true' },
  { key: 'features.reviewsEnabled',     value: 'true' },
  { key: 'features.notificationsEnabled', value: 'true' },
];

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 Seeding HarfiDar database...\n');

  // ── Wilayas ──────────────────────────────────────────────────────────────────
  console.log(`  Seeding ${WILAYAS.length} wilayas...`);
  let wilayaCount = 0;
  for (const wilaya of WILAYAS) {
    await prisma.wilaya.upsert({
      where: { id: wilaya.id },
      update: { code: wilaya.code, nameAr: wilaya.nameAr, nameFr: wilaya.nameFr },
      create: { id: wilaya.id, code: wilaya.code, nameAr: wilaya.nameAr, nameFr: wilaya.nameFr },
    });
    wilayaCount++;
  }
  console.log(`  ✔  ${wilayaCount} wilayas seeded.\n`);

  // ── Specialties ───────────────────────────────────────────────────────────────
  console.log(`  Seeding ${SPECIALTIES.length} specialties...`);
  const { count: specialtyCount } = await prisma.specialty.createMany({
    data: SPECIALTIES.map((s) => ({
      nameAr: s.nameAr,
      nameFr: s.nameFr,
      nameEn: s.nameEn,
      icon: s.icon,
      isActive: true,
    })),
    skipDuplicates: true,
  });
  console.log(`  ✔  ${specialtyCount} specialties seeded.\n`);

  // ── Admin user ────────────────────────────────────────────────────────────────
  console.log(`  Creating admin user: ${ADMIN_EMAIL}...`);
  const passwordHash = await bcrypt.hash(ADMIN_PASSWORD, 12);

  const admin = await prisma.user.upsert({
    where: { email: ADMIN_EMAIL },
    update: {
      passwordHash,
      firstName: ADMIN_FIRST,
      lastName: ADMIN_LAST,
      role: 'ADMIN',
      status: 'ACTIVE',
      isEmailVerified: true,
    },
    create: {
      email: ADMIN_EMAIL,
      passwordHash,
      firstName: ADMIN_FIRST,
      lastName: ADMIN_LAST,
      role: 'ADMIN',
      status: 'ACTIVE',
      isEmailVerified: true,
    },
  });
  console.log(`  ✔  Admin user ready (id: ${admin.id}).\n`);

  // ── AppConfig ─────────────────────────────────────────────────────────────────
  console.log(`  Seeding ${APP_CONFIG.length} app config entries...`);
  for (const entry of APP_CONFIG) {
    await prisma.appConfig.upsert({
      where: { key: entry.key },
      update: { value: entry.value },
      create: { key: entry.key, value: entry.value },
    });
  }
  console.log(`  ✔  ${APP_CONFIG.length} config entries seeded.\n`);

  console.log('✅  Seed completed successfully!');
  console.log('');
  console.log('  Admin credentials:');
  console.log(`    Email   : ${ADMIN_EMAIL}`);
  console.log(`    Password: ${ADMIN_PASSWORD}`);
  console.log('');
}

main()
  .catch((err) => {
    console.error('❌  Seed failed:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
