import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/partner_session.dart';

class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final _restId = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().post('/v1/partner/login', body: {
        'restaurant_id': _restId.text.trim(),
        'password': _password.text.trim(),
      });
      final ok = res is Map<String, dynamic>;
      if (ok) {
        final data = (res as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        final token = data['token'] as String;
        final rid = (data['restaurant'] as Map<String, dynamic>)['id'] as String;
        await PartnerSession().save(token: token, restaurantId: rid);
        if (!mounted) return;
        // After login, go to orders root
        // ignore: use_build_context_synchronously
        GoRouter.of(context).go('/');
        return;
      }
      setState(() => _error = 'login failed');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _restId,
              decoration: const InputDecoration(labelText: 'Login ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'Signing in...' : 'Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
