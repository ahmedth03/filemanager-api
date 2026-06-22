# AutoTrust — Drive With Confidence

Plateforme professionnelle de vente de voitures neuves et d'occasion en Algérie.

## Stack Technique

- **Frontend**: Next.js 15, TypeScript, Tailwind CSS
- **Backend**: Next.js API Routes
- **Base de données**: PostgreSQL + Prisma ORM
- **Auth**: NextAuth.js (JWT)
- **Upload**: Cloudinary (auto-compression + thumbnails)
- **Email**: Resend
- **IA**: OpenAI GPT-4o-mini
- **Déploiement**: Vercel / Docker

## Démarrage rapide

### Prérequis
- Node.js 20+
- PostgreSQL 14+
- Compte Cloudinary, Resend (optionnels)

### Installation

```bash
cd autotrust
npm install

# Copier et configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# Créer la base de données et migrer
npx prisma generate
npx prisma migrate dev --name init

# Charger les données de démonstration
npm run db:seed

# Démarrer en développement
npm run dev
```

Ouvrir [http://localhost:3000](http://localhost:3000)

### Administration

URL: [http://localhost:3000/admin](http://localhost:3000/admin)

| Email | Mot de passe | Rôle |
|---|---|---|
| admin@autotrust.dz | AutoTrust@2025! | Super Admin |
| sales@autotrust.dz | Sales@2025! | Sales Manager |

## Déploiement avec Docker

```bash
cp .env.example .env
# Configurer les variables requises

docker-compose up -d

# Migrer et seeder
docker-compose exec app npx prisma migrate deploy
docker-compose exec app npm run db:seed
```

## Déploiement sur Vercel

```bash
# Installer Vercel CLI
npm i -g vercel

# Déployer
vercel --prod

# Configurer les variables d'environnement dans Vercel Dashboard
# Puis migrer la DB
vercel env pull
npx prisma migrate deploy
```

## Structure du projet

```
autotrust/
├── app/
│   ├── (public)/          # Pages publiques
│   │   ├── page.tsx       # Accueil
│   │   ├── cars/          # Catalogue & détails
│   │   ├── financing/     # Financement
│   │   ├── about/         # À propos
│   │   ├── contact/       # Contact
│   │   └── faq/           # FAQ
│   ├── (admin)/           # Dashboard admin protégé
│   │   └── admin/
│   │       ├── page.tsx   # Dashboard
│   │       ├── cars/      # Gestion véhicules
│   │       ├── leads/     # Gestion leads
│   │       ├── users/     # Gestion utilisateurs
│   │       └── settings/  # Paramètres
│   ├── api/               # API Routes
│   └── auth/              # Authentification
├── components/
│   ├── public/            # Composants frontend
│   └── admin/             # Composants admin
├── lib/                   # Utilitaires (prisma, auth, cloudinary, AI...)
├── prisma/                # Schéma & seed
├── types/                 # Types TypeScript
├── docker-compose.yml
├── Dockerfile
└── vercel.json
```

## Fonctionnalités

### Site Public
- Page d'accueil avec héros, recherche, statistiques, témoignages
- Catalogue filtrable (marque, modèle, année, prix, carburant, boîte)
- Page détail voiture avec galerie, specs, calculateur financement
- Boutons WhatsApp, téléphone et formulaire de demande
- Pages: financement, à propos, contact, FAQ
- SEO: sitemap.xml, robots.txt, structured data, Open Graph

### Lοchage de contrôle Admin
- Dashboard avec stats en temps réel
- CRUD complet des véhicules avec upload multi-photos Cloudinary
- Gestion des leads avec pipeline de statuts
- Génération de descriptions IA (OpenAI)
- Paramètres du site
- Gestion des utilisateurs (Super Admin)

### Système de Leads
- Formulaire de demande sur chaque annonce
- Notification email automatique (Resend)
- Lien WhatsApp direct
- Pipeline: Nouveau → Contacté → Qualifié → Négociation → Gagné/Perdu

### Sécurité
- Rate limiting sur les formulaires
- JWT Authentication (NextAuth)
- Middleware de protection admin
- Validation des données (Zod)
