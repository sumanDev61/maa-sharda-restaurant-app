class Env {
  static const googleApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static String get apiBaseUrl {
    const env = String.fromEnvironment('API_BASE_URL');
    if (env.isNotEmpty) return env;
    return 'https://maa-sharda-backend-production.up.railway.app';
  }
  static String get restaurantId {
    const rid = String.fromEnvironment('RESTAURANT_ID');
    if (rid.isNotEmpty) return rid;
    return '';
  }
}
