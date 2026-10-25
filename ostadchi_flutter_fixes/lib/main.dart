import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.hasSupabaseConfig) {
    runApp(const _StartupErrorApp(
      title: 'تنظیمات سرویس کامل نیست',
      details: 'آدرس پروژه و کلید عمومی Supabase در زمان ساخت تنظیم نشده‌اند.',
    ));
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    runApp(const OstadchiApp());
  } catch (error, stackTrace) {
    debugPrint('Supabase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_StartupErrorApp(
      title: 'اتصال به سرویس برقرار نشد',
      details: 'تنظیمات یا دسترسی شبکه و پروژه Supabase را بررسی کنید. برنامه جزئیات خطا را در گزارش اجرا ثبت کرده است.',
    ));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.title, required this.details});

  final String title;
  final String details;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(details, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}
