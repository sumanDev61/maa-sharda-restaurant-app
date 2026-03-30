import 'package:flutter/material.dart';
import '../../../core/theme/merchant_theme.dart';
import '../../orders/presentation/merchant_shell.dart';
import '../../menu/data/menu_api.dart';
import '../../../core/api/api_client.dart';
import 'package:image_picker/image_picker.dart';

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
                        leading: it.imageUrl != null && it.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  it.imageUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const CircleAvatar(
                                radius: 24,
                                backgroundColor: MerchantTheme.bgCardInner,
                                child: Icon(Icons.fastfood, color: MerchantTheme.tabInactive),
                              ),
                        title: Row(
                          children: [
                            if (it.isVeg)
                              const Icon(Icons.circle, color: Colors.green, size: 10)
                            else
                              const Icon(Icons.circle, color: Colors.red, size: 10),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                it.name,
                                style: const TextStyle(
                                  color: MerchantTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (it.isBestseller)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${it.category ?? 'General'} • ₹${it.price.toStringAsFixed(2)} • ${it.prepTimeMinutes} min',
                              style: const TextStyle(color: MerchantTheme.tabInactive),
                            ),
                            if ((it.description ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  it.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: MerchantTheme.tabInactive,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
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
  int _prepTime = 15;
  bool _isVeg = false;
  bool _isBestseller = false;
  bool _uploading = false;

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
    _prepTime = widget.item?.prepTimeMinutes ?? 15;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preparation Time', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [10, 15, 20, 25, 30, 45, 60]
                        .map(
                          (m) => ChoiceChip(
                            label: Text('$m min'),
                            selected: _prepTime == m,
                            onSelected: (_) => setState(() => _prepTime = m),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: _description,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Image URL'),
                      controller: _imageUrl,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _uploading
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                            if (picked == null) return;
                            setState(() => _uploading = true);
                            try {
                              final res = await ApiClient().uploadImage(picked.path, folder: 'partner-menu');
                              final url = (res['data']?['url'] as String?) ?? '';
                              if (url.isNotEmpty) {
                                _imageUrl.text = url;
                                setState(() {});
                              }
                            } catch (_) {} finally {
                              if (mounted) {
                                setState(() => _uploading = false);
                              }
                            }
                          },
                    icon: _uploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.file_upload_outlined),
                    tooltip: 'Upload',
                  ),
                ],
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
              prepTimeMinutes: _prepTime,
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
