import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/address_repository.dart';
import '../domain/address.dart';

final addressRepositoryProvider = Provider<AddressRepository>((ref) => AddressRepository());

class AddressState extends StateNotifier<AsyncValue<List<Address>>> {
  final AddressRepository repo;
  AddressState(this.repo) : super(const AsyncValue.loading()) {
    _load();
  }
  Future<void> _load() async {
    try {
      final data = await repo.load();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  Future<void> refresh() => _load();
  Future<void> addOrUpdate(Address address) async {
    await repo.upsert(address);
    await _load();
  }
  Future<void> remove(String id) async {
    await repo.remove(id);
    await _load();
  }
}

final addressesProvider = StateNotifierProvider<AddressState, AsyncValue<List<Address>>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  return AddressState(repo);
});

final selectedAddressIdProvider = StateNotifierProvider<SelectedAddressController, AsyncValue<String?>>((ref) {
  final repo = ref.watch(addressRepositoryProvider);
  return SelectedAddressController(repo);
});

class SelectedAddressController extends StateNotifier<AsyncValue<String?>> {
  final AddressRepository repo;
  SelectedAddressController(this.repo) : super(const AsyncValue.loading()) {
    _load();
  }
  Future<void> _load() async {
    try {
      state = AsyncValue.data(await repo.getSelectedId());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  Future<void> setSelected(String id) async {
    await repo.setSelectedId(id);
    await _load();
  }
}
