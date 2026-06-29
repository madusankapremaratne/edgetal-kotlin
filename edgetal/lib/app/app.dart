import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

class EdgeTalApp extends StatelessWidget {
  const EdgeTalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EdgeTal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
