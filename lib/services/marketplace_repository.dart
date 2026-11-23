import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';
import '../data/demo_workers.dart';
import '../models/worker.dart';

class MarketplaceRepository {
  bool get isOnline => AppConfig.isSupabaseConfigured;

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<String>> getCityNames() async {
    if (!isOnline) return ['آبادان', 'خرمشهر', 'اهواز', 'ماهشهر', 'تهران', 'اصفهان'];
    try {
      final rows = await _client.from('cities').select('name').eq('is_active', true).order('name');
      final names = (rows as List).map((row) => row['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList();
      return names.isEmpty ? ['آبادان', 'خرمشهر', 'اهواز', 'ماهشهر', 'تهران', 'اصفهان'] : names;
    } catch (_) {
      return ['آبادان', 'خرمشهر', 'اهواز', 'ماهشهر', 'تهران', 'اصفهان'];
    }
  }

  Future<List<Worker>> getWorkers({
    String? city,
    String? categoryId,
    String search = '',
  }) async {
    if (!isOnline) {
      return _filterDemoWorkers(
        city: city,
        categoryId: categoryId,
        search: search,
      );
    }

    var query = _client
        .from('worker_directory')
        .select(
          'user_id, display_name, headline, bio, city, category_id, '
          'years_experience, is_verified, is_available, rating, review_count',
        )
        .eq('is_available', true);

    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (search.trim().isNotEmpty) {
      query = query.ilike('display_name', '%${search.trim()}%');
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Worker.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  List<Worker> _filterDemoWorkers({
    String? city,
    String? categoryId,
    required String search,
  }) {
    return demoWorkers.where((worker) {
      final cityMatches =
          city == null || city.isEmpty || worker.city == city;
      final categoryMatches =
          categoryId == null || categoryId.isEmpty ||
          worker.categoryId == categoryId;
      final searchMatches = search.isEmpty ||
          worker.name.contains(search) ||
          worker.headline.contains(search) ||
          worker.bio.contains(search);
      return cityMatches && categoryMatches && searchMatches;
    }).toList();
  }

  Future<void> createWorkRequest({
    required String title,
    required String description,
    required String city,
    required String categoryId,
    String? workerId,
  }) async {
    if (!isOnline) {
      throw StateError('اتصال پایگاه داده هنوز پیکربندی نشده است.');
    }
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('برای ثبت درخواست ابتدا وارد حساب کاربری شوید.');
    }
    await _client.from('work_requests').insert({
      'customer_id': user.id,
      'worker_id': workerId,
      'title': title,
      'description': description,
      'city': city,
      'category_id': categoryId,
      'status': 'open',
    });
  }

  Future<List<Map<String, dynamic>>> getMyRequests() async {
    if (!isOnline || _client.auth.currentUser == null) return [];
    final rows = await _client
        .from('work_requests')
        .select('id, title, description, city, status, created_at')
        .eq('customer_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
