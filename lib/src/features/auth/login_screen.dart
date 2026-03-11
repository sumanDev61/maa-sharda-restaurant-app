import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/partner_session.dart';
import '../../core/theme/merchant_theme.dart';
import 'auth_models.dart';

class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 8) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().post('/v1/partner/auth/login', body: {
        'phone': phone,
      });
      final data = (res as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final rid = data['restaurant_id']?.toString() ?? '';
      final otp = data['otp']?.toString();
      if (!mounted) return;
      GoRouter.of(context).go('/otp', extra: OtpArgs(restaurantId: rid, phone: phone, otp: otp));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404) {
        GoRouter.of(context).go('/register', extra: RegisterArgs(phone: phone));
        return;
      }
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Enter phone number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('We will send an OTP to verify your restaurant account.', style: TextStyle(color: MerchantTheme.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                child: Text(_loading ? 'Sending...' : 'Send OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerOtpScreen extends StatefulWidget {
  const PartnerOtpScreen({super.key, this.args});
  final OtpArgs? args;

  @override
  State<PartnerOtpScreen> createState() => _PartnerOtpScreenState();
}

class _PartnerOtpScreenState extends State<PartnerOtpScreen> {
  final _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _shownOtp;

  @override
  void initState() {
    super.initState();
    final otp = widget.args?.otp?.trim();
    if (otp != null && otp.isNotEmpty) {
      _shownOtp = otp;
      if (otp.length == 6) {
        _otpController.text = otp;
      }
    }
  }

  Future<void> _verify() async {
    final args = widget.args;
    if (args == null) return;
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      setState(() => _error = 'Enter OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient().post('/v1/partner/auth/verify-otp', body: {
        'restaurant_id': args.restaurantId,
        'otp': otp,
      });
      final data = (res as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final token = data['token']?.toString() ?? '';
      final rest = data['restaurant'] as Map<String, dynamic>? ?? {};
      final approval = rest['approval_status']?.toString() ?? 'inReview';
      final rid = rest['id']?.toString() ?? args.restaurantId;
      final name = rest['name']?.toString() ?? '';
      await PartnerSession().save(
        token: token,
        restaurantId: rid,
        approvalStatus: approval,
        restaurantName: name,
      );
      if (!mounted) return;
      if (approval != 'approved') {
        GoRouter.of(context).go('/review');
      } else {
        GoRouter.of(context).go('/');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OTP sent to ${args?.phone ?? ''}', style: const TextStyle(color: MerchantTheme.textSecondary)),
            if (_shownOtp != null) ...[
              const SizedBox(height: 8),
              Text('Debug OTP: $_shownOtp', style: const TextStyle(color: MerchantTheme.accentGreen)),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Enter OTP'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: Text(_loading ? 'Verifying...' : 'Verify OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
