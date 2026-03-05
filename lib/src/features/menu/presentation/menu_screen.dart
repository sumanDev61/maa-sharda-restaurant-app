import 'package:flutter/material.dart';
import '../../../core/theme/merchant_theme.dart';
import '../../orders/presentation/merchant_shell.dart';
import '../../menu/data/menu_api.dart';

const _menuCategories = [
  'Main Course',
  'Biryani',
  'Pizza',
  'Burger',
  'South Indian',
  'Chinese',
  'Snacks',
  'Dessert',
  'Starters',
  'Beverages',
  'Thali',
  'Bread',
  'Rice',
  'Salad',
  'Combo',
];

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _api = PartnerMenuApi();
  bool _loading = false;
  List<PartnerMenuItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.list();
      setState(() => _items = list);
    } catch (_) {
      setState(() => _items = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addOrEdit([PartnerMenuItem? item]) async {
    final res = await showDialog<PartnerMenuItem>(
      context: context,
      builder: (ctx) => _EditItemDialog(item: item),
    );
    if (res != null) {
      await _api.upsert([res]);
      await _load();
    }
  }

  Future<void> _toggleStatus(PartnerMenuItem it) async {
    final next = it.copyWith(status: it.status == 'Available' ? 'Unavailable' : 'Available');
    await _api.upsert([next]);
    await _load();
  }

  Future<void> _delete(PartnerMenuItem it) async {
    await _api.deleteIds([it.id]);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: MerchantTheme.bgDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Text('Menu', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _loading ? null : () => _addOrEdit(),
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final it = _items[i];
                      return ListTile(
                        title: Text(it.name, style: const TextStyle(color: MerchantTheme.textPrimary, fontWeight: FontWeight.w700)),
                        subtitle: Text('${it.category ?? 'General'} • ₹${it.price.toStringAsFixed(2)}', style: const TextStyle(color: MerchantTheme.tabInactive)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: it.status == 'Available',
                              onChanged: (_) => _toggleStatus(it),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: MerchantTheme.accentGreen),
                              onPressed: () => _addOrEdit(it),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _delete(it),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(color: MerchantTheme.dividerColor, height: 1),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EditItemDialog extends StatefulWidget {
  final PartnerMenuItem? item;
  const _EditItemDialog({required this.item});
  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  bool _isVeg = false;
  bool _isBestseller = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _price = TextEditingController(text: widget.item?.price.toString() ?? '');
    _category = TextEditingController(text: widget.item?.category ?? '');
    _description = TextEditingController(text: widget.item?.description ?? '');
    _imageUrl = TextEditingController(text: widget.item?.imageUrl ?? '');
    _isVeg = widget.item?.isVeg ?? false;
    _isBestseller = widget.item?.isBestseller ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Name'),
              controller: _name,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category.text.isEmpty ? null : _category.text,
              items: _menuCategories
                  .map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (v) {
                _category.text = v ?? '';
                setState(() {});
              },
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              keyboardType: TextInputType.number,
              controller: _price,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              controller: _description,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Image URL'),
              controller: _imageUrl,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: _isVeg,
                    onChanged: (v) => setState(() => _isVeg = v ?? false),
                    title: const Text('Veg'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    value: _isBestseller,
                    onChanged: (v) => setState(() => _isBestseller = v ?? false),
                    title: const Text('Bestseller'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final p = double.tryParse(_price.text.trim()) ?? 0;
            final item = PartnerMenuItem(
              id: widget.item?.id ?? '',
              name: _name.text.trim(),
              category: _category.text.trim().isEmpty ? null : _category.text.trim(),
              price: p,
              status: widget.item?.status ?? 'Available',
              isVeg: _isVeg,
              isBestseller: _isBestseller,
              description: _description.text.trim().isEmpty ? null : _description.text.trim(),
              imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
            );
            Navigator.pop(context, item);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
