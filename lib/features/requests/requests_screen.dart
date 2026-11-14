import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';
import '../../services/marketplace_repository.dart';
import '../auth/phone_auth_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _repository = MarketplaceRepository();
  late Future<List<Map<String, dynamic>>> _requests;

  bool get _signedIn => AppConfig.isSupabaseConfigured &&
      Supabase.instance.client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    _requests = _repository.getMyRequests();
  }

  Future<void> _login() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
    if (mounted) setState(() => _requests = _repository.getMyRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('درخواست‌های من')),
      body: !_signedIn
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 52),
                    const SizedBox(height: 12),
                    const Text('برای مشاهده درخواست‌ها وارد حساب شوید.'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _login, child: const Text('ورود')),
                  ],
                ),
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _requests,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('خطا: ${snapshot.error}'));
                }
                final rows = snapshot.data ?? [];
                if (rows.isEmpty) {
                  return const Center(child: Text('هنوز درخواستی ثبت نکرده‌اید.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Card(
                      child: ListTile(
                        title: Text(row['title']?.toString() ?? 'درخواست'),
                        subtitle: Text('${row['city'] ?? ''} • ${row['status'] ?? ''}'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
