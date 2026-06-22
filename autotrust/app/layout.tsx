import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL ?? 'https://autotrust.dz'),
  title: {
    default: 'AutoTrust — Drive With Confidence',
    template: '%s | AutoTrust',
  },
  description: 'Plateforme N°1 de vente de voitures neuves et d\'occasion en Algérie. Trouvez la voiture de vos rêves avec AutoTrust.',
  keywords: ['voitures algérie', 'achat voiture', 'vente voiture', 'auto occasion', 'auto neuve'],
  authors: [{ name: 'AutoTrust' }],
  creator: 'AutoTrust',
  openGraph: {
    type: 'website',
    locale: 'fr_DZ',
    url: '/',
    siteName: 'AutoTrust',
    title: 'AutoTrust — Drive With Confidence',
    description: 'Plateforme N°1 de vente de voitures en Algérie.',
    images: [{ url: '/images/og-image.jpg', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'AutoTrust — Drive With Confidence',
    description: 'Plateforme N°1 de vente de voitures en Algérie.',
    images: ['/images/og-image.jpg'],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true, 'max-image-preview': 'large' },
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <head>
        <link rel="icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
      </head>
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}
