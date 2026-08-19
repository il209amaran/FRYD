import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class FrydApp extends StatelessWidget {
  const FrydApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FRYD',
    debugShowCheckedModeBanner: false,
    theme: FrydTheme.light,
    initialRoute: AppRoutes.splash,
    routes: AppRoutes.routes,
  );
}
