import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/merchant_shell.dart';
import '../../features/auth/login_screen.dart';
import '../../features/menu/presentation/menu_screen.dart';
import '../../features/store/presentation/store_screen.dart';
import '../../features/orders/presentation/history_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';

final _screens = <Widget>[
  const OrdersScreen(),
  const HistoryScreen(),
  const MenuScreen(),
  const StoreScreen(),
  const ProfileScreen(),
];

GoRouter createRouter({required bool isLoggedIn, bool needsReview = false}) {
  return GoRouter(
    initialLocation: isLoggedIn ? (needsReview ? '/review' : '/') : '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(child: PartnerLoginScreen()),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: PartnerOtpScreen(args: state.extra as OtpArgs?)),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) =>
            NoTransitionPage(child: PartnerRegisterScreen(args: state.extra as RegisterArgs?)),
      ),
      GoRoute(
        path: '/review',
        name: 'review',
        pageBuilder: (context, state) => const NoTransitionPage(child: PartnerReviewScreen()),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsScreen()),
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
          } else if (location.startsWith('/profile')) {
            index = 4;
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
                case 4:
                  GoRouter.of(context).go('/profile');
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
                const NoTransitionPage(child: HistoryScreen()),
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
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}
