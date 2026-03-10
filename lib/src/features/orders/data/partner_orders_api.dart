import 'dart:math';
import '../../../core/api/api_client.dart';
import '../../../core/auth/partner_session.dart';
import '../domain/order_model.dart';

class PartnerOrdersApi {
  final _client = ApiClient();
  String get _restId => PartnerSession().restaurantId ?? '';

  Future<List<MerchantOrder>> fetch() async {
    final json = await _client.get('/v1/partner/orders?restaurant_id=$_restId') as Map<String, dynamic>;
    final list = (json['data'] as List<dynamic>? ?? []);
    return list.map(_mapOrder).toList();
  }

  Future<void> accept(String orderId, {int prepMinutes = 15}) async {
    await _client.put('/v1/partner/orders/$orderId', body: {'action': 'accept', 'prep_time_minutes': prepMinutes});
  }

  Future<void> reject(String orderId) async {
    await _client.put('/v1/partner/orders/$orderId', body: {'action': 'reject'});
  }

  Future<void> markReady(String orderId) async {
    await _client.put('/v1/partner/orders/$orderId', body: {'action': 'ready'});
  }

  Future<void> handover(String orderId) async {
    await _client.put('/v1/partner/orders/$orderId', body: {'action': 'handover'});
  }

  MerchantOrder _mapOrder(dynamic o) {
    final status = (o['status']?.toString() ?? '').toUpperCase();
    final driver = (o['driver'] as Map<String, dynamic>?) ?? {};
    final items = (o['items'] as List<dynamic>? ?? []).map((it) {
      final name = it['name']?.toString() ?? 'Item';
      final qty = (it['quantity'] as num?)?.toInt() ?? 1;
      final price = (it['price'] as num?)?.toDouble() ?? 0.0;
      return OrderItem(name: name, quantity: qty, price: price);
    }).toList();
    double amount = (o['bill_details']?['grand_total'] as num?)?.toDouble() ?? 0.0;
    if (amount == 0.0) {
      double sum = 0.0;
      for (final it in items) {
        sum += it.price;
      }
      amount = sum;
    }
    final w = max(5, (o['prep_time_minutes'] as num?)?.toInt() ?? 15);
    final mStatus = switch (status) {
      'PENDING_MERCHANT_CONFIRMATION' => OrderStatus.incoming,
      'ACCEPTED_BY_MERCHANT' => OrderStatus.preparing,
      'PREPARING' => OrderStatus.preparing,
      'READY_FOR_PICKUP' => OrderStatus.ready,
      'DRIVER_ASSIGNED' => OrderStatus.outForDelivery,
      'DRIVER_ARRIVED_AT_MERCHANT' => OrderStatus.outForDelivery,
      'PICKED_UP' => OrderStatus.outForDelivery,
      'EN_ROUTE_TO_CUSTOMER' => OrderStatus.outForDelivery,
      'ARRIVED_AT_CUSTOMER' => OrderStatus.outForDelivery,
      'OUT_FOR_DELIVERY' => OrderStatus.outForDelivery,
      'DELIVERED' => OrderStatus.delivered,
      'REJECTED_BY_MERCHANT' => OrderStatus.cancelled,
      'CANCELLED' => OrderStatus.cancelled,
      _ => OrderStatus.incoming,
    };
    return MerchantOrder(
      orderId: o['id']?.toString() ?? '',
      customerName: 'Customer',
      deliveryType: DeliveryType.delivery,
      items: items.isNotEmpty ? items : [OrderItem(name: 'Order Total', quantity: 1, price: amount)],
      waitTime: '${w.toString().padLeft(2, '0')}:00',
      status: mStatus,
      statusRaw: status,
      pickupOtp: (o['pickup_otp'] as String?) ?? '',
      driverName: driver['name']?.toString() ?? '',
      driverPhone: driver['phone']?.toString() ?? '',
      driverStatus: status,
      refundStatus: (o['refund_status'] as String?) ?? '',
    );
  }
}
