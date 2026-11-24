import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';
import '../data/demo_workers.dart';
import '../models/worker.dart';

class MarketplaceRepository {
  bool get isOnline => AppConfig.isSupabaseConfigured;

  SupabaseClient get _client => Supabase.instance.client;

  // The home/search UI uses stable slugs, while Supabase stores category UUIDs.
  // Resolve the UI slug to the existing database category before filtering/inserting.
  static const Map<String, String> _categoryNames = {
    'motorcycle': 'تعمیرات موتورسیکلت',
    'automotive': 'خودرو',
    'heavy_machinery': 'ماشین‌آلات سنگین',
    'machining': 'تراشکاری و ماشین‌کاری',
    'spare_parts': 'لوازم یدکی',
    'construction': 'ساختمان و مصالح',
    'electrical': 'برق و الکترونیک',
    'plumbing': 'تأسیسات و لوله‌کشی',
    'welding': 'جوشکاری و فلزکاری',
    'cooling': 'سرمایش و گرمایش',
    'painting': 'نقاشی و دکوراسیون',
    'services': 'خدمات عمومی',
    'other': 'سایر خدمات',
  };

  Future<List<String>> _resolveCategoryUuids(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) return [];
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}
    if (categoryId == null || categoryId.isEmpty) return null;

    // Profile forms already provide a UUID; only resolve UI slugs.
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(categoryId);
    if (isUuid) return categoryId;

    final categoryName = _categoryNames[categoryId];
    // "Other services" has no dedicated row in the current database.
    // Do not send its text slug to a UUID column.
    if (categoryName == null) return null;

    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .eq('name', categoryName)
        .limit(1);
    if (rows.isEmpty) {
      throw StateError('دسته‌بندی «$categoryName» در پایگاه داده پیدا نشد.');
    }
    return rows.first['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (!isOnline) return [];
    final rows = await _client.from('categories').select('id,name').eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String?> getCategoryIdForSlug(String slug) => _resolveCategoryUuid(slug);

  Future<Map<String, dynamic>?> getCityByName(String name) async {
    if (!isOnline) return null;
    final row = await _client.from('cities').select('id,name,province,province_id')
        .eq('name', name).eq('is_active', true).limit(1).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> getProvinces() async {
    if (!isOnline) return [];
    final rows = await _client.from('provinces').select('id,name').eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getCitiesByProvince(String provinceId) async {
    if (!isOnline) return [];
    final rows = await _client.from('cities').select('id,name,province_id')
        .eq('province_id', provinceId).eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

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

    final resolvedCategoryIds = await _resolveCategoryUuids(categoryId);
    var query = _client
        .from('worker_directory')
        .select(
          'user_id, display_name, headline, bio, city, category_id, '
          'years_experience, is_verified, is_available, avatar_url, rating, review_count',
        )
        .eq('is_available', true);

    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (resolvedCategoryIds.isNotEmpty) {
      query = query.inFilter('category_id', resolvedCategoryIds);
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
    required String cityId,
    required String categoryId,
    String? workerId,
  }) async {
    if (!isOnline) throw StateError('اتصال پایگاه داده هنوز پیکربندی نشده است.');
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('برای ثبت درخواست ابتدا وارد حساب کاربری شوید.');
    final resolvedCategoryId = await _resolveCategoryUuid(categoryId);
    if (resolvedCategoryId == null) {
      throw StateError('برای این دسته‌بندی هنوز شناسه‌ای در پایگاه داده تعریف نشده است.');
    }
    await _client.from('projects').insert({
      'customer_id': user.id,
      'city_id': cityId,
      'title': title,
      'description': description,
      'category_id': resolvedCategoryId,
      'target_worker_id': workerId,
      'status': 'open',
    });
  }

  Future<List<Map<String, dynamic>>> getMyRequests() async {
    if (!isOnline || _client.auth.currentUser == null) return [];
    final rows = await _client
        .from('projects')
        .select('id, title, description, status, created_at, cities(name, province)')
        .eq('customer_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
,
    ).hasMatch(categoryId);
    if (isUuid) return [categoryId];

    final categoryName = _categoryNames[categoryId];
    if (categoryName == null) return [];
    final parents = await _client.from('categories').select('id')
        .eq('is_active', true).eq('name', categoryName).limit(1);
    if (parents.isEmpty) {
      throw StateError('دسته‌بندی «$categoryName» در پایگاه داده پیدا نشد. ابتدا migration دسته‌بندی‌ها را اجرا کنید.');
    }
    final parentId = parents.first['id'].toString();
    final children = await _client.from('categories').select('id')
        .eq('is_active', true).eq('parent_id', parentId);
    return [parentId, ...children.map((row) => row['id'].toString())];
  }

  Future<String?> _resolveCategoryUuid(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) return null;

    // Profile forms already provide a UUID; only resolve UI slugs.
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(categoryId);
    if (isUuid) return categoryId;

    final categoryName = _categoryNames[categoryId];
    // "Other services" has no dedicated row in the current database.
    // Do not send its text slug to a UUID column.
    if (categoryName == null) return null;

    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .eq('name', categoryName)
        .limit(1);
    if (rows.isEmpty) {
      throw StateError('دسته‌بندی «$categoryName» در پایگاه داده پیدا نشد.');
    }
    return rows.first['id'].toString();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (!isOnline) return [];
    final rows = await _client.from('categories').select('id,name').eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<String?> getCategoryIdForSlug(String slug) => _resolveCategoryUuid(slug);

  Future<Map<String, dynamic>?> getCityByName(String name) async {
    if (!isOnline) return null;
    final row = await _client.from('cities').select('id,name,province,province_id')
        .eq('name', name).eq('is_active', true).limit(1).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> getProvinces() async {
    if (!isOnline) return [];
    final rows = await _client.from('provinces').select('id,name').eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getCitiesByProvince(String provinceId) async {
    if (!isOnline) return [];
    final rows = await _client.from('cities').select('id,name,province_id')
        .eq('province_id', provinceId).eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

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

    final resolvedCategoryId = await _resolveCategoryUuid(categoryId);
    var query = _client
        .from('worker_directory')
        .select(
          'user_id, display_name, headline, bio, city, category_id, '
          'years_experience, is_verified, is_available, avatar_url, rating, review_count',
        )
        .eq('is_available', true);

    if (city != null && city.isNotEmpty) {
      query = query.eq('city', city);
    }
    if (resolvedCategoryId != null) {
      query = query.eq('category_id', resolvedCategoryId);
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
    required String cityId,
    required String categoryId,
    String? workerId,
  }) async {
    if (!isOnline) throw StateError('اتصال پایگاه داده هنوز پیکربندی نشده است.');
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('برای ثبت درخواست ابتدا وارد حساب کاربری شوید.');
    final resolvedCategoryId = await _resolveCategoryUuid(categoryId);
    if (resolvedCategoryId == null) {
      throw StateError('برای این دسته‌بندی هنوز شناسه‌ای در پایگاه داده تعریف نشده است.');
    }
    await _client.from('projects').insert({
      'customer_id': user.id,
      'city_id': cityId,
      'title': title,
      'description': description,
      'category_id': resolvedCategoryId,
      'target_worker_id': workerId,
      'status': 'open',
    });
  }

  Future<List<Map<String, dynamic>>> getMyRequests() async {
    if (!isOnline || _client.auth.currentUser == null) return [];
    final rows = await _client
        .from('projects')
        .select('id, title, description, status, created_at, cities(name, province)')
        .eq('customer_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
}
