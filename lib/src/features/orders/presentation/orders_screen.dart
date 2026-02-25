import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, i) {
          return ListTile(
            leading: const Icon(Icons.receipt_long),
            title: Text('Order #${1000 + i}'),
            subtitle: const Text('2 items • Preparing'),
            trailing: const Text('₹320'),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemCount: 8,
      ),
    );
  }
}
