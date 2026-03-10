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
    final statusRaw = (o['status']?.toString() ?? '');
    final status = statusRaw.toUpperCase().replaceAll(' ', '_');
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
    OrderStatus mapStatus(String v) {
      if (v.contains('CANCEL') || v.contains('REJECT')) return OrderStatus.cancelled;
      if (v.contains('DELIVERED') || v.contains('COMPLETED')) return OrderStatus.delivered;
      if (
          v == 'DRIVER_ASSIGNED' ||
          v == 'DRIVER_ARRIVED_AT_MERCHANT' ||
          v == 'PICKED_UP' ||
          v == 'EN_ROUTE_TO_CUSTOMER' ||
          v == 'ARRIVED_AT_CUSTOMER' ||
          v == 'OUT_FOR_DELIVERY' ||
          v.contains('OUT_FOR_DELIVERY') ||
          v.contains('OUT_FOR')
      ) return OrderStatus.outForDelivery;
      if (v == 'READY_FOR_PICKUP' || v == 'READY' || v.contains('READY')) return OrderStatus.ready;
      if (v == 'ACCEPTED_BY_MERCHANT' || v == 'PREPARING' || v.contains('PREPARING') || v.contains('ACCEPTED')) {
        return OrderStatus.preparing;
      }
      if (v == 'PENDING_MERCHANT_CONFIRMATION' || v == 'PLACED' || v.contains('PENDING')) {
        return OrderStatus.incoming;
      }
      return OrderStatus.incoming;
    }
    final mStatus = mapStatus(status);
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
