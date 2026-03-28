import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/merchant_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/partner_session.dart';

enum _CouponVisibility { publicCoupon, privateCoupon }

class _CouponItem {
  final String id;
  final String code;
  final String title;
  final String subtitle;
  final double discount;
  final _CouponVisibility visibility;
  final String status;
  const _CouponItem({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.visibility,
    required this.status,
  });

  _CouponItem copyWith({
    String? id,
    String? code,
    String? title,
    String? subtitle,
    double? discount,
    _CouponVisibility? visibility,
    String? status,
  }) {
    return _CouponItem(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      discount: discount ?? this.discount,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
    );
  }
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final _client = ApiClient();
  bool _loading = false;
  bool _isOpen = true;
  int _deliveryMinutes = 25;
  bool _pureVeg = false;
  String _logoUrl = '';
  String _coverUrl = '';
  File? _logoFile;
  File? _coverFile;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  List<_CouponItem> _coupons = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadCoupons();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rid = PartnerSession().restaurantId ?? '';
      final json = await _client.get('/v1/restaurants/$rid') as Map<String, dynamic>;
      final data = (json['data'] as Map?) ?? {};
      final gallery = (data['gallery_image_urls'] as List?)?.whereType<String>().toList() ?? [];
      setState(() {
        _isOpen = (data['status']?.toString() ?? 'Active') == 'Active';
        _deliveryMinutes = (data['delivery_minutes'] as num?)?.toInt() ?? 25;
        _pureVeg = (data['is_pure_veg'] as bool?) ?? false;
        _logoUrl = data['image_url']?.toString() ?? '';
        _coverUrl = gallery.isNotEmpty ? gallery.first : '';
      });
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCoupons() async {
    try {
      final res = await _client.get('/v1/partner/coupons') as Map<String, dynamic>;
      final data = (res['data'] as Map?)?['coupons'] as List<dynamic>? ?? [];
      setState(() {
        _coupons = data.whereType<Map>().map((m) => _couponFromApi(Map<String, dynamic>.from(m))).toList();
      });
    } catch (_) {}
  }

  _CouponItem _couponFromApi(Map<String, dynamic> json) {
    final visibility = (json['visibility']?.toString() ?? 'public') == 'private'
        ? _CouponVisibility.privateCoupon
        : _CouponVisibility.publicCoupon;
    return _CouponItem(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      discount: (json['discount'] is num) ? (json['discount'] as num).toDouble() : 0,
      visibility: visibility,
      status: json['status']?.toString() ?? 'Active',
    );
  }

  Future<void> _upsertCoupon(_CouponItem coupon) async {
    try {
      final payload = {
        'upserts': [
          {
            if (coupon.id.isNotEmpty) 'id': coupon.id,
            'code': coupon.code,
            'title': coupon.title,
            'subtitle': coupon.subtitle,
            'discount': coupon.discount,
            'visibility': coupon.visibility == _CouponVisibility.publicCoupon ? 'public' : 'private',
            'status': coupon.status,
          }
        ],
        'deletes': [],
      };
      final res = await _client.put('/v1/partner/coupons', body: payload) as Map<String, dynamic>;
      final data = (res['data'] as Map?)?['coupons'] as List<dynamic>? ?? [];
      setState(() {
        _coupons = data.whereType<Map>().map((m) => _couponFromApi(Map<String, dynamic>.from(m))).toList();
      });
    } catch (_) {}
  }

  Future<void> _deleteCoupon(_CouponItem coupon) async {
    if (coupon.id.isEmpty) return;
    try {
      final payload = {
        'upserts': [],
        'deletes': [coupon.id],
      };
      final res = await _client.put('/v1/partner/coupons', body: payload) as Map<String, dynamic>;
      final data = (res['data'] as Map?)?['coupons'] as List<dynamic>? ?? [];
      setState(() {
        _coupons = data.whereType<Map>().map((m) => _couponFromApi(Map<String, dynamic>.from(m))).toList();
      });
    } catch (_) {}
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _logoFile = File(picked.path);
      _uploadingLogo = true;
    });
    try {
      final res = await _client.uploadImage(picked.path, folder: 'partner-branding');
      final url = (res['data']?['url'] as String?) ?? '';
      if (url.isNotEmpty) {
        setState(() => _logoUrl = url);
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _uploadingLogo = false);
      }
    }
  }

  Future<void> _pickAndUploadCover() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _coverFile = File(picked.path);
      _uploadingCover = true;
    });
    try {
      final res = await _client.uploadImage(picked.path, folder: 'partner-branding');
      final url = (res['data']?['url'] as String?) ?? '';
      if (url.isNotEmpty) {
        setState(() => _coverUrl = url);
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _uploadingCover = false);
      }
    }
  }

  Future<void> _addCoupon() async {
    final res = await showDialog<_CouponItem>(
      context: context,
      builder: (ctx) => _CouponDialog(),
    );
    if (res != null) {
      await _upsertCoupon(res);
    }
  }

  void _toggleVisibility(int index) {
    final item = _coupons[index];
    final next = item.visibility == _CouponVisibility.publicCoupon
        ? _CouponVisibility.privateCoupon
        : _CouponVisibility.publicCoupon;
    _upsertCoupon(item.copyWith(visibility: next));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await _client.put('/v1/partner/status', body: {
        'status': _isOpen ? 'Active' : 'Closed',
        'delivery_minutes': _deliveryMinutes,
        'is_pure_veg': _pureVeg,
        'image_url': _logoUrl,
        'cover_url': _coverUrl,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated')));
      }
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Restaurant Settings', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isOpen,
                  onChanged: _loading ? null : (v) => setState(() => _isOpen = v),
                  title: Text(_isOpen ? 'Open for orders' : 'Closed for orders'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                const Text('Delivery Time (minutes)', style: TextStyle(color: MerchantTheme.textPrimary)),
                Slider(
                  min: 10,
                  max: 60,
                  divisions: 10,
                  value: _deliveryMinutes.toDouble(),
                  onChanged: _loading ? null : (v) => setState(() => _deliveryMinutes = v.round()),
                  label: '$_deliveryMinutes',
                ),
                CheckboxListTile(
                  value: _pureVeg,
                  onChanged: _loading ? null : (v) => setState(() => _pureVeg = v ?? false),
                  title: const Text('Pure Veg'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: Text(_loading ? 'Saving...' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Branding', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _ImageUploadTile(
                  title: 'Restaurant Logo',
                  subtitle: 'Square logo for profile & lists',
                  imageUrl: _logoUrl,
                  file: _logoFile,
                  uploading: _uploadingLogo,
                  onUpload: _pickAndUploadLogo,
                ),
                const SizedBox(height: 12),
                _ImageUploadTile(
                  title: 'Cover Image',
                  subtitle: 'Wide banner for restaurant page',
                  imageUrl: _coverUrl,
                  file: _coverFile,
                  uploading: _uploadingCover,
                  onUpload: _pickAndUploadCover,
                  wide: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Coupons', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _addCoupon,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Coupon'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Public coupons user app me dikhte hain, private coupons sirf code apply karne par lagte hain.',
                  style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (_coupons.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Abhi koi coupon add nahi hai.', style: TextStyle(color: MerchantTheme.tabInactive)),
                  )
                else
                  Column(
                    children: [
                      for (int i = 0; i < _coupons.length; i++) ...[
                        _CouponCard(
                          coupon: _coupons[i],
                          onToggle: () => _toggleVisibility(i),
                          onDelete: () => _deleteCoupon(_coupons[i]),
                        ),
                        if (i != _coupons.length - 1)
                          const Divider(height: 20, color: MerchantTheme.dividerColor),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageUploadTile extends StatelessWidget {
  const _ImageUploadTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.file,
    required this.uploading,
    required this.onUpload,
    this.wide = false,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final File? file;
  final bool uploading;
  final VoidCallback onUpload;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final preview = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : imageUrl.isNotEmpty
            ? Image.network(imageUrl, fit: BoxFit.cover)
            : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MerchantTheme.bgCardInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MerchantTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: MerchantTheme.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
          const SizedBox(height: 10),
          Container(
            height: wide ? 120 : 90,
            decoration: BoxDecoration(
              color: MerchantTheme.bgDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MerchantTheme.dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: preview ?? const Center(child: Icon(Icons.image_outlined, color: MerchantTheme.tabInactive)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: uploading ? null : onUpload,
              icon: uploading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload),
              label: Text(uploading ? 'Uploading...' : 'Upload'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onToggle,
    required this.onDelete,
  });
  final _CouponItem coupon;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPublic = coupon.visibility == _CouponVisibility.publicCoupon;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MerchantTheme.bgCardInner,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MerchantTheme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPublic ? MerchantTheme.accentGreen.withOpacity(0.15) : MerchantTheme.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              coupon.code.toUpperCase(),
              style: TextStyle(
                color: isPublic ? MerchantTheme.accentGreen : MerchantTheme.tabInactive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coupon.title, style: const TextStyle(color: MerchantTheme.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(coupon.subtitle, style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Discount ₹${coupon.discount.toStringAsFixed(0)}', style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Text(isPublic ? 'Public' : 'Private', style: TextStyle(color: isPublic ? MerchantTheme.accentGreen : MerchantTheme.tabInactive)),
              Switch(value: isPublic, onChanged: (_) => onToggle()),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CouponDialog extends StatefulWidget {
  @override
  State<_CouponDialog> createState() => _CouponDialogState();
}

class _CouponDialogState extends State<_CouponDialog> {
  final _code = TextEditingController();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _discount = TextEditingController();
  bool _isPublic = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Coupon'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Coupon Code'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subtitle,
              decoration: const InputDecoration(labelText: 'Subtitle'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _discount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount (₹)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              title: Text(_isPublic ? 'Public Coupon' : 'Private Coupon'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final code = _code.text.trim();
            final title = _title.text.trim();
            final subtitle = _subtitle.text.trim();
            final discount = double.tryParse(_discount.text.trim()) ?? 0;
            if (code.isEmpty || title.isEmpty) return;
            Navigator.pop(
              context,
              _CouponItem(
                id: '',
                code: code,
                title: title,
                subtitle: subtitle.isEmpty ? 'Offer on orders' : subtitle,
                discount: discount,
                visibility: _isPublic ? _CouponVisibility.publicCoupon : _CouponVisibility.privateCoupon,
                status: 'Active',
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
