import '../../../core/api/api_client.dart';
import '../../../core/auth/partner_session.dart';

class PartnerMenuItem {
  final String id;
  final String name;
  final String? category;
  final double price;
  final bool isVeg;
  final bool isBestseller;
  final String status;
  final String? description;
  final String? imageUrl;

  PartnerMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.status,
    this.category,
    this.isVeg = false,
    this.isBestseller = false,
    this.description,
    this.imageUrl,
  });

  PartnerMenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isVeg,
    bool? isBestseller,
    String? status,
    String? description,
    String? imageUrl,
  }) {
    return PartnerMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      isBestseller: isBestseller ?? this.isBestseller,
      status: status ?? this.status,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static PartnerMenuItem fromJson(Map<String, dynamic> j) {
    return PartnerMenuItem(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      category: j['category']?.toString(),
      price: (j['price'] as num?)?.toDouble() ?? 0,
      status: j['status']?.toString() ?? 'Available',
      isVeg: (j['is_veg'] as bool?) ?? false,
      isBestseller: (j['is_bestseller'] as bool?) ?? false,
      description: j['description']?.toString(),
      imageUrl: j['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toUpsertJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'category': category,
      'price': price,
      'status': status,
      'is_veg': isVeg,
      'is_bestseller': isBestseller,
      'description': description,
      'image_url': imageUrl,
    };
  }
}

class PartnerMenuApi {
  final _client = ApiClient();
  String get _restId => PartnerSession().restaurantId ?? '';

  Future<List<PartnerMenuItem>> list() async {
    final json = await _client.get('/v1/restaurants/$_restId/menu') as Map<String, dynamic>;
    final items = ((json['data'] as Map?)?['items'] as List<dynamic>? ?? []);
    return items.whereType<Map>().map((m) => PartnerMenuItem.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<PartnerMenuItem>> upsert(List<PartnerMenuItem> items) async {
    final payload = {
      'upserts': items.map((e) => e.toUpsertJson()).toList(),
      'deletes': [],
    };
    final json = await _client.put('/v1/partner/menu', body: payload) as Map<String, dynamic>;
    final list = ((json['data'] as Map?)?['items'] as List<dynamic>? ?? []);
    return list.whereType<Map>().map((m) => PartnerMenuItem.fromJson(Map<String, dynamic>.from(m))).toList();
  }

  Future<List<PartnerMenuItem>> deleteIds(List<String> ids) async {
    final payload = {'upserts': [], 'deletes': ids};
    final json = await _client.put('/v1/partner/menu', body: payload) as Map<String, dynamic>;
    final list = ((json['data'] as Map?)?['items'] as List<dynamic>? ?? []);
    return list.whereType<Map>().map((m) => PartnerMenuItem.fromJson(Map<String, dynamic>.from(m))).toList();
  }
}
