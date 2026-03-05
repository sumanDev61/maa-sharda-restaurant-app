import 'package:flutter/material.dart';
import '../../../core/theme/merchant_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/partner_session.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rid = PartnerSession().restaurantId ?? '';
      final json = await _client.get('/v1/restaurants/$rid') as Map<String, dynamic>;
      final data = (json['data'] as Map?) ?? {};
      setState(() {
        _isOpen = (data['status']?.toString() ?? 'Active') == 'Active';
        _deliveryMinutes = (data['delivery_minutes'] as num?)?.toInt() ?? 25;
        _pureVeg = (data['is_pure_veg'] as bool?) ?? false;
      });
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await _client.put('/v1/partner/status', body: {
        'status': _isOpen ? 'Active' : 'Closed',
        'delivery_minutes': _deliveryMinutes,
        'is_pure_veg': _pureVeg,
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
                const Text('Store Status', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                SwitchListTile(
                  value: _isOpen,
                  onChanged: _loading ? null : (v) => setState(() => _isOpen = v),
                  title: Text(_isOpen ? 'Open' : 'Closed'),
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
      ],
    );
  }
}
