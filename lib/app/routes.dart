import 'package:flutter/widgets.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(nextRoute: home),
    home: (_) => const HomeScreen(),
  };
}
