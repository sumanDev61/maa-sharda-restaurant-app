import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/partner_session.dart';
import '../../core/theme/merchant_theme.dart';

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
                style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 16),
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
                style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: () => GoRouter.of(context).go('/review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MerchantTheme.accentGreen,
                  side: const BorderSide(color: MerchantTheme.accentGreen),
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
      color: MerchantTheme.bgDark,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: MerchantTheme.bgCardInner,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.store, color: MerchantTheme.tabInactive) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: MerchantTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(phone.isEmpty ? 'No phone added' : phone, style: const TextStyle(color: MerchantTheme.tabInactive)),
                        const SizedBox(height: 4),
                        Text(address.isEmpty ? 'No address added' : address, style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
                        const SizedBox(height: 8),
                        Text('Partner ID: ${id.isEmpty ? '-' : id}', style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Account', style: TextStyle(color: MerchantTheme.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _DarkRowItem(
                  icon: Icons.account_balance_outlined,
                  title: 'My Bank',
                  subtitle: 'Payout account details',
                  onTap: () {},
                ),
                const Divider(height: 1, color: MerchantTheme.dividerColor),
                _DarkRowItem(
                  icon: Icons.edit_outlined,
                  title: 'Edit Profile',
                  subtitle: ownerName.isEmpty ? 'Update owner details' : ownerName,
                  onTap: () => GoRouter.of(context).go('/profile/manager'),
                ),
                const Divider(height: 1, color: MerchantTheme.dividerColor),
                _DarkRowItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  titleColor: Colors.redAccent,
                  onTap: () async {
                    await PartnerSession().clear();
                    if (context.mounted) GoRouter.of(context).go('/login');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _DarkRowItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Help & Support',
                  subtitle: 'Contact team',
                  onTap: () => GoRouter.of(context).go('/profile/help'),
                ),
                const Divider(height: 1, color: MerchantTheme.dividerColor),
                _DarkRowItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: ownerEmail.isEmpty ? 'Merchant portal' : ownerEmail,
                  onTap: () => GoRouter.of(context).go('/profile/about'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkRowItem extends StatelessWidget {
  const _DarkRowItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MerchantTheme.bgCardInner,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: MerchantTheme.accentGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: titleColor ?? MerchantTheme.textPrimary, fontWeight: FontWeight.w700)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MerchantTheme.tabInactive),
          ],
        ),
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
      backgroundColor: MerchantTheme.bgDark,
      body: SafeArea(
        child: ListView(
          children: [
            _HeaderBar(title: 'Manager Profile', showBack: true),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _Avatar(imageUrl: imageUrl, size: 104),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MerchantTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: MerchantTheme.dimGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Owner', style: TextStyle(color: MerchantTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.isEmpty ? 'Restaurant' : restaurant,
                      style: const TextStyle(color: MerchantTheme.tabInactive),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit Profile'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.lock_reset, size: 18),
                            label: const Text('Password'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: MerchantTheme.textPrimary,
                              side: const BorderSide(color: MerchantTheme.dividerColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionTitle(title: 'Contact Information'),
            _Card(
              children: [
                _RowItem(icon: Icons.call, title: 'Phone', subtitle: phone, onTap: () {}),
                _RowItem(icon: Icons.mail, title: 'Email', subtitle: email, onTap: () {}),
                _RowItem(icon: Icons.location_on, title: 'Address', subtitle: _profile['address']?.toString() ?? '', onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            const _SectionTitle(title: 'Account Settings'),
            _Card(
              children: [
                _RowItem(icon: Icons.notifications, title: 'Notification Preferences', subtitle: 'Push & SMS alerts', onTap: () {}),
                _RowItem(icon: Icons.language, title: 'Language', trailingText: 'English', onTap: () {}),
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
      backgroundColor: MerchantTheme.bgDark,
      body: SafeArea(
        child: ListView(
          children: [
            _HeaderBar(title: 'Commission & Agreements', showBack: true),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MerchantTheme.bgCardInner,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MerchantTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Current Tier', style: TextStyle(color: MerchantTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8)),
                    SizedBox(height: 6),
                    Text('10% Commission', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: MerchantTheme.textPrimary)),
                    SizedBox(height: 8),
                    Text('Your commission rate is based on the Premium Partner tier. Next review scheduled soon.', style: TextStyle(color: MerchantTheme.tabInactive)),
                  ],
                ),
              ),
            ),
            const _SectionTitle(title: 'Active Agreements'),
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
                  color: MerchantTheme.bgCardInner,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MerchantTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.gavel, color: MerchantTheme.tabInactive, size: 36),
                    const SizedBox(height: 8),
                    const Text('Legal Contract Details', style: TextStyle(fontWeight: FontWeight.w700, color: MerchantTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text(
                      'View the complete terms and conditions of your partnership with Maa Sharda Go.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MerchantTheme.tabInactive),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('View Full Contract'),
                      style: ElevatedButton.styleFrom(backgroundColor: MerchantTheme.accentGreen, foregroundColor: const Color(0xFF003300)),
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
                style: TextStyle(color: MerchantTheme.tabInactive, fontSize: 12),
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
        color: MerchantTheme.bgDark,
        border: Border(bottom: BorderSide(color: MerchantTheme.dividerColor)),
      ),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => GoRouter.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              color: MerchantTheme.textPrimary,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MerchantTheme.textPrimary),
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
      color: MerchantTheme.bgCard,
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
                  color: MerchantTheme.accentGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.verified, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: MerchantTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Official Partner', style: TextStyle(color: MerchantTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text('Merchant ID: ${id.isEmpty ? '-' : '#$id'}', style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
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
        color: MerchantTheme.bgCardInner,
        image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
      ),
      child: imageUrl.isEmpty
          ? const Icon(Icons.store, color: MerchantTheme.tabInactive, size: 40)
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
          color: MerchantTheme.tabInactive,
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
        color: MerchantTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MerchantTheme.dividerColor),
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
          border: Border(bottom: BorderSide(color: MerchantTheme.dividerColor)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MerchantTheme.bgCardInner,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: MerchantTheme.accentGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: titleColor ?? MerchantTheme.textPrimary)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: const TextStyle(color: MerchantTheme.tabInactive, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (actionLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MerchantTheme.dimGreen.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(actionLabel!, style: const TextStyle(color: MerchantTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12)),
              )
            else if (trailingText != null)
              Text(trailingText!, style: const TextStyle(color: MerchantTheme.accentGreen, fontWeight: FontWeight.w700, fontSize: 12))
            else
              const Icon(Icons.chevron_right, color: MerchantTheme.tabInactive),
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
          backgroundColor: MerchantTheme.bgCardInner,
          foregroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MerchantTheme.bgDark,
      body: SafeArea(
        child: ListView(
          children: [
            _HeaderBar(title: 'Help & Support', showBack: true),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Need help?', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Reach out to our partner support team for quick assistance.', style: TextStyle(color: MerchantTheme.tabInactive)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionTitle(title: 'Contact Us'),
            _Card(
              children: [
                _RowItem(icon: Icons.call, title: 'Call Support', subtitle: '10:00 AM - 8:00 PM', onTap: () {}),
                _RowItem(icon: Icons.chat, title: 'WhatsApp Support', subtitle: 'Quick replies', onTap: () {}),
                _RowItem(icon: Icons.mail, title: 'Email Us', subtitle: 'support@maashardago.com', onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            const _SectionTitle(title: 'Help Topics'),
            _Card(
              children: [
                _RowItem(icon: Icons.restaurant, title: 'Menu & Pricing', subtitle: 'Add, edit, or update items', onTap: () {}),
                _RowItem(icon: Icons.receipt_long, title: 'Orders & Payments', subtitle: 'Payouts, invoices, and refunds', onTap: () {}),
                _RowItem(icon: Icons.security, title: 'Account & Security', subtitle: 'Login and verification help', onTap: () {}),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MerchantTheme.bgDark,
      body: SafeArea(
        child: ListView(
          children: [
            _HeaderBar(title: 'About', showBack: true),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Maa Sharda Go Partner', style: TextStyle(color: MerchantTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Manage orders, menu, and store settings with ease.', style: TextStyle(color: MerchantTheme.tabInactive)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _SectionTitle(title: 'App Info'),
            _Card(
              children: [
                _RowItem(icon: Icons.tag, title: 'Version', trailingText: '1.0.0', onTap: () {}),
                _RowItem(icon: Icons.description, title: 'Terms of Service', subtitle: 'Read the latest terms', onTap: () {}),
                _RowItem(icon: Icons.privacy_tip, title: 'Privacy Policy', subtitle: 'How we handle data', onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            const _SectionTitle(title: 'Company'),
            _Card(
              children: [
                _RowItem(icon: Icons.public, title: 'Website', subtitle: 'www.maashardago.com', onTap: () {}),
                _RowItem(icon: Icons.location_on, title: 'Office', subtitle: 'Lucknow, India', onTap: () {}),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
