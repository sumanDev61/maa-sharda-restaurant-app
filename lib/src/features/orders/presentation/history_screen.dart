import 'package:flutter/material.dart';
import '../domain/order_model.dart';
import '../data/partner_orders_api.dart';
import '../../../core/theme/merchant_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = PartnerOrdersApi();
  bool _loading = false;
  List<MerchantOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.fetch();
      setState(() {
        _orders = list
            .where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled)
            .toList();
      });
    } catch (_) {
      setState(() => _orders = []);
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
                if (_orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: Text(
                        'No completed orders yet',
                        style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 16),
                      ),
                    ),
                  ),
                ..._orders.map(_HistoryCard.new),
              ],
            ),
          );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.order);

  final MerchantOrder order;

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == OrderStatus.delivered;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.orderId}',
                style: const TextStyle(
                  color: MerchantTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered ? MerchantTheme.dimGreen : Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isDelivered ? 'DELIVERED' : 'CANCELLED',
                  style: TextStyle(
                    color: isDelivered ? MerchantTheme.accentGreen : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order.customerName,
            style: const TextStyle(color: MerchantTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...order.items.take(3).map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${it.quantity}x ${it.name}',
                  style: const TextStyle(color: MerchantTheme.textSecondary, fontSize: 13),
                ),
              )),
          if (order.items.length > 3)
            Text('+${order.items.length - 3} more items', style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
          const SizedBox(height: 12),
          if (!isDelivered && order.refundStatus.isNotEmpty)
            Text(
              'Refund: ${order.refundStatus}',
              style: const TextStyle(color: MerchantTheme.textSecondary, fontSize: 12),
            ),
          const SizedBox(height: 8),
          Text(
            'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(color: MerchantTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
