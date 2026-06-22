import { PrismaClient, CarCondition, FuelType, Transmission, CarStatus, UserRole } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

const cars = [
  {
    make: 'Toyota', model: 'Camry', year: 2024, price: 4500000,
    condition: CarCondition.NEW, fuel: FuelType.ESSENCE, transmission: Transmission.AUTOMATIQUE,
    color: 'Blanc Perle', doors: 4, seats: 5, power: 203, engineSize: 2.5,
    featured: true, status: CarStatus.AVAILABLE, mileage: 0,
    slug: 'toyota-camry-2024',
    description: 'Toyota Camry 2024, la berline référence alliant confort, fiabilité et élégance.',
    metaTitle: 'Toyota Camry 2024 — AutoTrust Algérie',
    metaDesc: 'Achetez la Toyota Camry 2024 neuve en Algérie. Financement disponible.',
    images: [
      { url: 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800', isPrimary: true, order: 0 },
      { url: 'https://images.unsplash.com/photo-1617886903355-9354bb57b7a7?w=800', isPrimary: false, order: 1 },
    ]
  },
  {
    make: 'BMW', model: 'X5', year: 2023, price: 9800000,
    condition: CarCondition.USED, fuel: FuelType.DIESEL, transmission: Transmission.AUTOMATIQUE,
    color: 'Noir Saphir', doors: 5, seats: 5, power: 265, engineSize: 3.0,
    featured: true, status: CarStatus.AVAILABLE, mileage: 35000,
    slug: 'bmw-x5-2023',
    description: 'BMW X5 2023 en excellent état. Véhicule d\'occasion certifié avec garantie constructeur.',
    metaTitle: 'BMW X5 2023 Occasion — AutoTrust',
    metaDesc: 'BMW X5 2023 occasion certifiée. Excellent état, faible kilométrage.',
    images: [
      { url: 'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=800', isPrimary: true, order: 0 },
      { url: 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800', isPrimary: false, order: 1 },
    ]
  },
  {
    make: 'Mercedes-Benz', model: 'C200', year: 2024, price: 7200000,
    condition: CarCondition.NEW, fuel: FuelType.ESSENCE, transmission: Transmission.AUTOMATIQUE,
    color: 'Gris Graphite', doors: 4, seats: 5, power: 204, engineSize: 2.0,
    featured: true, status: CarStatus.AVAILABLE, mileage: 0,
    slug: 'mercedes-c200-2024',
    description: 'Mercedes-Benz C200 2024, le summum du luxe allemand avec les dernières technologies.',
    metaTitle: 'Mercedes C200 2024 — AutoTrust Algérie',
    metaDesc: 'Mercedes-Benz C200 2024 neuve en Algérie. Financement facile.',
    images: [
      { url: 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800', isPrimary: true, order: 0 },
    ]
  },
  {
    make: 'Hyundai', model: 'Tucson', year: 2024, price: 3800000,
    condition: CarCondition.NEW, fuel: FuelType.HYBRIDE, transmission: Transmission.AUTOMATIQUE,
    color: 'Rouge', doors: 5, seats: 5, power: 180, engineSize: 1.6,
    featured: false, status: CarStatus.AVAILABLE, mileage: 0,
    slug: 'hyundai-tucson-2024',
    description: 'Hyundai Tucson 2024 Hybride, le SUV moderne et économique parfait pour l\'Algérie.',
    metaTitle: 'Hyundai Tucson 2024 Hybride — AutoTrust',
    metaDesc: 'Hyundai Tucson 2024 hybride neuf. Économique et moderne.',
    images: [
      { url: 'https://images.unsplash.com/photo-1609521263047-f8f205293f24?w=800', isPrimary: true, order: 0 },
    ]
  },
  {
    make: 'Volkswagen', model: 'Golf 8', year: 2023, price: 3200000,
    condition: CarCondition.USED, fuel: FuelType.ESSENCE, transmission: Transmission.MANUELLE,
    color: 'Bleu', doors: 5, seats: 5, power: 130, engineSize: 1.5,
    featured: false, status: CarStatus.AVAILABLE, mileage: 18000,
    slug: 'volkswagen-golf-8-2023',
    description: 'Volkswagen Golf 8 2023 en très bon état. Faible kilométrage, carnet d\'entretien complet.',
    metaTitle: 'Volkswagen Golf 8 2023 Occasion — AutoTrust',
    metaDesc: 'Golf 8 2023 occasion en excellent état.',
    images: [
      { url: 'https://images.unsplash.com/photo-1635273051427-40cd6da00a7e?w=800', isPrimary: true, order: 0 },
    ]
  },
  {
    make: 'Kia', model: 'Sportage', year: 2024, price: 4200000,
    condition: CarCondition.NEW, fuel: FuelType.DIESEL, transmission: Transmission.AUTOMATIQUE,
    color: 'Argent', doors: 5, seats: 5, power: 136, engineSize: 1.6,
    featured: true, status: CarStatus.AVAILABLE, mileage: 0,
    slug: 'kia-sportage-2024',
    description: 'Kia Sportage 2024, le SUV coréen aux lignes audacieuses et technologies avancées.',
    metaTitle: 'Kia Sportage 2024 — AutoTrust Algérie',
    metaDesc: 'Kia Sportage 2024 neuf. Design moderne, technologies de pointe.',
    images: [
      { url: 'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=800', isPrimary: true, order: 0 },
    ]
  },
  {
    make: 'Renault', model: 'Clio 5', year: 2023, price: 1950000,
    condition: CarCondition.NEW, fuel: FuelType.ESSENCE, transmission: Transmission.MANUELLE,
    color: 'Blanc', doors: 5, seats: 5, power: 90, engineSize: 1.0,
    featured: false, status: CarStatus.AVAILABLE, mileage: 0,
    slug: 'renault-clio-5-2023',
    description: 'Renault Clio 5 2023, citadine moderne et accessible, idéale pour la ville.',
    metaTitle: 'Renault Clio 5 2023 — AutoTrust',
    metaDesc: 'Renault Clio 5 neuve. Citadine moderne au meilleur prix.',
    images: [
      { url: 'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?w=800', isPrimary: true, order: 0 },
    ]
  },
  {
    make: 'Audi', model: 'A4', year: 2022, price: 5500000,
    condition: CarCondition.USED, fuel: FuelType.DIESEL, transmission: Transmission.AUTOMATIQUE,
    color: 'Gris', doors: 4, seats: 5, power: 163, engineSize: 2.0,
    featured: false, status: CarStatus.AVAILABLE, mileage: 45000,
    slug: 'audi-a4-2022',
    description: 'Audi A4 2022 occasion, le luxe à l\'allemande avec un équipement haut de gamme.',
    metaTitle: 'Audi A4 2022 Occasion — AutoTrust',
    metaDesc: 'Audi A4 2022 occasion certifiée.',
    images: [
      { url: 'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?w=800', isPrimary: true, order: 0 },
    ]
  },
];

async function main() {
  console.log('🌱 Seeding AutoTrust database...');

  // Create super admin
  const hashedPassword = await bcrypt.hash('AutoTrust@2025!', 12);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@autotrust.dz' },
    update: {},
    create: {
      name: 'Super Admin',
      email: 'admin@autotrust.dz',
      password: hashedPassword,
      role: UserRole.SUPER_ADMIN,
    },
  });
  console.log('✅ Admin created:', admin.email);

  // Create sales manager
  await prisma.user.upsert({
    where: { email: 'sales@autotrust.dz' },
    update: {},
    create: {
      name: 'Sales Manager',
      email: 'sales@autotrust.dz',
      password: await bcrypt.hash('Sales@2025!', 12),
      role: UserRole.SALES_MANAGER,
    },
  });

  // Create cars
  for (const carData of cars) {
    const { images, ...car } = carData;
    const created = await prisma.car.upsert({
      where: { slug: car.slug },
      update: {},
      create: {
        ...car,
        images: { create: images },
      },
    });
    console.log(`✅ Car: ${created.make} ${created.model} ${created.year}`);
  }

  // Create site settings
  const settings = [
    { key: 'site_name', value: 'AutoTrust', description: 'Nom du site' },
    { key: 'phone', value: '+213 555 123 456', description: 'Téléphone principal' },
    { key: 'email', value: 'contact@autotrust.dz', description: 'Email de contact' },
    { key: 'address', value: 'Alger, Algérie', description: 'Adresse' },
    { key: 'whatsapp', value: '+213555123456', description: 'Numéro WhatsApp' },
    { key: 'facebook', value: 'https://facebook.com/autotrust.dz', description: 'Facebook' },
    { key: 'instagram', value: 'https://instagram.com/autotrust.dz', description: 'Instagram' },
    { key: 'financing_rate', value: '8.5', description: 'Taux de financement par défaut (%)' },
    { key: 'financing_max_months', value: '60', description: 'Durée max financement (mois)' },
  ];

  for (const s of settings) {
    await prisma.siteSettings.upsert({ where: { key: s.key }, update: {}, create: s });
  }

  // Sample leads
  await prisma.lead.createMany({
    skipDuplicates: true,
    data: [
      { name: 'Mohamed Benali', phone: '0661234567', email: 'benali@email.com', message: 'Intéressé par BMW X5', source: 'website' },
      { name: 'Fatima Hadj', phone: '0771234567', email: 'fhadj@email.com', message: 'Toyota Camry — demande de prix', source: 'whatsapp' },
      { name: 'Karim Boussaad', phone: '0551234567', message: 'Financement Mercedes C200', source: 'phone' },
    ],
  });

  console.log('✅ Seed complete!');
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
