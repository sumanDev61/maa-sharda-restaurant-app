import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env.dart';
import '../auth/partner_session.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String get _baseUrl => Env.apiBaseUrl;

  Map<String, String> _headers() {
    final h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = PartnerSession().token;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<dynamic> get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('GET $path failed ${res.statusCode}');
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.put(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body.isEmpty ? '{}' : res.body);
    }
    throw Exception('PUT $path failed ${res.statusCode}');
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final res = await http.post(uri, headers: _headers(), body: body != null ? jsonEncode(body) : null);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body.isEmpty ? '{}' : res.body);
    }
    throw Exception('POST $path failed ${res.statusCode}');
  }

  Future<Map<String, dynamic>> uploadImage(String filePath, {String folder = 'partner-menu'}) async {
    final uri = Uri.parse('$_baseUrl/v1/partner/upload');
    final req = http.MultipartRequest('POST', uri);
    final token = PartnerSession().token;
    if (token != null && token.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.fields['folder'] = folder;
    req.files.add(await http.MultipartFile.fromPath('image', filePath));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Exception('Upload failed ${streamed.statusCode}');
  }
}
