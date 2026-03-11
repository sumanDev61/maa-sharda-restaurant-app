import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/partner_session.dart';
import 'auth_models.dart';

const _kPrimary = Color(0xFF135BEC);
const _kBgLight = Color(0xFFF6F6F8);

class RegistrationDraft {
  const RegistrationDraft({
    required this.phone,
    required this.restaurantName,
    required this.ownerName,
    required this.ownerPhone,
    required this.email,
    required this.cuisine,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.fssaiNumber,
    required this.gstNumber,
    required this.panNumber,
    required this.documents,
    required this.documentsUrls,
  });

  final String phone;
  final String restaurantName;
  final String ownerName;
  final String ownerPhone;
  final String email;
  final String cuisine;
  final String address;
  final double? latitude;
  final double? longitude;
  final String fssaiNumber;
  final String gstNumber;
  final String panNumber;
  final Map<String, String> documents;
  final Map<String, String> documentsUrls;

  factory RegistrationDraft.initial(String phone) {
    return RegistrationDraft(
      phone: phone,
      restaurantName: '',
      ownerName: '',
      ownerPhone: phone,
      email: '',
      cuisine: '',
      address: '',
      latitude: null,
      longitude: null,
      fssaiNumber: '',
      gstNumber: '',
      panNumber: '',
      documents: const {},
      documentsUrls: const {},
    );
  }

  RegistrationDraft copyWith({
    String? restaurantName,
    String? ownerName,
    String? ownerPhone,
    String? email,
    String? cuisine,
    String? address,
    double? latitude,
    double? longitude,
    String? fssaiNumber,
    String? gstNumber,
    String? panNumber,
    Map<String, String>? documents,
    Map<String, String>? documentsUrls,
  }) {
    return RegistrationDraft(
      phone: phone,
      restaurantName: restaurantName ?? this.restaurantName,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      email: email ?? this.email,
      cuisine: cuisine ?? this.cuisine,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fssaiNumber: fssaiNumber ?? this.fssaiNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      documents: documents ?? this.documents,
      documentsUrls: documentsUrls ?? this.documentsUrls,
    );
  }
}

class PartnerRegisterStep1Screen extends StatefulWidget {
  const PartnerRegisterStep1Screen({super.key, this.args});
  final RegisterArgs? args;

  @override
  State<PartnerRegisterStep1Screen> createState() => _PartnerRegisterStep1ScreenState();
}

class _PartnerRegisterStep1ScreenState extends State<PartnerRegisterStep1Screen> {
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _cuisine = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final phone = widget.args?.phone ?? '';
    if (phone.isNotEmpty) {
      _phone.text = phone;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _name.text.trim();
    final ownerName = _ownerName.text.trim();
    final phone = _phone.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || ownerName.isEmpty || phone.length < 8 || email.isEmpty || _cuisine.isEmpty) {
      setState(() => _error = 'Please fill all required fields.');
      return;
    }

    final draft = RegistrationDraft.initial(phone).copyWith(
      restaurantName: name,
      ownerName: ownerName,
      ownerPhone: phone,
      email: email,
      cuisine: _cuisine,
    );
    GoRouter.of(context).go('/register/location', extra: draft);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgLight,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'Merchant Registration', onBack: () => GoRouter.of(context).pop()),
            _ProgressHeader(title: 'Basic Information', step: 1, total: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Partner with Maa Sharda Go',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Join our network and grow your business by reaching more customers in your area.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _IconField(
                      controller: _name,
                      label: 'Restaurant Name',
                      hint: "e.g. Sharda's Kitchen",
                      icon: Icons.storefront,
                    ),
                    const SizedBox(height: 16),
                    _IconField(
                      controller: _ownerName,
                      label: 'Owner Name',
                      hint: 'Owner full name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _IconField(
                      controller: _phone,
                      label: 'Owner Contact Number',
                      hint: '+91 00000 00000',
                      icon: Icons.call,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _IconField(
                      controller: _email,
                      label: 'Business Email',
                      hint: 'business@example.com',
                      icon: Icons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _CuisineDropdown(
                      value: _cuisine.isEmpty ? null : _cuisine,
                      onChanged: (v) => setState(() => _cuisine = v ?? ''),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                ),
              ),
            ),
            _BottomAction(
              label: 'Continue to Step 2',
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerRegisterStep2Screen extends StatefulWidget {
  const PartnerRegisterStep2Screen({super.key, required this.draft});
  final RegistrationDraft draft;

  @override
  State<PartnerRegisterStep2Screen> createState() => _PartnerRegisterStep2ScreenState();
}

class _PartnerRegisterStep2ScreenState extends State<PartnerRegisterStep2Screen> {
  final _address = TextEditingController();
  final _fssai = TextEditingController();
  final _gst = TextEditingController();
  final _search = TextEditingController();
  Timer? _debounce;
  List<_PlaceResult> _results = [];
  bool _searching = false;
  String? _searchError;
  LatLng _center = const LatLng(22.7196, 75.8577);
  String? _error;

  @override
  void initState() {
    super.initState();
    _address.text = widget.draft.address;
    _fssai.text = widget.draft.fssaiNumber;
    _gst.text = widget.draft.gstNumber;
    if (widget.draft.latitude != null && widget.draft.longitude != null) {
      _center = LatLng(widget.draft.latitude!, widget.draft.longitude!);
    }
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _address.dispose();
    _fssai.dispose();
    _gst.dispose();
    _search.dispose();
    super.dispose();
  }

  void _continue() {
    final address = _address.text.trim().isNotEmpty ? _address.text.trim() : _search.text.trim();
    final fssai = _fssai.text.trim();
    final gst = _gst.text.trim();
    if (address.isEmpty || fssai.isEmpty) {
      setState(() => _error = 'Store location and FSSAI number are required.');
      return;
    }
    final next = widget.draft.copyWith(
      address: address,
      fssaiNumber: fssai,
      gstNumber: gst,
      latitude: _center.latitude,
      longitude: _center.longitude,
    );
    GoRouter.of(context).go('/register/documents', extra: next);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _search.text.trim();
    if (q.length < 3) {
      setState(() {
        _results = [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _searchPlaces(q));
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'maa-sharda-go-app',
      });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as List<dynamic>;
        final results = data.map((e) => _PlaceResult.fromJson(e as Map<String, dynamic>)).toList();
        setState(() => _results = results);
      } else {
        setState(() => _searchError = 'Search failed');
      }
    } catch (_) {
      setState(() => _searchError = 'Search failed');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useMyLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _searchError = 'Location services are disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _searchError = 'Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
      });
      await _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {
      setState(() => _searchError = 'Unable to fetch location');
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'maa-sharda-go-app',
      });
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final display = data['display_name']?.toString() ?? '';
        if (display.isNotEmpty) {
          setState(() => _address.text = display);
        }
      }
    } catch (_) {}
  }

  void _selectResult(_PlaceResult place) {
    setState(() {
      _center = LatLng(place.lat, place.lon);
      _address.text = place.displayName;
      _search.text = place.displayName;
      _results = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgLight,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'Maa Sharda Go', onBack: () => GoRouter.of(context).pop()),
            const SizedBox(height: 8),
            _StepDots(activeIndex: 1, total: 4),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Business Details',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pinpoint your store location and provide legal identification for verification.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'STORE LOCATION',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),
                    _IconField(
                      controller: _search,
                      label: '',
                      hint: 'Search for store address',
                      icon: Icons.search,
                    ),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_searchError!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                      ),
                    if (_results.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: _results
                              .map((r) => ListTile(
                                    tileColor: Colors.white,
                                    title: Text(
                                      r.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFF0F172A)),
                                    ),
                                    onTap: () => _selectResult(r),
                                  ))
                              .toList(),
                        ),
                      ),
                    const SizedBox(height: 10),
                    _IconField(
                      controller: _address,
                      label: 'Selected Address',
                      hint: 'Address will appear here',
                      icon: Icons.location_on,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    _MapPreview(
                      center: _center,
                      onUseMyLocation: _useMyLocation,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'COMPLIANCE & LICENSES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 10),
                    _IconField(
                      controller: _fssai,
                      label: 'FSSAI License Number',
                      hint: '14-digit FSSAI Number',
                      icon: Icons.receipt_long,
                    ),
                    const SizedBox(height: 12),
                    _IconField(
                      controller: _gst,
                      label: 'GST Number (Optional)',
                      hint: 'Enter GSTIN',
                      icon: Icons.account_balance,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recommended for larger outlets to claim tax credits.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                ),
              ),
            ),
            _BottomAction(label: 'Continue to Document Upload', onPressed: _continue),
          ],
        ),
      ),
    );
  }
}

class _DocType {
  const _DocType({required this.keyName, required this.title, required this.icon, required this.required});
  final String keyName;
  final String title;
  final IconData icon;
  final bool required;
}

class _DocUploadState {
  _DocUploadState({this.url, this.uploading = false, this.error});
  String? url;
  bool uploading;
  String? error;
}

class _PlaceResult {
  const _PlaceResult({required this.displayName, required this.lat, required this.lon});
  final String displayName;
  final double lat;
  final double lon;

  factory _PlaceResult.fromJson(Map<String, dynamic> json) {
    return _PlaceResult(
      displayName: json['display_name']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
    );
  }
}

class PartnerRegisterDocumentsScreen extends StatefulWidget {
  const PartnerRegisterDocumentsScreen({super.key, required this.draft});
  final RegistrationDraft draft;

  @override
  State<PartnerRegisterDocumentsScreen> createState() => _PartnerRegisterDocumentsScreenState();
}

class _PartnerRegisterDocumentsScreenState extends State<PartnerRegisterDocumentsScreen> {
  final _picker = ImagePicker();
  final _panNumber = TextEditingController();
  bool _submitting = false;
  String? _error;
  late final Map<String, _DocUploadState> _docs;

  final List<_DocType> _docTypes = const [
    _DocType(keyName: 'fssai', title: 'FSSAI Certificate', icon: Icons.description, required: true),
    _DocType(keyName: 'pan', title: 'PAN Card of Owner', icon: Icons.badge, required: true),
    _DocType(keyName: 'gst', title: 'GST Certificate', icon: Icons.account_balance, required: false),
    _DocType(keyName: 'cancelled_cheque', title: 'Cancelled Cheque', icon: Icons.payments, required: false),
  ];

  @override
  void initState() {
    super.initState();
    _panNumber.text = widget.draft.panNumber;
    _panNumber.addListener(() {
      if (mounted) setState(() {});
    });
    _docs = {
      for (final d in _docTypes) d.keyName: _DocUploadState(url: widget.draft.documentsUrls[d.keyName])
    };
  }

  @override
  void dispose() {
    _panNumber.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return (_docs['fssai']?.url ?? '').isNotEmpty &&
        (_docs['pan']?.url ?? '').isNotEmpty &&
        _panNumber.text.trim().isNotEmpty;
  }

  Future<void> _pickAndUpload(String key) async {
    setState(() {
      _docs[key]?.uploading = true;
      _docs[key]?.error = null;
    });
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) {
        setState(() => _docs[key]?.uploading = false);
        return;
      }
      final res = await ApiClient().uploadRegistrationImage(picked.path, folder: 'partner-registration');
      final url = (res['data']?['url'] ?? '').toString();
      if (url.isEmpty) {
        setState(() {
          _docs[key]?.uploading = false;
          _docs[key]?.error = 'Upload failed';
        });
        return;
      }
      setState(() {
        _docs[key]?.url = url;
        _docs[key]?.uploading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _docs[key]?.uploading = false;
        _docs[key]?.error = e.message;
      });
    } catch (e) {
      setState(() {
        _docs[key]?.uploading = false;
        _docs[key]?.error = 'Upload failed';
      });
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      setState(() => _error = 'Please upload required documents.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final documentsUrls = <String, String>{};
      for (final entry in _docs.entries) {
        final url = entry.value.url;
        if (url != null && url.isNotEmpty) {
          documentsUrls[entry.key] = url;
        }
      }
      final documents = <String, String>{
        'fssai': widget.draft.fssaiNumber,
        'pan': _panNumber.text.trim(),
      };
      if (widget.draft.gstNumber.trim().isNotEmpty) {
        documents['gst'] = widget.draft.gstNumber.trim();
      }
      if (documentsUrls['cancelled_cheque'] != null) documents['cancelled_cheque'] = 'uploaded';

      final body = {
        'phone': widget.draft.phone,
        'name': widget.draft.restaurantName,
        'address': widget.draft.address,
        'owner_name': widget.draft.ownerName,
        'owner_email': widget.draft.email,
        'cuisines': [widget.draft.cuisine],
        'documents': documents,
        'documents_urls': documentsUrls,
      };
      final res = await ApiClient().post('/v1/partner/auth/register', body: body);
      final data = (res as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final rid = data['restaurant_id']?.toString() ?? '';
      final otp = data['otp']?.toString();
      if (!mounted) return;
      if (otp != null && otp.trim().isNotEmpty) {
        final verifyRes = await ApiClient().post('/v1/partner/auth/verify-otp', body: {
          'restaurant_id': rid,
          'otp': otp,
        });
        final vData = (verifyRes as Map<String, dynamic>)['data'] as Map<String, dynamic>;
        final token = vData['token']?.toString() ?? '';
        final rest = vData['restaurant'] as Map<String, dynamic>? ?? {};
        final approval = rest['approval_status']?.toString() ?? 'inReview';
        final name = rest['name']?.toString() ?? widget.draft.restaurantName;
        await PartnerSession().save(
          token: token,
          restaurantId: rid,
          approvalStatus: approval,
          restaurantName: name,
        );
        if (!mounted) return;
        GoRouter.of(context).go('/review');
      } else {
        GoRouter.of(context).go('/otp', extra: OtpArgs(restaurantId: rid, phone: widget.draft.phone, otp: otp));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgLight,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'maa sharda Go', onBack: () => GoRouter.of(context).pop()),
            _ProgressHeader(title: 'Document Verification', step: 3, total: 4, showPercent: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'To ensure a safe marketplace, please upload valid business documents. Clear photos are preferred.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    _IconField(
                      controller: _panNumber,
                      label: 'PAN Number',
                      hint: 'Enter PAN number',
                      icon: Icons.badge,
                    ),
                    const SizedBox(height: 16),
                    ..._docTypes.map((doc) {
                      final state = _docs[doc.keyName]!;
                      final status = state.url == null ? 'Pending' : 'Uploaded';
                      final actionLabel = state.url == null ? 'Upload' : 'Re-upload';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _kPrimary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(doc.icon, color: _kPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                      if (doc.required)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 6),
                                          child: Text('*', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.uploading ? 'Uploading...' : status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: state.url == null ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                                    ),
                                  ),
                                  if (state.error != null)
                                    Text(state.error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: state.url == null ? _kPrimary : const Color(0xFFE2E8F0),
                                  foregroundColor: state.url == null ? Colors.white : const Color(0xFF0F172A),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: state.uploading ? null : () => _pickAndUpload(doc.keyName),
                                child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.help_outline, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Need help with documents?', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text(
                                  'Contact our onboarding support team available 24/7 for merchant assistance.',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                ),
              ),
            ),
            _BottomAction(
              label: _submitting ? 'Submitting...' : 'Submit Application',
              onPressed: _submitting ? null : _submit,
              enabled: _canSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerApplicationStatusScreen extends StatefulWidget {
  const PartnerApplicationStatusScreen({super.key});

  @override
  State<PartnerApplicationStatusScreen> createState() => _PartnerApplicationStatusScreenState();
}

class _PartnerApplicationStatusScreenState extends State<PartnerApplicationStatusScreen> {
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
      backgroundColor: _kBgLight,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: 'Application Status', onBack: () => GoRouter.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 80, color: _kPrimary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Application Submitted!',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Our team will visit your restaurant for a quick quality check and menu setup.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    _Timeline(status: _status),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.headset_mic, color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Have questions?', style: TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(height: 2),
                                Text('Our support is here to help 24/7', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {},
                            child: const Text('Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loading ? null : _checkStatus,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(_loading ? 'Checking...' : 'Check Status'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'title': 'Application Received', 'subtitle': 'Completed today', 'done': true},
      {'title': 'In-Person Verification', 'subtitle': 'Expect a visit within 2-3 business days', 'done': status == 'approved'},
      {'title': 'Menu Setup & Training', 'subtitle': 'Get your digital kitchen ready', 'done': status == 'approved'},
      {'title': 'Go Live!', 'subtitle': 'Start receiving orders from Maa Sharda Go', 'done': status == 'approved'},
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...steps.map((s) {
            final done = s['done'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: done ? _kPrimary : const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(done ? Icons.check : Icons.circle, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: done ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(s['subtitle'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.title, required this.step, required this.total, this.showPercent = false});
  final String title;
  final int step;
  final int total;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final progress = step / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A))),
              Text('Step $step of $total', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: _kPrimary,
              backgroundColor: _kPrimary.withOpacity(0.15),
            ),
          ),
          if (showPercent)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex, required this.total});
  final int activeIndex;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == activeIndex;
        return Container(
          width: active ? 32 : 20,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? _kPrimary : _kPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.label, required this.onPressed, this.enabled = true});
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: _kBgLight,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _IconField extends StatelessWidget {
  const _IconField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            onChanged: onChanged,
            style: const TextStyle(color: Color(0xFF0F172A)),
            cursorColor: _kPrimary,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _CuisineDropdown extends StatelessWidget {
  const _CuisineDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Primary Cuisine Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text('Select cuisine type', style: TextStyle(color: Color(0xFF94A3B8))),
              style: const TextStyle(color: Color(0xFF0F172A)),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down),
              isExpanded: true,
              onChanged: onChanged,
              items: const [
                DropdownMenuItem(value: 'North Indian', child: Text('North Indian')),
                DropdownMenuItem(value: 'South Indian', child: Text('South Indian')),
                DropdownMenuItem(value: 'Chinese', child: Text('Chinese')),
                DropdownMenuItem(value: 'Continental', child: Text('Continental')),
                DropdownMenuItem(value: 'Street Food', child: Text('Street Food')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.center, required this.onUseMyLocation});
  final LatLng center;
  final VoidCallback onUseMyLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: FlutterMap(
              options: MapOptions(
                center: center,
                zoom: 15,
                interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.maa.sharda.go',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: _kPrimary, size: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              onPressed: onUseMyLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Use My Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
