import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/merchant_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _client = ApiClient();
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get('/v1/partner/notifications') as Map<String, dynamic>;
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _items = items;
        _unread = (data['unread_count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {
      setState(() {
        _items = [];
        _unread = 0;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _client.put('/v1/partner/notifications/read', body: {'all': true});
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 16),
                        ),
                      ),
                    ),
                  ..._items.map((n) => _NotificationCard(n)),
                ],
              ),
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard(this.notification);

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final read = notification['read'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: read ? MerchantTheme.bgCard : MerchantTheme.bgCardInner,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MerchantTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification['title']?.toString() ?? 'Order update',
                  style: const TextStyle(
                    color: MerchantTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MerchantTheme.accentGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notification['message']?.toString() ?? '',
            style: const TextStyle(color: MerchantTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
