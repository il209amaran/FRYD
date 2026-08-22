import 'package:flutter/widgets.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/business/presentation/business_profile_screen.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const setup = '/setup';
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashScreen(),
    home: (_) => const HomeScreen(),
    setup: (_) => const BusinessProfileScreen(setupMode: true),
  };
}
