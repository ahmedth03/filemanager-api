import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const HASH = bcrypt.hashSync('HarfiDar2024!', 10);

async function main() {
  console.log('🌱 Seeding HarfiDar database...');

  // ── Specialties ──────────────────────────────────────────────────────────
  const specialties = await Promise.all([
    prisma.specialty.upsert({ where: { id: 'sp_plumb' }, update: {}, create: { id: 'sp_plumb', nameAr: 'سباكة', nameFr: 'Plomberie', nameEn: 'Plumbing', icon: '🔧', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_elec' }, update: {}, create: { id: 'sp_elec', nameAr: 'كهرباء', nameFr: 'Électricité', nameEn: 'Electricity', icon: '⚡', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_paint' }, update: {}, create: { id: 'sp_paint', nameAr: 'دهان', nameFr: 'Peinture', nameEn: 'Painting', icon: '🎨', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_tile' }, update: {}, create: { id: 'sp_tile', nameAr: 'تبليط وسيراميك', nameFr: 'Carrelage', nameEn: 'Tiling', icon: '🏠', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_carpent' }, update: {}, create: { id: 'sp_carpent', nameAr: 'نجارة', nameFr: 'Menuiserie', nameEn: 'Carpentry', icon: '🪚', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_ac' }, update: {}, create: { id: 'sp_ac', nameAr: 'تكييف وتبريد', nameFr: 'Climatisation', nameEn: 'AC & Cooling', icon: '❄️', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_mason' }, update: {}, create: { id: 'sp_mason', nameAr: 'بناء وجدران', nameFr: 'Maçonnerie', nameEn: 'Masonry', icon: '🧱', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_weld' }, update: {}, create: { id: 'sp_weld', nameAr: 'حدادة ولحام', nameFr: 'Soudure', nameEn: 'Welding', icon: '🔩', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_clean' }, update: {}, create: { id: 'sp_clean', nameAr: 'تنظيف وصيانة', nameFr: 'Nettoyage', nameEn: 'Cleaning', icon: '🧹', isActive: true } }),
    prisma.specialty.upsert({ where: { id: 'sp_alum' }, update: {}, create: { id: 'sp_alum', nameAr: 'ألومنيوم وزجاج', nameFr: 'Aluminium', nameEn: 'Aluminum & Glass', icon: '🪟', isActive: true } }),
  ]);
  console.log(`✅ ${specialties.length} specialties created`);

  // ── Admin user ──────────────────────────────────────────────────────────
  const admin = await prisma.user.upsert({
    where: { email: 'admin@harfidar.dz' },
    update: {},
    create: {
      email: 'admin@harfidar.dz', firstName: 'مدير', lastName: 'النظام',
      passwordHash: HASH, phone: '+213550000000',
      role: 'ADMIN', status: 'ACTIVE', isEmailVerified: true,
    },
  });

  // ── Regular users ─────────────────────────────────────────────────────────
  const userDefs = [
    { id: 'u1', email: 'karim@harfidar.dz', first: 'كريم', last: 'بوعزة', phone: '+213551111001' },
    { id: 'u2', email: 'fatima@harfidar.dz', first: 'فاطمة', last: 'بن علي', phone: '+213551111002' },
    { id: 'u3', email: 'youssef@harfidar.dz', first: 'يوسف', last: 'حمداوي', phone: '+213551111003' },
    { id: 'u4', email: 'amina@harfidar.dz', first: 'أمينة', last: 'مزاري', phone: '+213551111004' },
    { id: 'u5', email: 'omar@harfidar.dz', first: 'عمر', last: 'بلحاج', phone: '+213551111005' },
    { id: 'u6', email: 'sara@harfidar.dz', first: 'سارة', last: 'قاسمي', phone: '+213551111006' },
    { id: 'u7', email: 'riad@harfidar.dz', first: 'رياض', last: 'سعيداني', phone: '+213551111007' },
    { id: 'u8', email: 'nadia@harfidar.dz', first: 'نادية', last: 'بوكراع', phone: '+213551111008' },
    { id: 'u9', email: 'ziad@harfidar.dz', first: 'زياد', last: 'عيساوي', phone: '+213551111009' },
    { id: 'u10', email: 'lina@harfidar.dz', first: 'لينا', last: 'هاشمي', phone: '+213551111010' },
  ];

  const users = await Promise.all(
    userDefs.map(u =>
      prisma.user.upsert({
        where: { email: u.email },
        update: {},
        create: {
          id: u.id, email: u.email,
          firstName: u.first, lastName: u.last,
          passwordHash: HASH, phone: u.phone,
          role: 'USER', status: 'ACTIVE', isEmailVerified: true,
        },
      })
    )
  );
  console.log(`✅ ${users.length + 1} users created (including admin)`);

  // ── Craftsman users ────────────────────────────────────────────────────────
  const craftsmanDefs = [
    { id: 'cu1', email: 'hassan.plumb@harfidar.dz', first: 'حسان', last: 'مبروك', phone: '+213561000001', sp: 'sp_plumb', wilaya: 'W16', city: 'الجزائر العاصمة', bio: 'خبرة 15 سنة في أعمال السباكة المنزلية والتجارية', years: 15, biz: 'حسان للسباكة', rating: 4.8, reviews: 45 },
    { id: 'cu2', email: 'ali.elec@harfidar.dz', first: 'علي', last: 'جابر', phone: '+213561000002', sp: 'sp_elec', wilaya: 'W16', city: 'بولوغين', bio: 'كهربائي معتمد للمشاريع السكنية والصناعية', years: 12, biz: 'علي للكهرباء', rating: 4.9, reviews: 67 },
    { id: 'cu3', email: 'mahmoud.paint@harfidar.dz', first: 'محمود', last: 'بن صالح', phone: '+213561000003', sp: 'sp_paint', wilaya: 'W16', city: 'المحمدية', bio: 'متخصص في الدهان الديكوري والتشطيب الراقي', years: 8, biz: 'محمود للدهان', rating: 4.6, reviews: 32 },
    { id: 'cu4', email: 'yacine.tile@harfidar.dz', first: 'ياسين', last: 'تلمساني', phone: '+213561000004', sp: 'sp_tile', wilaya: 'W13', city: 'تلمسان', bio: 'خبرة 10 سنوات في التبليط والسيراميك الإيطالي', years: 10, biz: 'ياسين للسيراميك', rating: 4.7, reviews: 28 },
    { id: 'cu5', email: 'omar.carp@harfidar.dz', first: 'عمر', last: 'بن حمو', phone: '+213561000005', sp: 'sp_carpent', wilaya: 'W31', city: 'وهران', bio: 'نجار خبير في الأثاث المنزلي والأبواب والنوافذ', years: 20, biz: 'ورشة بن حمو للنجارة', rating: 4.5, reviews: 89 },
    { id: 'cu6', email: 'sofiane.ac@harfidar.dz', first: 'سفيان', last: 'نور الدين', phone: '+213561000006', sp: 'sp_ac', wilaya: 'W16', city: 'حيدرة', bio: 'تركيب وصيانة مكيفات جميع الماركات', years: 6, biz: 'سفيان للتكييف', rating: 4.4, reviews: 54 },
    { id: 'cu7', email: 'kamel.mason@harfidar.dz', first: 'كامل', last: 'دراجي', phone: '+213561000007', sp: 'sp_mason', wilaya: 'W25', city: 'قسنطينة', bio: 'بناء وترميم المساكن، خبرة 18 سنة', years: 18, biz: 'دراجي للبناء', rating: 4.6, reviews: 41 },
    { id: 'cu8', email: 'hichem.weld@harfidar.dz', first: 'هشام', last: 'عمراني', phone: '+213561000008', sp: 'sp_weld', wilaya: 'W31', city: 'وهران', bio: 'حداد ملحام، أبواب وشبابيك وقضبان أمنية', years: 14, biz: 'عمراني للحدادة', rating: 4.3, reviews: 23 },
    { id: 'cu9', email: 'mourad.clean@harfidar.dz', first: 'مراد', last: 'بلقاسم', phone: '+213561000009', sp: 'sp_clean', wilaya: 'W16', city: 'باب الزوار', bio: 'خدمات تنظيف احترافي للشقق والمكاتب والمصانع', years: 5, biz: 'مراد للتنظيف', rating: 4.2, reviews: 76 },
    { id: 'cu10', email: 'reda.alum@harfidar.dz', first: 'رضا', last: 'بوضياف', phone: '+213561000010', sp: 'sp_alum', wilaya: 'W09', city: 'البليدة', bio: 'ألومنيوم وزجاج للمشاريع السكنية والتجارية', years: 9, biz: 'بوضياف للألومنيوم', rating: 4.7, reviews: 19 },
    { id: 'cu11', email: 'farid.plumb2@harfidar.dz', first: 'فريد', last: 'حاج سعيد', phone: '+213561000011', sp: 'sp_plumb', wilaya: 'W25', city: 'قسنطينة', bio: 'سباك معتمد، إصلاح التسربات وتركيب حمامات', years: 11, biz: 'حاج سعيد للسباكة', rating: 4.5, reviews: 38 },
    { id: 'cu12', email: 'abdo.elec2@harfidar.dz', first: 'عبدو', last: 'خلفاوي', phone: '+213561000012', sp: 'sp_elec', wilaya: 'W09', city: 'البليدة', bio: 'كهربائي منازل وتركيب ألواح شمسية', years: 7, biz: 'خلفاوي للكهرباء', rating: 4.6, reviews: 29 },
    { id: 'cu13', email: 'nabil.paint2@harfidar.dz', first: 'نبيل', last: 'غروف', phone: '+213561000013', sp: 'sp_paint', wilaya: 'W31', city: 'وهران', bio: 'دهان وتشطيب داخلي وخارجي بأسعار مناسبة', years: 9, biz: 'غروف للدهان', rating: 4.4, reviews: 51 },
    { id: 'cu14', email: 'lyes.tile2@harfidar.dz', first: 'ليث', last: 'معاش', phone: '+213561000014', sp: 'sp_tile', wilaya: 'W16', city: 'الجزائر العاصمة', bio: 'تركيب باركيه وسيراميك وموزاييك', years: 13, biz: 'معاش للباركيه', rating: 4.8, reviews: 62 },
    { id: 'cu15', email: 'walid.carp2@harfidar.dz', first: 'وليد', last: 'بوشاشي', phone: '+213561000015', sp: 'sp_carpent', wilaya: 'W16', city: 'دار البيضاء', bio: 'نجار للمطابخ والخزائن المدمجة حسب الطلب', years: 16, biz: 'بوشاشي للمطابخ', rating: 4.9, reviews: 73 },
    { id: 'cu16', email: 'anis.ac2@harfidar.dz', first: 'أنيس', last: 'دحماني', phone: '+213561000016', sp: 'sp_ac', wilaya: 'W25', city: 'قسنطينة', bio: 'تركيب وصيانة تكييف مركزي وسبليت', years: 8, biz: 'دحماني للتكييف', rating: 4.3, reviews: 44 },
    { id: 'cu17', email: 'larbi.mason2@harfidar.dz', first: 'العربي', last: 'زروق', phone: '+213561000017', sp: 'sp_mason', wilaya: 'W16', city: 'الحراش', bio: 'بناء وترميم وتشطيب، ضمان العمل', years: 22, biz: 'زروق للبناء والترميم', rating: 4.7, reviews: 57 },
    { id: 'cu18', email: 'hamza.weld2@harfidar.dz', first: 'حمزة', last: 'صحراوي', phone: '+213561000018', sp: 'sp_weld', wilaya: 'W16', city: 'الجزائر العاصمة', bio: 'حداد ولحام MIG/TIG للمشاريع الصناعية', years: 10, biz: 'صحراوي للحدادة', rating: 4.5, reviews: 16 },
    { id: 'cu19', email: 'nacer.alum2@harfidar.dz', first: 'ناصر', last: 'بن غبريط', phone: '+213561000019', sp: 'sp_alum', wilaya: 'W31', city: 'وهران', bio: 'نوافذ وأبواب ألومنيوم وزجاج مزدوج', years: 12, biz: 'بن غبريط للألومنيوم', rating: 4.6, reviews: 33 },
    { id: 'cu20', email: 'samir.clean2@harfidar.dz', first: 'سامر', last: 'بن يحيى', phone: '+213561000020', sp: 'sp_clean', wilaya: 'W25', city: 'قسنطينة', bio: 'تنظيف عميق للفلل والمكاتب بمعدات حديثة', years: 4, biz: 'بن يحيى للتنظيف', rating: 4.1, reviews: 22 },
  ];

  let craftsmanCount = 0;
  for (const cd of craftsmanDefs) {
    const u = await prisma.user.upsert({
      where: { email: cd.email },
      update: {},
      create: {
        id: cd.id, email: cd.email,
        firstName: cd.first, lastName: cd.last,
        passwordHash: HASH, phone: cd.phone,
        role: 'CRAFTSMAN', status: 'ACTIVE', isEmailVerified: true,
      },
    });
    await prisma.craftsman.upsert({
      where: { userId: u.id },
      update: {},
      create: {
        userId: u.id, specialtyId: cd.sp,
        bio: cd.bio, yearsExperience: cd.years,
        wilaya: cd.wilaya as any,
        city: cd.city,
        businessName: cd.biz,
        whatsappNumber: cd.phone,
        businessPhone: cd.phone,
        status: 'VERIFIED',
        isAvailable: true,
        avgRating: cd.rating,
        totalReviews: cd.reviews,
      },
    });
    craftsmanCount++;
  }
  console.log(`✅ ${craftsmanCount} craftsmen created`);

  // ── Property listings ─────────────────────────────────────────────────────
  const listingDefs = [
    { oid: 'u1', title: 'شقة فاخرة في حيدرة', type: 'APARTMENT', price: 75000, wilaya: 'W16', city: 'حيدرة', rooms: 4, bath: 2, area: 120, fur: true, park: true, elev: true, bal: true, desc: 'شقة راقية في قلب حيدرة، إطلالة بانورامية، مؤثثة بالكامل بأثاث عصري' },
    { oid: 'u2', title: 'شقة 3 غرف ببولوغين', type: 'APARTMENT', price: 45000, wilaya: 'W16', city: 'بولوغين', rooms: 3, bath: 1, area: 85, fur: false, park: false, elev: false, bal: true, desc: 'شقة هادئة بالطابق الثالث، قريبة من المواصلات العامة' },
    { oid: 'u3', title: 'فيلا مع حديقة في الدار البيضاء', type: 'VILLA', price: 150000, wilaya: 'W16', city: 'الدار البيضاء', rooms: 6, bath: 3, area: 300, fur: true, park: true, elev: false, bal: true, desc: 'فيلا فاخرة بحديقة واسعة، مسبح، 3 طوابق، مثالية للعائلات الكبيرة' },
    { oid: 'u4', title: 'استوديو مفروش بالجزائر العاصمة', type: 'STUDIO', price: 25000, wilaya: 'W16', city: 'الجزائر العاصمة', rooms: 1, bath: 1, area: 35, fur: true, park: false, elev: true, bal: false, desc: 'استوديو مجهز بالكامل، مثالي للطلاب والموظفين' },
    { oid: 'u5', title: 'شقة عائلية في تلمسان', type: 'APARTMENT', price: 35000, wilaya: 'W13', city: 'تلمسان', rooms: 4, bath: 2, area: 110, fur: false, park: true, elev: false, bal: true, desc: 'شقة واسعة في حي هادئ، قريبة من المدارس والمستشفى' },
    { oid: 'u6', title: 'محل تجاري في وهران', type: 'COMMERCIAL', price: 80000, wilaya: 'W31', city: 'وهران', rooms: 2, bath: 1, area: 60, fur: false, park: true, elev: false, bal: false, desc: 'محل تجاري في شارع رئيسي، واجهة 8 متر، مناسب لجميع الأنشطة' },
    { oid: 'u7', title: 'شقة 2 غرف في قسنطينة', type: 'APARTMENT', price: 30000, wilaya: 'W25', city: 'قسنطينة', rooms: 2, bath: 1, area: 65, fur: false, park: false, elev: true, bal: false, desc: 'شقة بسيطة ونظيفة، الطابق الخامس بمصعد' },
    { oid: 'u8', title: 'بيت مستقل في البليدة', type: 'HOUSE', price: 60000, wilaya: 'W09', city: 'البليدة', rooms: 5, bath: 2, area: 180, fur: false, park: true, elev: false, bal: true, desc: 'بيت مستقل بحديقة صغيرة، قريب من غابة الأرز' },
    { oid: 'u9', title: 'شقة مطلة على البحر بعنابة', type: 'APARTMENT', price: 55000, wilaya: 'W23', city: 'عنابة', rooms: 3, bath: 2, area: 95, fur: true, park: false, elev: true, bal: true, desc: 'شقة مطلة مباشرة على البحر المتوسط، إطلالة خلابة' },
    { oid: 'u10', title: 'فيلا بتيبازة على البحر', type: 'VILLA', price: 200000, wilaya: 'W42', city: 'تيبازة', rooms: 7, bath: 4, area: 400, fur: true, park: true, elev: false, bal: true, desc: 'فيلا بأجمل موقع، فندقية التجهيز، مسبح خاص مطل على البحر' },
    { oid: 'u1', title: 'شقة 3 غرف في سيدي بلعباس', type: 'APARTMENT', price: 28000, wilaya: 'W22', city: 'سيدي بلعباس', rooms: 3, bath: 1, area: 75, fur: false, park: false, elev: false, bal: true, desc: 'شقة عائلية في حي راقي، قريبة من الجامعة' },
    { oid: 'u2', title: 'استوديو للطلاب في قسنطينة', type: 'STUDIO', price: 18000, wilaya: 'W25', city: 'قسنطينة', rooms: 1, bath: 1, area: 28, fur: true, park: false, elev: false, bal: false, desc: 'استوديو صغير ومريح، قريب من الجامعة الإسلامية' },
    { oid: 'u3', title: 'مكتب تجاري في حيدرة', type: 'COMMERCIAL', price: 120000, wilaya: 'W16', city: 'حيدرة', rooms: 4, bath: 2, area: 150, fur: true, park: true, elev: true, bal: false, desc: 'مكتب احترافي في مبنى إداري راقي، جاهز للاستعمال' },
    { oid: 'u4', title: 'شقة في وهران المدينة', type: 'APARTMENT', price: 40000, wilaya: 'W31', city: 'وهران', rooms: 3, bath: 2, area: 90, fur: true, park: false, elev: true, bal: true, desc: 'شقة في وسط المدينة، قريبة من الميناء والمركز التجاري' },
    { oid: 'u5', title: 'بيت عائلي في عين تيموشنت', type: 'HOUSE', price: 45000, wilaya: 'W46', city: 'عين تيموشنت', rooms: 4, bath: 2, area: 150, fur: false, park: true, elev: false, bal: true, desc: 'بيت عائلي كبير في هدوء تام، حديقة وتيراس' },
    { oid: 'u6', title: 'شقة 4 غرف في باب الزوار', type: 'APARTMENT', price: 38000, wilaya: 'W16', city: 'باب الزوار', rooms: 4, bath: 2, area: 100, fur: false, park: false, elev: false, bal: true, desc: 'شقة فسيحة في حي عائلي راقٍ، الطابق الثاني' },
    { oid: 'u7', title: 'استوديو في الجزائر العاصمة', type: 'STUDIO', price: 22000, wilaya: 'W16', city: 'الجزائر العاصمة', rooms: 1, bath: 1, area: 32, fur: true, park: false, elev: true, bal: false, desc: 'استوديو بموقع استراتيجي، قريب من المترو' },
    { oid: 'u8', title: 'شقة 2 غرف في البليدة', type: 'APARTMENT', price: 25000, wilaya: 'W09', city: 'البليدة', rooms: 2, bath: 1, area: 60, fur: false, park: false, elev: false, bal: false, desc: 'شقة هادئة في حي السلام، بالقرب من الحديقة العامة' },
    { oid: 'u9', title: 'فيلا فخمة في سطيف', type: 'VILLA', price: 120000, wilaya: 'W19', city: 'سطيف', rooms: 6, bath: 3, area: 350, fur: false, park: true, elev: false, bal: true, desc: 'فيلا حديثة في أرقى أحياء سطيف، بناء 2022' },
    { oid: 'u10', title: 'محل في سوق السكوارة وهران', type: 'COMMERCIAL', price: 55000, wilaya: 'W31', city: 'وهران', rooms: 1, bath: 1, area: 40, fur: false, park: false, elev: false, bal: false, desc: 'محل تجاري في سوق نشط، موقع ممتاز وزبائن دائمون' },
    { oid: 'u1', title: 'شقة حديثة في الشراقة', type: 'APARTMENT', price: 52000, wilaya: 'W16', city: 'الشراقة', rooms: 3, bath: 2, area: 88, fur: true, park: true, elev: true, bal: true, desc: 'شقة محدودة الاستعمال، بناء 2020، جميع المرافق متوفرة' },
    { oid: 'u2', title: 'شقة بالمدية', type: 'APARTMENT', price: 20000, wilaya: 'W26', city: 'المدية', rooms: 3, bath: 1, area: 70, fur: false, park: false, elev: false, bal: true, desc: 'شقة بسيطة ومريحة في الطابق الأول' },
    { oid: 'u3', title: 'شقة 5 غرف في القبة', type: 'APARTMENT', price: 65000, wilaya: 'W16', city: 'القبة', rooms: 5, bath: 3, area: 145, fur: true, park: true, elev: true, bal: true, desc: 'شقة فاخرة في حي القبة العريق، مجهزة بالكامل' },
    { oid: 'u4', title: 'بيت في برج بوعريريج', type: 'HOUSE', price: 35000, wilaya: 'W34', city: 'برج بوعريريج', rooms: 4, bath: 2, area: 130, fur: false, park: true, elev: false, bal: false, desc: 'بيت واسع وهادئ، مناسب للعائلة الكبيرة' },
    { oid: 'u5', title: 'شقة مفروشة في تيزي وزو', type: 'APARTMENT', price: 32000, wilaya: 'W15', city: 'تيزي وزو', rooms: 2, bath: 1, area: 55, fur: true, park: false, elev: false, bal: false, desc: 'شقة في مركز المدينة، قريبة من الجامعة ومرافق الحياة اليومية' },
    { oid: 'u6', title: 'شقة في بجاية', type: 'APARTMENT', price: 42000, wilaya: 'W06', city: 'بجاية', rooms: 3, bath: 2, area: 80, fur: false, park: false, elev: true, bal: true, desc: 'شقة إطلالة على البحر الأبيض المتوسط، قريبة من الشاطئ' },
    { oid: 'u7', title: 'محل تجاري في الحراش', type: 'COMMERCIAL', price: 65000, wilaya: 'W16', city: 'الحراش', rooms: 2, bath: 1, area: 50, fur: false, park: false, elev: false, bal: false, desc: 'محل على الشارع الرئيسي، واجهة زجاجية، مناسب لمطعم أو صيدلية' },
    { oid: 'u8', title: 'شقة في مستغانم', type: 'APARTMENT', price: 28000, wilaya: 'W29', city: 'مستغانم', rooms: 3, bath: 1, area: 72, fur: false, park: true, elev: false, bal: true, desc: 'شقة في حي جديد قريبة من الشاطئ' },
    { oid: 'u9', title: 'فيلا في بسكرة', type: 'VILLA', price: 80000, wilaya: 'W07', city: 'بسكرة', rooms: 5, bath: 3, area: 250, fur: false, park: true, elev: false, bal: true, desc: 'فيلا فسيحة في مدينة بسكرة، بساتين نخيل محيطة' },
    { oid: 'u10', title: 'استوديو للموظفين في وهران', type: 'STUDIO', price: 20000, wilaya: 'W31', city: 'وهران', rooms: 1, bath: 1, area: 30, fur: true, park: false, elev: false, bal: false, desc: 'استوديو مثالي للموظف، قريب من المستشفى الجامعي' },
    { oid: 'u1', title: 'شقة 3 غرف في تيبازة', type: 'APARTMENT', price: 48000, wilaya: 'W42', city: 'تيبازة', rooms: 3, bath: 2, area: 92, fur: true, park: false, elev: false, bal: true, desc: 'شقة قريبة من الشاطئ، تُستأجر للصيف والشتاء' },
  ];

  let listingCount = 0;
  const userMap: Record<string, string> = {};
  for (const u of users) userMap[`u${users.indexOf(u) + 1}`] = u.id;

  for (const ld of listingDefs) {
    const ownerId = userMap[ld.oid] ?? users[0].id;
    await prisma.propertyListing.create({
      data: {
        ownerId,
        title: ld.title,
        description: ld.desc,
        type: ld.type as any,
        status: 'ACTIVE',
        price: ld.price,
        pricePeriod: 'monthly',
        wilaya: ld.wilaya as any,
        city: ld.city,
        rooms: ld.rooms,
        bathrooms: ld.bath,
        area: ld.area,
        isFurnished: ld.fur,
        hasParking: ld.park,
        hasElevator: ld.elev,
        hasBalcony: ld.bal,
        isAvailable: true,
        publishedAt: new Date(),
        avgRating: +(Math.random() * 1.5 + 3.5).toFixed(1),
        totalReviews: Math.floor(Math.random() * 20),
        viewCount: Math.floor(Math.random() * 200),
        images: {
          create: [
            {
              url: `https://picsum.photos/seed/${ld.title.slice(0, 5)}/800/600`,
              publicId: `listings/${Date.now()}`,
              isCover: true,
              order: 0,
            },
          ],
        },
      },
    });
    listingCount++;
  }
  console.log(`✅ ${listingCount} property listings created`);

  // ── Sample reviews ────────────────────────────────────────────────────────
  const craftsmen = await prisma.craftsman.findMany({ take: 5 });
  const listings = await prisma.propertyListing.findMany({ take: 5 });

  let reviewCount = 0;
  for (let i = 0; i < Math.min(craftsmen.length, users.length); i++) {
    await prisma.review.create({
      data: {
        reviewerId: users[i].id,
        craftsmanId: craftsmen[i % craftsmen.length].id,
        rating: [4, 5, 5, 4, 3][i % 5],
        comment: ['عمل ممتاز وسريع', 'محترف جداً أنصح به', 'راضٍ عن الخدمة', 'سعر مناسب وجودة جيدة', 'عمل جيد لكن تأخر قليلاً'][i % 5],
        isVerified: true,
      },
    });
    reviewCount++;
  }
  for (let i = 0; i < Math.min(listings.length, users.length); i++) {
    await prisma.review.create({
      data: {
        reviewerId: users[(i + 3) % users.length].id,
        listingId: listings[i % listings.length].id,
        rating: [5, 4, 4, 5, 3][i % 5],
        comment: ['شقة رائعة وصاحبها محترم', 'مكان هادئ وموقع ممتاز', 'كما هو موصوف تماماً', 'سعر مناسب وجودة الشقة جيدة', 'مقبول لكن يحتاج صيانة'][i % 5],
        isVerified: true,
      },
    });
    reviewCount++;
  }
  console.log(`✅ ${reviewCount} reviews created`);

  console.log('\n🎉 Seeding complete!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('Test credentials (password: HarfiDar2024!):');
  console.log('  Admin:    admin@harfidar.dz');
  console.log('  User:     karim@harfidar.dz');
  console.log('  User:     fatima@harfidar.dz');
  console.log('  Craftsman: hassan.plumb@harfidar.dz');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

main()
  .catch(e => { console.error('❌ Seed failed:', e); process.exit(1); })
  .finally(() => prisma.$disconnect());
