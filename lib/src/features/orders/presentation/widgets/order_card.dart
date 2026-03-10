import 'package:flutter/material.dart';
import '../../domain/order_model.dart';
import '../../../../core/theme/merchant_theme.dart';

class OrderCard extends StatelessWidget {
  final MerchantOrder order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onReady;

  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: MerchantTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantTheme.dimGreen, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: INCOMING ORDER + wait time ──
            _buildHeader(),
            const SizedBox(height: 2),
            // ── Order ID ──
            _buildOrderId(),
            const SizedBox(height: 16),
            // ── Customer info ──
            _buildCustomerInfo(),
            const SizedBox(height: 8),
            if ((order.status == OrderStatus.ready || order.status == OrderStatus.outForDelivery) &&
                order.pickupOtp.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MerchantTheme.bgCardInner,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MerchantTheme.dividerColor, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pickup OTP',
                      style: TextStyle(
                        color: MerchantTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      order.pickupOtp,
                      style: const TextStyle(
                        color: MerchantTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 14),
            if (order.driverName.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MerchantTheme.bgCardInner,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MerchantTheme.dividerColor, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Driver Assigned',
                      style: TextStyle(
                        color: MerchantTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          order.driverName,
                          style: const TextStyle(
                            color: MerchantTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (order.driverPhone.isNotEmpty)
                          Text(
                            order.driverPhone,
                            style: const TextStyle(
                              color: MerchantTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // ── Items list ──
            _buildItemsList(),
            const SizedBox(height: 16),
            // ── Action buttons ──
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _statusLabel,
          style: const TextStyle(
            color: MerchantTheme.accentGreen,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.waitTime,
              style: TextStyle(
                color: order.status == OrderStatus.incoming
                    ? MerchantTheme.accentGreen
                    : MerchantTheme.textSecondary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'WAIT TIME',
              style: TextStyle(
                color: MerchantTheme.tabInactive,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _statusLabel {
    switch (order.status) {
      case OrderStatus.incoming:
        return 'INCOMING ORDER';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.ready:
        return 'READY FOR PICKUP';
      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Widget _buildOrderId() {
    return Text(
      '#${order.orderId}',
      style: const TextStyle(
        color: MerchantTheme.textPrimary,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: MerchantTheme.dimGreen,
          child: Icon(
            Icons.person,
            color: MerchantTheme.textSecondary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.customerName,
              style: const TextStyle(
                color: MerchantTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              order.deliveryTypeLabel,
              style: const TextStyle(
                color: MerchantTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantTheme.bgCardInner,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MerchantTheme.dividerColor, width: 0.5),
      ),
      child: Column(
        children: order.items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == order.items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.name}',
                    style: const TextStyle(
                      color: MerchantTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: MerchantTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions() {
    if (order.status == OrderStatus.incoming) {
      return Row(
        children: [
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: MerchantTheme.accentGreen,
              side: const BorderSide(color: MerchantTheme.accentGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'REJECT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantTheme.accentGreen,
                foregroundColor: const Color(0xFF003300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'ACCEPT ORDER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.preparing) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onReady,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantTheme.accentGreen,
                foregroundColor: const Color(0xFF003300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                'MARK READY',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.ready) {
      final canHandover = order.driverName.isNotEmpty;
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: canHandover ? onReady : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: MerchantTheme.accentGreen,
                foregroundColor: const Color(0xFF003300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                canHandover ? 'HANDOVER TO DRIVER' : 'WAITING FOR DRIVER',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (order.status == OrderStatus.outForDelivery) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                foregroundColor: MerchantTheme.textSecondary,
                side: const BorderSide(color: MerchantTheme.dividerColor, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _driverStatusLabel(order.statusRaw),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled ? null : onReady,
            style: ElevatedButton.styleFrom(
              backgroundColor: MerchantTheme.accentGreen,
              foregroundColor: const Color(0xFF003300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: Text(
              order.status == OrderStatus.delivered
                  ? 'DELIVERED'
                  : order.status == OrderStatus.cancelled
                      ? 'CANCELLED'
                      : 'HANDOVER',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _driverStatusLabel(String raw) {
    final s = raw.toUpperCase();
    if (s == 'DRIVER_ASSIGNED') return 'DRIVER ASSIGNED';
    if (s == 'DRIVER_ARRIVED_AT_MERCHANT') return 'DRIVER ARRIVED';
    if (s == 'PICKED_UP') return 'ORDER PICKED UP';
    if (s == 'EN_ROUTE_TO_CUSTOMER') return 'OUT FOR DELIVERY';
    if (s == 'ARRIVED_AT_CUSTOMER') return 'ARRIVED AT CUSTOMER';
    if (s == 'DELIVERED') return 'DELIVERED';
    return 'IN TRANSIT';
  }
}
