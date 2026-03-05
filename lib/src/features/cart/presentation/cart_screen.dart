import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../address/shared/address_providers.dart';
import '../../address/domain/address.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final selectedId = ref.watch(selectedAddressIdProvider);
    Address? selected;
    if (addresses is AsyncData<List<Address>> && selectedId is AsyncData<String?>) {
      final list = addresses.value;
      final id = selectedId.value;
      if (id != null) {
        final found = list.where((e) => e.id == id);
        if (found.isNotEmpty) {
          selected = found.first;
        } else if (list.isNotEmpty) {
          selected = list.first;
        }
      } else if (list.any((e) => e.isDefault)) {
        selected = list.firstWhere((e) => e.isDefault);
      } else if (list.isNotEmpty) {
        selected = list.first;
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(selected != null ? '${selected.type} • ${selected.city}' : 'Select delivery address'),
                subtitle: Text(selected != null ? '${selected.line1}, ${selected.city} ${selected.pincode}' : 'Choose where to deliver'),
                trailing: TextButton(onPressed: () => context.push('/address/select'), child: const Text('Change')),
              ),
            ),
          ),
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
