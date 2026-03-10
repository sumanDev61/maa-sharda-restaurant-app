import 'package:shared_preferences/shared_preferences.dart';

class PartnerSession {
  static const _kToken = 'partner_token';
  static const _kRestaurantId = 'partner_restaurant_id';
  static const _kApprovalStatus = 'partner_approval_status';
  static const _kRestaurantName = 'partner_restaurant_name';

  String? _token;
  String? _restaurantId;
  String? _approvalStatus;
  String? _restaurantName;

  String? get token => _token;
  String? get restaurantId => _restaurantId;
  String? get approvalStatus => _approvalStatus;
  String? get restaurantName => _restaurantName;

  static final PartnerSession _i = PartnerSession._();
  factory PartnerSession() => _i;
  PartnerSession._();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _restaurantId = prefs.getString(_kRestaurantId);
    _approvalStatus = prefs.getString(_kApprovalStatus);
    _restaurantName = prefs.getString(_kRestaurantName);
  }

  Future<void> save({
    required String token,
    required String restaurantId,
    String? approvalStatus,
    String? restaurantName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _token = token;
    _restaurantId = restaurantId;
    _approvalStatus = approvalStatus;
    _restaurantName = restaurantName;
    await prefs.setString(_kToken, token);
    await prefs.setString(_kRestaurantId, restaurantId);
    if (approvalStatus != null) {
      await prefs.setString(_kApprovalStatus, approvalStatus);
    }
    if (restaurantName != null) {
      await prefs.setString(_kRestaurantName, restaurantName);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    _token = null;
    _restaurantId = null;
    _approvalStatus = null;
    _restaurantName = null;
    await prefs.remove(_kToken);
    await prefs.remove(_kRestaurantId);
    await prefs.remove(_kApprovalStatus);
    await prefs.remove(_kRestaurantName);
  }
}
