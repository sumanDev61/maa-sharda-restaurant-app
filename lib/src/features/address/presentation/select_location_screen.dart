import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/address_providers.dart';

class SelectLocationScreen extends ConsumerWidget {
  const SelectLocationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);
    final selectedId = ref.watch(selectedAddressIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: addresses.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 48),
                  const SizedBox(height: 8),
                  const Text('No saved addresses'),
                ],
              ),
            );
          }
          final currentId = selectedId.asData?.value;
          final sorted = [...list]..sort((a, b) {
              if (a.isDefault && !b.isDefault) return -1;
              if (!a.isDefault && b.isDefault) return 1;
              return a.createdAt.isAfter(b.createdAt) ? -1 : 1;
            });
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final a = sorted[i];
              final selected = a.id == currentId;
              return Card(
                child: ListTile(
                  leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
                  title: Text('${a.type} • ${a.city}'),
                  subtitle: Text('${a.line1}, ${a.line2.isNotEmpty ? '${a.line2}, ' : ''}${a.city}, ${a.state} ${a.pincode}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await ref.read(addressesProvider.notifier).remove(a.id);
                      }
                      if (v == 'default') {
                        await ref.read(addressesProvider.notifier).addOrUpdate(a.copyWith(isDefault: true));
                        await ref.read(selectedAddressIdProvider.notifier).setSelected(a.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'default', child: Text('Make default')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () {
                    ref.read(selectedAddressIdProvider.notifier).setSelected(a.id);
                    if (context.canPop()) {
                      context.pop(a);
                    }
                  },
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: sorted.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(e.toString())),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/address/add'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Address'),
      ),
    );
  }
}
