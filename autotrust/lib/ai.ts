import { openai } from '@ai-sdk/openai';
import { generateText } from 'ai';

interface CarData {
  make: string;
  model: string;
  year: number;
  condition: string;
  fuel: string;
  transmission: string;
  mileage: number;
  price: number;
  power?: number;
  engineSize?: number;
  color?: string;
}

export async function generateCarDescription(car: CarData): Promise<string> {
  if (!process.env.OPENAI_API_KEY) {
    return `${car.make} ${car.model} ${car.year} — ${car.condition === 'NEW' ? 'Véhicule neuf' : 'Véhicule d\'occasion'}. Motorisation ${car.fuel.toLowerCase()}, boîte ${car.transmission.toLowerCase()}. ${car.mileage > 0 ? `Kilométrage: ${car.mileage.toLocaleString()} km.` : ''} Prix: ${car.price.toLocaleString()} DA.`;
  }

  const { text } = await generateText({
    model: openai('gpt-4o-mini'),
    prompt: `Génère une description professionnelle et attrayante pour cette voiture à vendre en Algérie (2-3 paragraphes, en français):
      - Marque/Modèle: ${car.make} ${car.model} ${car.year}
      - État: ${car.condition === 'NEW' ? 'Neuve' : 'Occasion'}
      - Carburant: ${car.fuel}
      - Boîte: ${car.transmission}
      - Kilométrage: ${car.mileage} km
      - Puissance: ${car.power ?? 'N/A'} ch
      - Prix: ${car.price.toLocaleString()} DA
      Sois professionnel, persuasif et mets en avant les points forts.`,
    maxTokens: 400,
  });

  return text;
}

export async function suggestMarketPrice(car: { make: string; model: string; year: number; condition: string; mileage: number }): Promise<{ min: number; max: number; suggested: number }> {
  if (!process.env.OPENAI_API_KEY) {
    return { min: 1500000, max: 5000000, suggested: 3000000 };
  }

  const { text } = await generateText({
    model: openai('gpt-4o-mini'),
    prompt: `Estime le prix de marché en DZD pour cette voiture en Algérie: ${car.make} ${car.model} ${car.year}, état: ${car.condition}, kilométrage: ${car.mileage}km. Réponds UNIQUEMENT en JSON: {"min": number, "max": number, "suggested": number}`,
    maxTokens: 100,
  });

  try {
    return JSON.parse(text.match(/\{.*\}/s)?.[0] ?? '{}');
  } catch {
    return { min: 1500000, max: 5000000, suggested: 3000000 };
  }
}

export async function generateSeoMeta(car: { make: string; model: string; year: number; condition: string; price: number }): Promise<{ title: string; description: string }> {
  const condition = car.condition === 'NEW' ? 'Neuve' : 'Occasion';
  return {
    title: `${car.make} ${car.model} ${car.year} ${condition} — AutoTrust Algérie`,
    description: `Achetez ${car.make} ${car.model} ${car.year} ${condition.toLowerCase()} en Algérie à ${car.price.toLocaleString()} DA. Financement disponible. Garantie AutoTrust. Drive With Confidence.`,
  };
}

export async function summarizeLeads(leads: Array<{ name: string; message?: string | null; status: string }>): Promise<string> {
  if (!process.env.OPENAI_API_KEY || leads.length === 0) {
    return `${leads.length} lead(s) en attente de traitement.`;
  }

  const { text } = await generateText({
    model: openai('gpt-4o-mini'),
    prompt: `Résume ces demandes clients en 2-3 phrases pour un manager commercial: ${JSON.stringify(leads.slice(0, 10))}`,
    maxTokens: 150,
  });

  return text;
}
