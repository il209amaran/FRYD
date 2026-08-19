import 'package:flutter/material.dart';

import '../../../core/database/database_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({required this.nextRoute, super.key});

  final String nextRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _backgroundColor = Color(0xFFFFF3E0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    try {
      await DatabaseManager.instance.database;
    } catch (error, stackTrace) {
      debugPrint('Database initialization failed: $error\n$stackTrace');
    } finally {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(widget.nextRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _backgroundColor,
    body: Center(
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: constraints.maxHeight * 0.58,
          child: Image.asset(
            'images/appsplash.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    ),
  );
}
