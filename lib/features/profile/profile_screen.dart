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
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _workerHeadlineController = TextEditingController();
  final _workerBioController = TextEditingController();
  final _yearsController = TextEditingController(text: '0');

  bool _loading = false;
  bool _saving = false;
  bool _hasProfile = false;
  bool _hasWorkerProfile = false;
  String? _categoryId;
  List<Map<String, dynamic>> _categories = [];

  SupabaseClient get _client => Supabase.instance.client;
  bool get _signedIn =>
      AppConfig.isSupabaseConfigured && _client.auth.currentUser != null;

  @override
  void initState() {
    super.initState();
    if (_signedIn) _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _workerHeadlineController.dispose();
    _workerBioController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!_signedIn) return;
    setState(() => _loading = true);
    try {
      final userId = _client.auth.currentUser!.id;
      _categories = List<Map<String, dynamic>>.from(
        await _client.from('categories').select('id, name').eq('is_active', true).order('name'),
      );
      final profile = await _client
          .from('profiles')
          .select('display_name, selected_city_id')
          .eq('id', userId)
          .maybeSingle();
      if (profile != null) {
        _nameController.text = (profile['display_name'] ?? '').toString();
        final cityId = profile['selected_city_id']?.toString();
        if (cityId != null) {
          final city = await _client.from('cities').select('name').eq('id', cityId).maybeSingle();
          _cityController.text = (city?['name'] ?? '').toString();
        }
        _hasProfile = _nameController.text.trim().isNotEmpty &&
            _cityController.text.trim().isNotEmpty;
      }
      final worker = await _client
          .from('worker_profiles')
          .select('profession, bio, experience_years')
          .eq('user_id', userId)
          .maybeSingle();
      if (worker != null) {
        _hasWorkerProfile = true;
        _workerHeadlineController.text = (worker['profession'] ?? '').toString();
        _workerBioController.text = (worker['bio'] ?? '').toString();
        _yearsController.text = (worker['experience_years'] ?? 0).toString();
      }
    } catch (error) {
      _showMessage('دریافت اطلاعات حساب انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAuth() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
    );
    if (!mounted) return;
    if (_signedIn) {
      await _loadProfile();
    } else {
      setState(() {});
    }
  }

  Future<void> _saveBasicProfile() async {
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    if (name.isEmpty || city.isEmpty) {
      _showMessage('نام و شهر را وارد کنید.');
      return;
    }
    setState(() => _saving = true);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw StateError('ابتدا وارد حساب کاربری شوید.');
      final cityRow = await _client.from('cities').select('id').ilike('name', city).eq('is_active', true).maybeSingle();
      if (cityRow == null) {
        throw StateError('این شهر در فهرست شهرهای فعال استادچی نیست. فعلاً آبادان، اهواز، تهران و خرمشهر ثبت شده‌اند.');
      }
      await _client.from('profiles').upsert({
        'id': user.id,
        'phone': user.phone,
        'display_name': name,
        'selected_city_id': cityRow['id'],
      }, onConflict: 'id');
      if (!mounted) return;
      setState(() => _hasProfile = true);
      _showMessage('اطلاعات کاربری ذخیره شد.');
    } catch (error) {
      _showMessage('ذخیره اطلاعات انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveWorkerProfile() async {
    final user = _client.auth.currentUser;
    final name = _nameController.text.trim();
    final city = _cityController.text.trim();
    final headline = _workerHeadlineController.text.trim();
    final years = int.tryParse(_yearsController.text.trim());
    if (user == null) {
      _showMessage('ابتدا وارد حساب کاربری شوید.');
      return;
    }
    if (!_hasProfile) {
      _showMessage('ابتدا نام و شهر حساب کاربری را ذخیره کنید.');
      return;
    }
    if (_categoryId == null || years == null || years < 0 || headline.isEmpty) {
      _showMessage('تخصص، عنوان شغلی و سابقه معتبر را وارد کنید.');
      return;
    }

    setState(() => _saving = true);
    try {
      await _client.from('worker_profiles').upsert({
        'user_id': user.id,
        'profession': headline,
        'bio': _workerBioController.text.trim(),
        'experience_years': years,
      }, onConflict: 'user_id');
      await _client.from('user_roles').upsert({
        'user_id': user.id,
        'role': 'worker',
      }, onConflict: 'user_id,role', ignoreDuplicates: true);

      if (!mounted) return;
      setState(() => _hasWorkerProfile = true);
      _showMessage('پروفایل استادکاری ذخیره شد.');
    } catch (error) {
      _showMessage('ذخیره پروفایل استادکاری انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await _client.auth.signOut();
    if (!mounted) return;
    setState(() {
      _hasProfile = false;
      _hasWorkerProfile = false;
      _nameController.clear();
      _cityController.clear();
    });
  }

  void _showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('حساب کاربری')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 38, child: Icon(Icons.person_outline, size: 38)),
                const SizedBox(height: 16),
                const Text('برای ساخت حساب کاربری وارد شوید.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _openAuth, child: const Text('ورود با شماره موبایل')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حساب کاربری')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text('اطلاعات کاربر', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('برای همه کاربران فقط نام و شهر لازم است.'),
                        ),
                        Text('شماره موبایل: ${_client.auth.currentUser?.phone ?? ''}'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'نام و نام خانوادگی'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cityController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(labelText: 'شهر'),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _saving ? null : _saveBasicProfile,
                          child: Text(_saving ? 'در حال ذخیره...' : 'ذخیره اطلاعات کاربری'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.engineering)),
                          title: const Text('پروفایل استادکار', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(_hasWorkerProfile
                              ? 'پروفایل استادکاری شما ثبت شده است؛ می‌توانید آن را ویرایش کنید.'
                              : 'این فرم جداگانه است و فقط برای افرادی است که می‌خواهند استادکار معرفی شوند.'),
                        ),
                        if (!_hasProfile)
                          const Text('ابتدا نام و شهر را در بخش اطلاعات کاربر ذخیره کنید.'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _categoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'تخصص اصلی'),
                          items: _categories
                              .map((item) => DropdownMenuItem<String>(
                                    value: item['id'].toString(),
                                    child: Text(item['name'].toString()),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _categoryId = value),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _workerHeadlineController,
                          decoration: const InputDecoration(labelText: 'عنوان شغلی (مثلاً تعمیرکار موتورسیکلت)'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _yearsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'سابقه کار به سال'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _workerBioController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'توضیحات و معرفی کوتاه (اختیاری)'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _saving || !_hasProfile ? null : _saveWorkerProfile,
                          child: Text(_saving ? 'در حال ذخیره...' : 'ذخیره پروفایل استادکاری'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('خروج از حساب'),
                ),
              ],
            ),
    );
  }
}

// User profile setup: basic user details and optional worker registration.
