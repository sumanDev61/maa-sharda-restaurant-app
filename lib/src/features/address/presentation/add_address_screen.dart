import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/address.dart';
import '../shared/address_providers.dart';
import '../data/address_api.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key});
  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _landmark = TextEditingController();
  final _otherLabel = TextEditingController();
  double? _lat;
  double? _lng;
  String _type = 'Home';
  bool _isDefault = false;
  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _landmark.dispose();
    _otherLabel.dispose();
    super.dispose();
  }
  Future<void> _fetchLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
    } catch (_) {
      // Ignore errors; user can fill form manually.
    }
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final a = Address(
      id: id,
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
      landmark: _landmark.text.trim(),
      type: _type == 'Other' && _otherLabel.text.trim().isNotEmpty ? 'Other - ${_otherLabel.text.trim()}' : _type,
      isDefault: _isDefault,
      latitude: _lat,
      longitude: _lng,
      createdAt: DateTime.now(),
    );
    try {
      await AddressApi().create(a);
    } catch (_) {
      // Fallback to local only if API not configured or fails
    }
    await ref.read(addressesProvider.notifier).addOrUpdate(a);
    if (_isDefault) {
      await ref.read(selectedAddressIdProvider.notifier).setSelected(a.id);
    }
    if (mounted) {
      context.pop(a);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Address')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.tonalIcon(
              onPressed: _fetchLocation,
              icon: const Icon(Icons.my_location_outlined),
              label: const Text('Fetch Current Location'),
            ),
            if (_lat != null && _lng != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Location: ${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'),
              ),
            TextFormField(
              controller: _fullName,
              decoration: const InputDecoration(labelText: 'Full Name'),
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().length < 3 ? 'Enter valid name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid phone' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line1,
              decoration: const InputDecoration(labelText: 'Address Line 1'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _line2,
              decoration: const InputDecoration(labelText: 'Address Line 2'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _state,
                    decoration: const InputDecoration(labelText: 'State'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pincode,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Pincode'),
              validator: (v) => v == null || v.trim().length < 6 ? 'Enter valid pincode' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landmark,
              decoration: const InputDecoration(labelText: 'Landmark (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: const [
                DropdownMenuItem(value: 'Home', child: Text('Home')),
                DropdownMenuItem(value: 'Work', child: Text('Work')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            if (_type == 'Other') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _otherLabel,
                decoration: const InputDecoration(labelText: 'Label for Other'),
                validator: (v) => _type == 'Other' && (v == null || v.trim().isEmpty) ? 'Enter a label' : null,
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Set as default'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text('Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}
