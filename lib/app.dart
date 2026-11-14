import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'features/home/home_screen.dart';

class OstadchiApp extends StatelessWidget {
  const OstadchiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'استادچی',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HomeScreen(),
      ),
    );
  }
}
