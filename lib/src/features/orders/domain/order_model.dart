enum OrderStatus { incoming, preparing, ready, outForDelivery, delivered, cancelled }

enum DeliveryType { priorityDelivery, selfPickup, delivery }

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class MerchantOrder {
  final String orderId;
  final String customerName;
  final DeliveryType deliveryType;
  final List<OrderItem> items;
  final String waitTime;
  final OrderStatus status;
  final String pickupOtp;
  final String statusRaw;
  final String driverName;
  final String driverPhone;
  final String driverStatus;
  final String refundStatus;

  const MerchantOrder({
    required this.orderId,
    required this.customerName,
    required this.deliveryType,
    required this.items,
    required this.waitTime,
    required this.status,
    required this.statusRaw,
    this.pickupOtp = '',
    this.driverName = '',
    this.driverPhone = '',
    this.driverStatus = '',
    this.refundStatus = '',
  });

  String get deliveryTypeLabel {
    switch (deliveryType) {
      case DeliveryType.priorityDelivery:
        return 'Priority Delivery';
      case DeliveryType.selfPickup:
        return 'Self-Pickup';
      case DeliveryType.delivery:
        return 'Delivery';
    }
  }

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + (item.price));
}

// ── Dummy data for demonstration ──
final List<MerchantOrder> dummyOrders = [
  const MerchantOrder(
    orderId: 'MS-9021',
    customerName: 'Rajesh Kumar',
    deliveryType: DeliveryType.priorityDelivery,
    items: [
      OrderItem(name: 'Paneer Butter Masala', quantity: 2, price: 480),
      OrderItem(name: 'Garlic Naan', quantity: 4, price: 160),
      OrderItem(name: 'Dal Makhani (Half)', quantity: 1, price: 180),
    ],
    waitTime: '08:45',
    status: OrderStatus.incoming,
    statusRaw: 'PENDING_MERCHANT_CONFIRMATION',
  ),
  const MerchantOrder(
    orderId: 'MS-9025',
    customerName: 'Ananya Singh',
    deliveryType: DeliveryType.selfPickup,
    items: [
      OrderItem(name: 'Veg Biryani (Large)', quantity: 1, price: 220),
      OrderItem(name: 'Raita (Extra)', quantity: 1, price: 40),
    ],
    waitTime: '03:12',
    status: OrderStatus.incoming,
    statusRaw: 'PENDING_MERCHANT_CONFIRMATION',
  ),
  const MerchantOrder(
    orderId: 'MS-9018',
    customerName: 'Priya Sharma',
    deliveryType: DeliveryType.delivery,
    items: [
      OrderItem(name: 'Butter Chicken', quantity: 1, price: 320),
      OrderItem(name: 'Tandoori Roti', quantity: 6, price: 120),
      OrderItem(name: 'Gulab Jamun', quantity: 2, price: 80),
    ],
    waitTime: '12:30',
    status: OrderStatus.incoming,
    statusRaw: 'PENDING_MERCHANT_CONFIRMATION',
  ),
  const MerchantOrder(
    orderId: 'MS-9015',
    customerName: 'Amit Verma',
    deliveryType: DeliveryType.priorityDelivery,
    items: [
      OrderItem(name: 'Chole Bhature', quantity: 2, price: 260),
      OrderItem(name: 'Lassi (Sweet)', quantity: 2, price: 100),
    ],
    waitTime: '05:20',
    status: OrderStatus.preparing,
    statusRaw: 'ACCEPTED_BY_MERCHANT',
  ),
  const MerchantOrder(
    orderId: 'MS-9013',
    customerName: 'Sneha Patel',
    deliveryType: DeliveryType.selfPickup,
    items: [
      OrderItem(name: 'Masala Dosa', quantity: 3, price: 270),
      OrderItem(name: 'Sambhar', quantity: 3, price: 90),
    ],
    waitTime: '18:40',
    status: OrderStatus.preparing,
    statusRaw: 'PREPARING',
  ),
  const MerchantOrder(
    orderId: 'MS-9012',
    customerName: 'Vikram Joshi',
    deliveryType: DeliveryType.delivery,
    items: [
      OrderItem(name: 'Paneer Tikka', quantity: 1, price: 280),
      OrderItem(name: 'Butter Naan', quantity: 4, price: 160),
      OrderItem(name: 'Mango Lassi', quantity: 2, price: 120),
    ],
    waitTime: '15:55',
    status: OrderStatus.preparing,
    statusRaw: 'PREPARING',
  ),
  const MerchantOrder(
    orderId: 'MS-9010',
    customerName: 'Ravi Gupta',
    deliveryType: DeliveryType.delivery,
    items: [
      OrderItem(name: 'Kadhai Paneer', quantity: 1, price: 260),
      OrderItem(name: 'Jeera Rice', quantity: 1, price: 140),
    ],
    waitTime: '22:00',
    status: OrderStatus.preparing,
    statusRaw: 'PREPARING',
  ),
  const MerchantOrder(
    orderId: 'MS-9008',
    customerName: 'Neha Agarwal',
    deliveryType: DeliveryType.selfPickup,
    items: [
      OrderItem(name: 'Mixed Veg', quantity: 1, price: 200),
      OrderItem(name: 'Roti', quantity: 4, price: 80),
    ],
    waitTime: '25:10',
    status: OrderStatus.preparing,
    statusRaw: 'PREPARING',
  ),
  const MerchantOrder(
    orderId: 'MS-9005',
    customerName: 'Karan Malhotra',
    deliveryType: DeliveryType.delivery,
    items: [
      OrderItem(name: 'Chicken Biryani', quantity: 2, price: 520),
      OrderItem(name: 'Raita', quantity: 2, price: 60),
    ],
    waitTime: '30:00',
    status: OrderStatus.ready,
    statusRaw: 'READY_FOR_PICKUP',
  ),
  const MerchantOrder(
    orderId: 'MS-9003',
    customerName: 'Deepa Reddy',
    deliveryType: DeliveryType.priorityDelivery,
    items: [
      OrderItem(name: 'Thali (Special)', quantity: 1, price: 350),
    ],
    waitTime: '35:15',
    status: OrderStatus.ready,
    statusRaw: 'READY_FOR_PICKUP',
  ),
];
