import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/merchant_shell.dart';
import '../../features/auth/login_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/store/presentation/store_screen.dart';

class _HistoryScreen extends StatelessWidget {
  const _HistoryScreen();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Order History',
        style: TextStyle(color: Colors.white54, fontSize: 18),
      ),
    );
  }
}

final _screens = <Widget>[
  const OrdersScreen(),
  const _HistoryScreen(),
  const MenuScreen(),
  const StoreScreen(),
];

GoRouter createRouter({required bool isLoggedIn}) {
  return GoRouter(
    initialLocation: isLoggedIn ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(child: PartnerLoginScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.toString();
          int index = 0;
          if (location.startsWith('/history')) {
            index = 1;
          } else if (location.startsWith('/menu')) {
            index = 2;
          } else if (location.startsWith('/store')) {
            index = 3;
          }
          return MerchantShell(
            currentIndex: index,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  GoRouter.of(context).go('/');
                  break;
                case 1:
                  GoRouter.of(context).go('/history');
                  break;
                case 2:
                  GoRouter.of(context).go('/menu');
                  break;
                case 3:
                  GoRouter.of(context).go('/store');
                  break;
              }
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'orders',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrdersScreen()),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: _HistoryScreen()),
          ),
          GoRoute(
            path: '/menu',
            name: 'menu',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MenuScreen()),
          ),
          GoRoute(
            path: '/store',
            name: 'store',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StoreScreen()),
          ),
        ],
      ),
    ],
  );
}
