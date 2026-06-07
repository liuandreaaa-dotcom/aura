import 'package:flutter/material.dart';
import '../../features/chat/ui/chat_list_page.dart';
import '../../features/chat/ui/chat_detail_page.dart';
import '../../features/dashboard/ui/dashboard_page.dart';
import '../../features/settings/ui/settings_page.dart';

class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String chatDetail = '/chat';
  static const String settings = '/settings';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: routeSettings,
        );
      case chatDetail:
        final conversationId = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ChatDetailPage(conversationId: conversationId),
          settings: routeSettings,
        );
      case settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
          settings: routeSettings,
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: routeSettings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: routeSettings,
        );
    }
  }
}