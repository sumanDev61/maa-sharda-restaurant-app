import 'package:shared_preferences/shared_preferences.dart';
import '../domain/address.dart';

class AddressRepository {
  static const _storageKey = 'addresses';
  static const _selectedKey = 'selected_address_id';
  Future<List<Address>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final list = raw.map((e) => Address.fromJson(e)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveAll(List<Address> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final data = addresses.map((e) => e.toJson()).toList();
    await prefs.setStringList(_storageKey, data);
  }

  Future<void> upsert(Address address) async {
    final current = await load();
    final idx = current.indexWhere((e) => e.id == address.id);
    if (address.isDefault) {
      for (var i = 0; i < current.length; i++) {
        current[i] = current[i].copyWith(isDefault: false);
      }
    }
    if (idx >= 0) {
      current[idx] = address;
    } else {
      current.add(address);
    }
    await saveAll(current);
  }

  Future<void> remove(String id) async {
    final current = await load();
    current.removeWhere((e) => e.id == id);
    await saveAll(current);
    final prefs = await SharedPreferences.getInstance();
    final sel = prefs.getString(_selectedKey);
    if (sel == id) {
      await prefs.remove(_selectedKey);
    }
  }

  Future<String?> getSelectedId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedKey);
  }

  Future<void> setSelectedId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, id);
  }
}
