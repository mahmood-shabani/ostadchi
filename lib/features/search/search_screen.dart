import 'package:flutter/material.dart';

import '../../data/service_categories.dart';
import '../../models/worker.dart';
import '../../services/marketplace_repository.dart';
import '../../services/city_store.dart';
import '../workers/worker_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialCategoryId, this.initialCity});

  final String? initialCategoryId;
  final String? initialCity;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _repository = MarketplaceRepository();
  String? _categoryId;
  String _city = 'آبادان';
  late Future<List<Worker>> _workers;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _city = widget.initialCity ?? 'آبادان';
    _workers = _load();
    CityStore().getSelectedCity().then((city) {
      if (!mounted) return;
      setState(() {
        _city = widget.initialCity ?? city;
        _workers = _load();
      });
    });
  }

  Future<List<Worker>> _load() => _repository.getWorkers(
        city: _city,
        categoryId: _categoryId,
        search: _searchController.text,
      );

  void _refresh() => setState(() => _workers = _load());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جست‌وجوی استادکار')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _refresh(),
              decoration: const InputDecoration(
                hintText: 'نام استادکار یا تخصص را جست‌وجو کنید',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('همه'),
                    selected: _categoryId == null,
                    onSelected: (_) {
                      setState(() => _categoryId = null);
                      _refresh();
                    },
                  ),
                ),
                ...serviceCategories.map((category) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(category.title),
                        selected: _categoryId == category.id,
                        onSelected: (_) {
                          setState(() => _categoryId = category.id);
                          _refresh();
                        },
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Worker>>(
              future: _workers,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('دریافت اطلاعات ناموفق بود: ${snapshot.error}'));
                }
                final workers = snapshot.data ?? [];
                if (workers.isEmpty) {
                  return const Center(child: Text('استادکاری با این مشخصات پیدا نشد.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: workers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _WorkerTile(
                    worker: workers[index],
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkerDetailScreen(worker: workers[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({required this.worker, required this.onTap});
  final Worker worker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.engineering)),
        title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${worker.headline}\n${worker.city} • ${worker.experienceYears} سال سابقه'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
