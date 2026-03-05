import 'package:shared_preferences/shared_preferences.dart';

class PartnerSession {
  static const _kToken = 'partner_token';
  static const _kRestaurantId = 'partner_restaurant_id';

  String? _token;
  String? _restaurantId;

  String? get token => _token;
  String? get restaurantId => _restaurantId;

  static final PartnerSession _i = PartnerSession._();
  factory PartnerSession() => _i;
  PartnerSession._();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _restaurantId = prefs.getString(_kRestaurantId);
  }

  Future<void> save({required String token, required String restaurantId}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _restaurantId = restaurantId;
    await prefs.setString(_kToken, token);
    await prefs.setString(_kRestaurantId, restaurantId);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _restaurantId = null;
    await prefs.remove(_kToken);
    await prefs.remove(_kRestaurantId);
  }
}
