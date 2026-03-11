import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/partner_session.dart';

const _kPrimary = Color(0xFF477EEB);
const _kBgLight = Color(0xFFF6F6F8);
const _kText = Color(0xFF0F172A);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = ApiClient();
  bool _loading = false;
  Map<String, dynamic> _profile = {};
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get('/v1/partner/profile') as Map<String, dynamic>;
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final approval = data['approval_status']?.toString() ?? 'inReview';
      setState(() {
        _profile = data;
        _approved = approval == 'approved';
      });
      if (approval.isNotEmpty) {
        await PartnerSession().save(
          token: PartnerSession().token ?? '',
          restaurantId: PartnerSession().restaurantId ?? '',
          approvalStatus: approval,
          restaurantName: data['name']?.toString() ?? '',
        );
      }
    } catch (_) {
      setState(() {
        _profile = {};
        _approved = false;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                'Profile not available',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (!_approved) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 60),
            const Center(
              child: Text(
                'Your profile will be available after approval.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: () => GoRouter.of(context).go('/review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                ),
                child: const Text('Check Status'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _MerchantProfileAndSettings(profile: _profile),
    );
  }
}

class _MerchantProfileAndSettings extends StatelessWidget {
  const _MerchantProfileAndSettings({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final name = profile['name']?.toString() ?? 'Restaurant';
    final phone = profile['phone']?.toString() ?? '';
    final address = profile['address']?.toString() ?? '';
    final ownerName = profile['owner_name']?.toString() ?? 'Manager';
    final ownerEmail = profile['owner_email']?.toString() ?? '';
    final imageUrl = profile['image_url']?.toString() ?? '';
    final id = profile['id']?.toString() ?? '';

    return Container(
      color: _kBgLight,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _HeaderBar(title: 'Business Profile'),
          _ProfileHero(
            name: name,
            id: id,
            imageUrl: imageUrl,
          ),
          _SectionTitle(title: 'Store Management'),
          _Card(
            children: [
              _RowItem(
                icon: Icons.schedule,
                title: 'Store Timings',
                subtitle: '09:00 AM - 10:00 PM',
                actionLabel: 'Edit',
                onTap: () {},
              ),
              _RowItem(
                icon: Icons.call,
                title: 'Contact Information',
                subtitle: phone.isEmpty ? 'Add contact' : phone,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Administration'),
          _Card(
            children: [
              _RowItem(
                icon: Icons.badge,
                title: 'Manager Profile',
                onTap: () => GoRouter.of(context).go('/profile/manager'),
              ),
              _RowItem(
                icon: Icons.description,
                title: 'Commission & Agreements',
                onTap: () => GoRouter.of(context).go('/profile/commission'),
              ),
              _RowItem(
                icon: Icons.language,
                title: 'App Language',
                subtitle: 'English (US)',
                trailingText: 'English (US)',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _LogoutButton(
              onPressed: () async {
                await PartnerSession().clear();
                if (context.mounted) GoRouter.of(context).go('/login');
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'App Version 2.4.1 (Build 890)',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              address.isEmpty ? '' : address,
              style: const TextStyle(color: _kMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              ownerName.isEmpty ? '' : '$ownerName${ownerEmail.isNotEmpty ? ' · $ownerEmail' : ''}',
              style: const TextStyle(color: _kMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key});

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final _client = ApiClient();
  bool _loading = true;
  Map<String, dynamic> _profile = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get('/v1/partner/profile') as Map<String, dynamic>;
      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() => _profile = data);
    } catch (_) {
      setState(() => _profile = {});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final name = _profile['owner_name']?.toString() ?? 'Manager';
    final email = _profile['owner_email']?.toString() ?? '';
    final phone = _profile['phone']?.toString() ?? '';
    final restaurant = _profile['name']?.toString() ?? '';
    final imageUrl = _profile['image_url']?.toString() ?? '';

    return Scaffold(
      backgroundColor: _kBgLight,
      body: SafeArea(
        child: ListView(
          children: [
            _HeaderBar(title: 'Manager Profile', showBack: true),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.white,
              child: Column(
                children: [
                  _Avatar(imageUrl: imageUrl, size: 120),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('General Manager', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  const SizedBox(height: 6),
                  Text(restaurant, style: const TextStyle(color: Color(0xFF94A3B8))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.lock_reset, size: 18),
                            label: const Text('Password'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE2E8F0),
                              foregroundColor: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionTitle(title: 'Contact Information'),
            _Card(
              children: [
                _RowItem(icon: Icons.call, title: 'Phone', subtitle: phone, onTap: () {}),
                _RowItem(icon: Icons.mail, title: 'Email', subtitle: email, onTap: () {}),
                _RowItem(icon: Icons.location_on, title: 'Address', subtitle: _profile['address']?.toString() ?? '', onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            _SectionTitle(title: 'Account Settings'),
            _Card(
              children: [
                _RowItem(icon: Icons.notifications, title: 'Notification Preferences', onTap: () {}),
                _RowItem(icon: Icons.language, title: 'Language Selection', trailingText: 'English', onTap: () {}),
                _RowItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  titleColor: Colors.redAccent,
                  onTap: () async {
                    await PartnerSession().clear();
                    if (context.mounted) GoRouter.of(context).go('/login');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class CommissionAgreementsScreen extends StatelessWidget {
  const CommissionAgreementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgLight,
      body: SafeArea(
        child: ListView(
          children: [
            _HeaderBar(title: 'Commission & Agreements', showBack: true),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kPrimary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Current Tier', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8)),
                    SizedBox(height: 6),
                    Text('10% Commission', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    SizedBox(height: 8),
                    Text('Your commission rate is based on the Premium Partner tier. Next review: Jan 15, 2024.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
            _SectionTitle(title: 'Active Agreements'),
            _Card(
              children: [
                _RowItem(
                  icon: Icons.description,
                  title: 'Standard Partnership Agreement',
                  subtitle: 'Signed & Activated • Oct 12, 2023',
                  onTap: () {},
                ),
                _RowItem(
                  icon: Icons.verified_user,
                  title: 'Data Processing Addendum (GDPR)',
                  subtitle: 'Version 2.1 • Signed Nov 02, 2023',
                  onTap: () {},
                ),
                _RowItem(
                  icon: Icons.campaign,
                  title: 'Marketing & Promotions Opt-in',
                  subtitle: 'Ongoing • Last updated Dec 01, 2023',
                  onTap: () {},
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.gavel, color: Color(0xFF94A3B8), size: 36),
                    const SizedBox(height: 8),
                    const Text('Legal Contract Details', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                      'View the complete terms and conditions of your partnership with Maa Sharda Go.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('View Full Contract'),
                      style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'By continuing to use the platform, you agree to the latest terms of service.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.title, this.showBack = false});
  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: _kBgLight,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => GoRouter.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              color: const Color(0xFF0F172A),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kText),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name, required this.id, required this.imageUrl});
  final String name;
  final String id;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      color: Colors.white,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              _Avatar(imageUrl: imageUrl, size: 120),
              Container(
                margin: const EdgeInsets.only(right: 6, bottom: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.verified, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kText)),
          const SizedBox(height: 4),
          const Text('Official Partner', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text('Merchant ID: ${id.isEmpty ? '-' : '#$id'}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.size});
  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE2E8F0),
        image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.store, color: Color(0xFF94A3B8), size: 40)
          : null,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.actionLabel,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final String? actionLabel;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
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
              child: Icon(icon, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor ?? _kText)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (actionLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(actionLabel!, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
              )
            else if (trailingText != null)
              Text(trailingText!, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 12))
            else
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text('Log Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
