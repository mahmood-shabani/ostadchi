import 'package:flutter/material.dart';

import '../../models/worker.dart';
import '../auth/phone_auth_screen.dart';
import '../requests/create_request_screen.dart';

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({super.key, required this.worker});

  final Worker worker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل استادکار')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundImage: worker.avatarUrl == null || worker.avatarUrl!.isEmpty
                        ? null
                        : NetworkImage(worker.avatarUrl!),
                    child: worker.avatarUrl == null || worker.avatarUrl!.isEmpty
                        ? Text(
                            worker.name.isEmpty ? 'ا' : worker.name.substring(0, 1),
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    worker.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(worker.headline),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      Text(worker.city),
                      const SizedBox(width: 14),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      Text(
                        worker.reviewCount == 0
                            ? 'بدون امتیاز ثبت‌شده'
                            : '${worker.rating} (${worker.reviewCount} نظر)',
                      ),
                    ],
                  ),
                  if (worker.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Chip(
                        avatar: Icon(Icons.verified, color: Colors.blue),
                        label: Text('تأییدشده'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _section('درباره استادکار', worker.bio.isEmpty ? 'اطلاعاتی ثبت نشده است.' : worker.bio),
          _section('سابقه کاری', '${worker.experienceYears} سال تجربه'),
          _section('نمونه‌کارها', 'پس از اتصال پایگاه داده، تصاویر پروژه‌های انجام‌شده در این بخش نمایش داده می‌شوند.'),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateRequestScreen(worker: worker),
                ),
              );
            },
            icon: const Icon(Icons.assignment_add),
            label: const Text('ثبت درخواست برای این استادکار'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
              );
            },
            icon: const Icon(Icons.phone),
            label: const Text('ورود برای ارتباط با استادکار'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
