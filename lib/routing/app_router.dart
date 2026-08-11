import 'package:flutter/material.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

abstract final class AppRouter {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static Route<void> onGenerateRoute(RouteSettings settings) =>
      MaterialPageRoute<void>(
        builder: (_) => switch (settings.name) {
          login => const LoginScreen(),
          home => const HomeScreen(),
          _ => const SplashScreen(),
        },
        settings: settings,
      );
}
