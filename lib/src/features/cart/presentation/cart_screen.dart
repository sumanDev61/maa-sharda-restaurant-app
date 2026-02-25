import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                CartTile(name: 'Paneer Butter Masala', price: 220),
                CartTile(name: 'Garlic Naan', price: 40, qty: 2),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [Text('Subtotal'), Text('₹300')],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [Text('Taxes'), Text('₹20')],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹320', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(onPressed: () {}, child: const Text('Proceed to Checkout')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CartTile extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  const CartTile({super.key, required this.name, this.qty = 1, required this.price});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text('₹${price.toStringAsFixed(0)} • Qty $qty'),
        trailing: IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
      ),
    );
  }
}
