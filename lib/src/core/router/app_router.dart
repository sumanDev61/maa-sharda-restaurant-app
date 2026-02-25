import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: _NavBar(),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'menu',
            pageBuilder: (context, state) => const NoTransitionPage(child: MenuScreen()),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            pageBuilder: (context, state) => const NoTransitionPage(child: OrdersScreen()),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            pageBuilder: (context, state) => const NoTransitionPage(child: CartScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}

class _NavBar extends StatefulWidget {
  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  int current = 0;
  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).routeInformationProvider.value.uri.toString();
    if (location.startsWith('/orders')) {
      current = 1;
    } else if (location.startsWith('/cart')) {
      current = 2;
    } else if (location.startsWith('/profile')) {
      current = 3;
    } else {
      current = 0;
    }
    return NavigationBar(
      selectedIndex: current,
      onDestinationSelected: (i) {
        if (i == 0) {
          context.go('/');
        }
        if (i == 1) {
          context.go('/orders');
        }
        if (i == 2) {
          context.go('/cart');
        }
        if (i == 3) {
          context.go('/profile');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag), label: 'Cart'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
