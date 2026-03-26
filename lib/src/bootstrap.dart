import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'core/push/push_service.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await PushService.initAndSync();
  runApp(const ProviderScope(child: App()));
}
