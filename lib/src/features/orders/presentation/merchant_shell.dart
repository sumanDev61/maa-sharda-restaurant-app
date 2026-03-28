import 'package:flutter/material.dart';
import '../../../core/theme/merchant_theme.dart';
import 'package:go_router/go_router.dart';

class MerchantShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const MerchantShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MerchantTheme.bgDark,
      appBar: _buildAppBar(context),
      body: child,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: MerchantTheme.bgDark,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(
            Icons.menu,
            color: MerchantTheme.accentGreen,
            size: 26,
          ),
          onPressed: () {},
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Maa Sharda Go',
            style: TextStyle(
              color: MerchantTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'MERCHANT PORTAL',
            style: TextStyle(
              color: MerchantTheme.accentGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: MerchantTheme.accentGreen,
                  size: 26,
                ),
                onPressed: () => GoRouter.of(context).push('/notifications'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: MerchantTheme.navBarBg,
        border: Border(
          top: BorderSide(
            color: MerchantTheme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.receipt_long,
                label: 'ORDERS',
                isSelected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _NavItem(
                icon: Icons.history,
                label: 'HISTORY',
                isSelected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _NavItem(
                icon: Icons.restaurant_menu,
                label: 'MENU',
                isSelected: currentIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _NavItem(
                icon: Icons.restaurant,
                label: 'RESTAURANT',
                isSelected: currentIndex == 3,
                onTap: () => onDestinationSelected(3),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'PROFILE',
                isSelected: currentIndex == 4,
                onTap: () => onDestinationSelected(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isSelected ? MerchantTheme.accentGreen : MerchantTheme.tabInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
