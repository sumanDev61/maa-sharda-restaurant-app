export const Env = {
  apiBaseUrl: (import.meta as any).env?.VITE_API_BASE_URL || 'https://maa-sharda-backend-production.up.railway.app',
  restaurantId: (import.meta as any).env?.VITE_RESTAURANT_ID || '',
  googleApiKey: (import.meta as any).env?.VITE_GOOGLE_MAPS_API_KEY || '',
};
