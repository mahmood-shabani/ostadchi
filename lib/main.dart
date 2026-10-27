import 'package:flutter/material.dart';

void main() => runApp(const OstadchiApp());

class OstadchiApp extends StatelessWidget {
  const OstadchiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'استادچی',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        ),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('استادچی'), centerTitle: true),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('استاد موردنظرت را پیدا کن',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('مشاهده، مقایسه و انتخاب متخصصان فنی در شهر شما'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('دسته‌بندی خدمات',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  CategoryChip(label: 'تعمیرات موتور', icon: Icons.two_wheeler),
                  CategoryChip(label: 'برق‌کاری', icon: Icons.electrical_services),
                  CategoryChip(label: 'لوله‌کشی', icon: Icons.plumbing),
                  CategoryChip(label: 'جوشکاری', icon: Icons.handyman),
                  CategoryChip(label: 'ساختمان', icon: Icons.home_repair_service),
                  CategoryChip(label: 'سایر خدمات', icon: Icons.more_horiz),
                ],
              ),
              const SizedBox(height: 24),
              const Text('شروع سریع',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ActionTile(icon: Icons.search, title: 'جست‌وجوی استادکار',
                  subtitle: 'پروفایل‌ها و نمونه‌کارها را بررسی کن',
                  onTap: () => showInfo(context, 'جست‌وجوی استادکار')),
              ActionTile(icon: Icons.work_outline, title: 'ثبت درخواست کار',
                  subtitle: 'شرح کار و شهر موردنظر را وارد کن',
                  onTap: () => showInfo(context, 'ثبت درخواست کار')),
              ActionTile(icon: Icons.person_outline, title: 'ورود یا ثبت‌نام',
                  subtitle: 'برای شروع، شماره تلفن خود را آماده داشته باش',
                  onTap: () => showInfo(context, 'ورود یا ثبت‌نام')),
              const SizedBox(height: 16),
              const Text('نسخه آزمایشی ۰٫۴ — ورود پیامکی و پایگاه داده هنوز فعال نیست',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      );

  static void showInfo(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('این بخش در نسخه آزمایشی نمایشی است و هنوز به سامانه واقعی وصل نشده است.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(),
              child: const Text('متوجه شدم')),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      );
}

class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.title,
    required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left),
          onTap: onTap,
        ),
      );
}
