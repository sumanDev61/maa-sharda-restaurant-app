import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/merchant_theme.dart';
import 'core/auth/partner_session.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: PartnerSession().load(),
      builder: (context, snap) {
        final ready = snap.connectionState == ConnectionState.done;
        if (!ready) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MerchantTheme.dark,
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final isLoggedIn = (PartnerSession().token ?? '').isNotEmpty &&
            (PartnerSession().restaurantId ?? '').isNotEmpty;
        final router = createRouter(isLoggedIn: isLoggedIn);
        return MaterialApp.router(
          title: 'Maa Sharda Go - Merchant Portal',
          debugShowCheckedModeBanner: false,
          theme: MerchantTheme.dark,
          darkTheme: MerchantTheme.dark,
          themeMode: ThemeMode.dark,
          routerConfig: router,
        );
      },
    );
  }
}
