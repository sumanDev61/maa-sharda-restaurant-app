import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/partner_session.dart';
import '../../core/theme/merchant_theme.dart';

class OtpArgs {
  const OtpArgs({required this.restaurantId, required this.phone, this.otp});
  final String restaurantId;
  final String phone;
  final String? otp;
}

class RegisterArgs {
  const RegisterArgs({required this.phone});
  final String phone;
}

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

class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key, this.args});
  final RegisterArgs? args;

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _cuisine = TextEditingController();
  final _fssai = TextEditingController();
  final _gst = TextEditingController();
  final _pan = TextEditingController();
  final _aadhar = TextEditingController();
  final _license = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _cuisine.dispose();
    _fssai.dispose();
    _gst.dispose();
    _pan.dispose();
    _aadhar.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final phone = widget.args?.phone ?? '';
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      setState(() => _error = 'Name and address required');
      return;
    }
    final docs = <String, String>{};
    final fssai = _fssai.text.trim();
    final gst = _gst.text.trim();
    final pan = _pan.text.trim();
    final aadhar = _aadhar.text.trim();
    final license = _license.text.trim();
    if (fssai.isNotEmpty) docs['fssai'] = fssai;
    if (gst.isNotEmpty) docs['gst'] = gst;
    if (pan.isNotEmpty) docs['pan'] = pan;
    if (aadhar.isNotEmpty) docs['aadhar'] = aadhar;
    if (license.isNotEmpty) docs['license'] = license;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = {
        'phone': phone,
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'owner_name': _ownerName.text.trim(),
        'owner_email': _ownerEmail.text.trim(),
        'cuisines': _cuisine.text.trim().isNotEmpty ? [_cuisine.text.trim()] : [],
      };
      if (docs.isNotEmpty) {
        body['documents'] = docs;
      }
      final res = await ApiClient().post('/v1/partner/auth/register', body: body);
      final data = (res as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final rid = data['restaurant_id']?.toString() ?? '';
      final otp = data['otp']?.toString();
      if (!mounted) return;
      GoRouter.of(context).go('/otp', extra: OtpArgs(restaurantId: rid, phone: phone, otp: otp));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextFormField(
              initialValue: widget.args?.phone ?? '',
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Restaurant Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cuisine,
              decoration: const InputDecoration(labelText: 'Cuisine (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerName,
              decoration: const InputDecoration(labelText: 'Owner Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerEmail,
              decoration: const InputDecoration(labelText: 'Owner Email'),
            ),
            const SizedBox(height: 12),
            const Text('Documents (optional)', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _fssai,
              decoration: const InputDecoration(labelText: 'FSSAI License'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gst,
              decoration: const InputDecoration(labelText: 'GST Number'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pan,
              decoration: const InputDecoration(labelText: 'PAN'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _aadhar,
              decoration: const InputDecoration(labelText: 'Aadhar'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _license,
              decoration: const InputDecoration(labelText: 'Other License'),
            ),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: Text(_loading ? 'Submitting...' : 'Submit & Verify'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerReviewScreen extends StatefulWidget {
  const PartnerReviewScreen({super.key});

  @override
  State<PartnerReviewScreen> createState() => _PartnerReviewScreenState();
}

class _PartnerReviewScreenState extends State<PartnerReviewScreen> {
  String _status = PartnerSession().approvalStatus ?? 'inReview';
  bool _loading = false;
  bool _checking = false;
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(const Duration(seconds: 15), (_) => _checkStatus(showLoading: false));
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus({bool showLoading = true}) async {
    if (_checking) return;
    _checking = true;
    if (showLoading) setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/v1/partner/profile') as Map<String, dynamic>;
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final status = data['approval_status']?.toString() ?? 'inReview';
      await PartnerSession().save(
        token: PartnerSession().token ?? '',
        restaurantId: PartnerSession().restaurantId ?? '',
        approvalStatus: status,
        restaurantName: data['name']?.toString() ?? '',
      );
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'approved') {
        GoRouter.of(context).go('/');
      }
    } catch (_) {
    } finally {
      _checking = false;
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your restaurant registration is under review.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text('Current status: $_status', style: const TextStyle(color: MerchantTheme.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _checkStatus,
                child: Text(_loading ? 'Checking...' : 'Check Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
