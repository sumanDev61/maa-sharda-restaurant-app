import 'package:flutter/material.dart';
import 'dart:async';
import '../domain/order_model.dart';
import '../data/partner_orders_api.dart';
import '../../../core/auth/partner_session.dart';
import '../../../core/config/env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'package:flutter/services.dart' show SystemSound, SystemSoundType;
import '../../../core/theme/merchant_theme.dart';
import 'widgets/order_card.dart';
import '../../../core/notifications/notification_service.dart';
import 'package:go_router/go_router.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = PartnerOrdersApi();
  List<MerchantOrder> _orders = [];
  bool _loading = false;
  bool _sessionReady = false;
  Timer? _ringTimer;
  Set<String> _knownIncoming = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _bootstrap();
    _poller = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
  }

  Future<void> _bootstrap() async {
    await PartnerSession().load();
    if (!mounted) return;
    if ((PartnerSession().restaurantId ?? '').isEmpty) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        GoRouter.of(context).go('/login');
      }
      return;
    }
    setState(() => _sessionReady = true);
    await _load();
    _startSse();
  }

  StreamSubscription<String>? _sseSub;
  Future<void> _startSse() async {
    _sseSub?.cancel();
    final rid = PartnerSession().restaurantId ?? '';
    if (rid.isEmpty) return;
    final uri = Uri.parse('${Env.apiBaseUrl}/v1/sse/partner?restaurant_id=$rid');
    final client = http.Client();
    final req = http.Request('GET', uri);
    req.headers.addAll({'Accept': 'text/event-stream'});
    final res = await client.send(req);
    _sseSub = res.stream.transform(utf8.decoder).listen((chunk) {
      if (chunk.contains('data:')) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _poller.cancel();
    _sseSub?.cancel();
    _stopRinging();
    super.dispose();
  }

  late final Timer _poller;
  void _poll() {
    if (!_loading) _load();
  }
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.fetch();
      setState(() => _orders = list);
      _handleIncomingAlert(list.where((o) => o.status == OrderStatus.incoming).toList());
    } catch (_) {
      setState(() => _orders = []);
      _handleIncomingAlert(const []);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<MerchantOrder> _getOrdersByStatus(OrderStatus status) {
    return _orders.where((o) => o.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady) {
      return const Center(child: CircularProgressIndicator());
    }
    final newOrders = _getOrdersByStatus(OrderStatus.incoming);
    final preparingOrders = _getOrdersByStatus(OrderStatus.preparing);
    final readyOrders = _getOrdersByStatus(OrderStatus.ready);
    final outForDeliveryOrders = _getOrdersByStatus(OrderStatus.outForDelivery);

    return Column(
      children: [
        // ── Tab bar ──
        Container(
          color: MerchantTheme.bgDark,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'NEW (${newOrders.length})'),
              Tab(text: 'PREPARING (${preparingOrders.length})'),
              Tab(text: 'READY (${readyOrders.length})'),
              Tab(text: 'OUT FOR DELIVERY (${outForDeliveryOrders.length})'),
            ],
          ),
        ),
        // ── Tab content ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: newOrders,
                showingCount: 2,
                totalCount: newOrders.length,
                onAccept: _onAccept,
                onReject: _onReject,
                onReady: _onReady,
              ),
              _OrderList(
                orders: preparingOrders,
                showingCount: preparingOrders.length,
                totalCount: preparingOrders.length,
                onAccept: _onAccept,
                onReject: _onReject,
                onReady: _onReady,
              ),
              _OrderList(
                orders: readyOrders,
                showingCount: readyOrders.length,
                totalCount: readyOrders.length,
                onAccept: _onAccept,
                onReject: _onReject,
                onReady: _onReady,
              ),
              _OrderList(
                orders: outForDeliveryOrders,
                showingCount: outForDeliveryOrders.length,
                totalCount: outForDeliveryOrders.length,
                onAccept: null,
                onReject: null,
                onReady: null,
              ),
            ],
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _onAccept(MerchantOrder o) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (ctx) {
        int val = 15;
        return AlertDialog(
          title: const Text('Set prep time (minutes)'),
          content: StatefulBuilder(
            builder: (ctx, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [10, 15, 20, 25, 30, 35, 40, 45]
                      .map(
                        (m) => ChoiceChip(
                          label: Text('$m min'),
                          selected: val == m,
                          onSelected: (_) => setS(() => val = m),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('Selected: $val min'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, val), child: const Text('Confirm')),
          ],
        );
      },
    );
    if (minutes != null) {
      await _api.accept(o.orderId, prepMinutes: minutes);
      await _load();
    }
  }

  Future<void> _onReject(MerchantOrder o) async {
    await _api.reject(o.orderId);
    await _load();
  }

  Future<void> _onReady(MerchantOrder o) async {
    if (o.status == OrderStatus.preparing) {
      await _api.markReady(o.orderId);
    } else {
      await _api.handover(o.orderId);
    }
    await _load();
  }

  void _handleIncomingAlert(List<MerchantOrder> incoming) {
    final ids = incoming.map((o) => o.orderId).toSet();
    final newIds = ids.difference(_knownIncoming);
    _knownIncoming = ids;
    if (newIds.isNotEmpty) {
      NotificationService().showOrderAlert(
        title: 'New order received',
        body: 'You have ${incoming.length} new order${incoming.length == 1 ? '' : 's'}',
      );
    }
    if (ids.isNotEmpty) {
      _startRinging();
    } else {
      _stopRinging();
    }
  }

  void _startRinging() {
    if (_ringTimer != null) return;
    _ringTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      SystemSound.play(SystemSoundType.alert);
    });
  }

  void _stopRinging() {
    _ringTimer?.cancel();
    _ringTimer = null;
  }
}

class _OrderList extends StatelessWidget {
  final List<MerchantOrder> orders;
  final int showingCount;
  final int totalCount;
  final Future<void> Function(MerchantOrder)? onAccept;
  final Future<void> Function(MerchantOrder)? onReject;
  final Future<void> Function(MerchantOrder)? onReady;

  const _OrderList({
    required this.orders,
    required this.showingCount,
    required this.totalCount,
    this.onAccept,
    this.onReject,
    this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    final displayOrders = orders.take(showingCount).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        ...displayOrders.map(
          (order) => OrderCard(
            order: order,
            onAccept: onAccept != null ? () => onAccept!(order) : null,
            onReject: onReject != null ? () => onReject!(order) : null,
            onReady: onReady != null ? () => onReady!(order) : null,
          ),
        ),
        if (showingCount < totalCount) ...[
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Showing $showingCount of $totalCount orders',
              style: const TextStyle(
                color: MerchantTheme.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Text(
                'VIEW MORE',
                style: TextStyle(
                  color: MerchantTheme.accentGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              label: const Icon(
                Icons.keyboard_arrow_down,
                color: MerchantTheme.accentGreen,
                size: 20,
              ),
            ),
          ),
        ],
        if (orders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: Text(
                'No orders',
                style: TextStyle(
                  color: MerchantTheme.tabInactive,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
