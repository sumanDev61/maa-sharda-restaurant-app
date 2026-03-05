import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../domain/address.dart';

class AddressApi {
  Future<void> create(Address address) async {
    final base = Env.apiBaseUrl;
    if (base.isEmpty) return;
    final uri = Uri.parse('$base/addresses');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(address.toMap()),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to create address (${res.statusCode})');
    }
  }
}
