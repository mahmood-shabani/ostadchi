import 'package:flutter/material.dart';

import '../../data/service_categories.dart';
import '../../models/worker.dart';
import '../../services/city_store.dart';
import '../../services/marketplace_repository.dart';
import '../profile/profile_screen.dart';
import '../requests/create_request_screen.dart';
import '../requests/requests_screen.dart';
import '../search/search_screen.dart';
import '../workers/worker_detail_screen.dart';

class _CityPicker extends StatefulWidget {
  const _CityPicker({required this.currentCity, required this.cities});

  final String currentCity;
  final List<String> cities;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('انتخاب شهر', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...widget.cities.map((city) => ListTile(
                title: Text(city),
                trailing: city == widget.currentCity
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, city),
              )),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _city = 'آبادان';
  final _cityStore = CityStore();
  final _repository = MarketplaceRepository();
  late Future<List<Worker>> _workers;

  List<String> _cities = ['آبادان', 'خرمشهر', 'اهواز', 'ماهشهر', 'تهران', 'اصفهان'];

  @override
  void initState() {
    super.initState();
    _workers = _repository.getWorkers(city: _city);
    _loadCity();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _repository.getCityNames();
    if (!mounted) return;
    setState(() => _cities = cities);
  }

  Future<void> _loadCity() async {
    final city = await _cityStore.getSelectedCity();
    if (!mounted) return;
    setState(() {
      _city = city;
      _workers = _repository.getWorkers(city: _city);
    });
  }

  Future<void> _chooseCity() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: _CityPicker(
          currentCity: _city,
          cities: _cities,
        ),
      ),
    );
    if (selected == null) return;
    await _cityStore.saveSelectedCity(selected);
    if (!mounted) return;
    setState(() {
      _city = selected;
      _workers = _repository.getWorkers(city: _city);
    });
  }

  void _openSearch({String? categoryId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialCategoryId: categoryId,
          initialCity: _city,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homeBody(),
      const SearchScreen(),
      const RequestsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.search), label: 'جست‌وجو'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'درخواست‌ها'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حساب من'),
        ],
      ),
    );
  }

  Widget _homeBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('استادچی', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            TextButton.icon(
              onPressed: _chooseCity,
              icon: const Icon(Icons.location_on_outlined),
              label: Text(_city),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF17324D), Color(0xFF1769AA)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('استاد مطمئن، انتخاب آگاهانه',
                          style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('متخصصان شهر خود را ببینید، مقایسه کنید و درخواست کار ثبت کنید.',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('دسته‌بندی خدمات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('همه خدمات')),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: serviceCategories.map((category) => ActionChip(
                    avatar: Icon(category.icon, size: 18),
                    label: Text(category.title),
                    onPressed: () => _openSearch(categoryId: category.id),
                  )).toList(),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('استادکاران در $_city', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('مشاهده همه')),
                  ],
                ),
                FutureBuilder<List<Worker>>(
                  future: _workers,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('دریافت استادکاران ناموفق بود: ${snapshot.error}');
                    }
                    final workers = snapshot.data ?? [];
                    if (workers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Text('هنوز استادکاری در این شهر ثبت نشده است.'),
                      );
                    }
                    return Column(
                      children: workers.map((worker) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => WorkerDetailScreen(worker: worker)),
                            ),
                            leading: CircleAvatar(
                              backgroundImage: worker.avatarUrl == null || worker.avatarUrl!.isEmpty
                                  ? null
                                  : NetworkImage(worker.avatarUrl!),
                              child: worker.avatarUrl == null || worker.avatarUrl!.isEmpty
                                  ? const Icon(Icons.engineering)
                                  : null,
                            ),
                            title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${worker.headline}\n${worker.experienceYears} سال سابقه'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_left),
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
                    ),
                    icon: const Icon(Icons.add_task),
                    label: const Text('ثبت درخواست جدید'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'نسخه توسعه‌ای استادچی — اطلاعات نمونه تا زمان اتصال پایگاه داده',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
