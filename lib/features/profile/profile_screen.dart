import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../auth/phone_auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool get _signedIn =>
      AppConfig.isSupabaseConfigured &&
      Supabase.instance.client.auth.currentUser != null;

  Future<void> _openAuth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حساب کاربری')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    child: Icon(Icons.person_outline, size: 34),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _signedIn ? 'حساب شما' : 'به استادچی خوش آمدید',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _signedIn
                        ? 'شماره: ${Supabase.instance.client.auth.currentUser?.phone ?? ''}'
                        : 'برای ثبت درخواست و مدیریت خدمات وارد شوید.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_signedIn)
                    OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout),
                      label: const Text('خروج از حساب'),
                    )
                  else
                    FilledButton(
                      onPressed: _openAuth,
                      child: const Text('ورود یا ثبت‌نام'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.engineering),
                  title: Text('پروفایل استادکاری'),
                  subtitle: Text('ساخت رزومه و معرفی خدمات در مرحله بعد فعال می‌شود.'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text('درخواست تأیید حضوری'),
                  subtitle: Text('امکان درخواست بازدید کارشناس برای استادکاران'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('راهنما و پشتیبانی'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
