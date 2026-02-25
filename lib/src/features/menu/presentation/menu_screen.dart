import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/menu_providers.dart';
import '../../../common/widgets/app_logo.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(menuItemsProvider);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              AppLogo(),
              SizedBox(width: 8),
              Text('Maa Sharda'),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search dishes',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder: (context, i) {
            final item = items[i % items.length];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(item.icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  title: Text(item.name),
                  subtitle: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${item.price.toStringAsFixed(0)}'),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(minimumSize: const Size(72, 28), padding: const EdgeInsets.symmetric(horizontal: 8)),
                          onPressed: () {},
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          itemCount: items.length,
        ),
      ],
    );
  }
}
