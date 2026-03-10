import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/merchant_theme.dart';
import '../../core/auth/partner_session.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = ApiClient();
  bool _loading = false;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get('/v1/partner/profile') as Map<String, dynamic>;
      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() => _profile = data);
      final approval = data['approval_status']?.toString();
      if (approval != null && approval.isNotEmpty) {
        await PartnerSession().save(
          token: PartnerSession().token ?? '',
          restaurantId: PartnerSession().restaurantId ?? '',
          approvalStatus: approval,
          restaurantName: data['name']?.toString() ?? '',
        );
      }
    } catch (_) {
      setState(() => _profile = {});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_profile.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'Profile not available',
                        style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 16),
                      ),
                    ),
                  )
                else ...[
                  _ProfileTile(label: 'Restaurant Name', value: _profile['name']?.toString() ?? ''),
                  _ProfileTile(label: 'Phone', value: _profile['phone']?.toString() ?? ''),
                  _ProfileTile(label: 'Address', value: _profile['address']?.toString() ?? ''),
                  _ProfileTile(label: 'Cuisines', value: (_profile['cuisines'] as List<dynamic>? ?? []).join(', ')),
                  _ProfileTile(label: 'Approval Status', value: _profile['approval_status']?.toString() ?? 'inReview'),
                  _ProfileTile(label: 'Store Status', value: _profile['status']?.toString() ?? 'Inactive'),
                  _ProfileTile(label: 'Owner Name', value: _profile['owner_name']?.toString() ?? ''),
                  _ProfileTile(label: 'Owner Email', value: _profile['owner_email']?.toString() ?? ''),
                  ..._buildDocumentTiles(_profile['documents']),
                ],
              ],
            ),
          );
  }

  List<Widget> _buildDocumentTiles(dynamic docsRaw) {
    if (docsRaw is! Map) return const [];
    final docs = docsRaw.cast<String, dynamic>();
    final entries = <MapEntry<String, String>>[
      MapEntry('FSSAI License', docs['fssai']?.toString() ?? ''),
      MapEntry('GST Number', docs['gst']?.toString() ?? ''),
      MapEntry('PAN', docs['pan']?.toString() ?? ''),
      MapEntry('Aadhar', docs['aadhar']?.toString() ?? ''),
      MapEntry('Other License', docs['license']?.toString() ?? ''),
    ].where((e) => e.value.isNotEmpty).toList();
    if (entries.isEmpty) return const [];
    return entries.map((e) => _ProfileTile(label: e.key, value: e.value)).toList();
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MerchantTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MerchantTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: MerchantTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value.isEmpty ? '-' : value, style: const TextStyle(color: MerchantTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
