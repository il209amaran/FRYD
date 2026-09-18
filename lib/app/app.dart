import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class KanakkiApp extends StatelessWidget {
  const KanakkiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kanakki',
    debugShowCheckedModeBanner: false,
    theme: KanakkiTheme.light,
    initialRoute: AppRoutes.splash,
    routes: AppRoutes.routes,
  );
}
