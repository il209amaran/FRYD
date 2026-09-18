import 'package:flutter/material.dart';

import '../../../core/database/database_manager.dart';
import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../business/data/business_settings_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    var nextRoute = AppRoutes.home;
    try {
      await DatabaseManager.instance.database;
      final settings = await BusinessSettingsRepository().get();
      CurrencyFormatter.update(settings);
      if (!settings.setupCompleted) nextRoute = AppRoutes.setup;
    } catch (error, stackTrace) {
      debugPrint('Database initialization failed: $error\n$stackTrace');
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(nextRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _backgroundColor,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final isPortrait = constraints.maxHeight >= constraints.maxWidth;
        return SizedBox.expand(
          child: Image.asset(
            isPortrait
                ? 'images/splash_potrait.png'
                : 'images/splash_landscape.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
          ),
        );
      },
    ),
  );
}
