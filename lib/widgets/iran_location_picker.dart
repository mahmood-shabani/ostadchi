import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>?> showIranLocationPicker(
  BuildContext context, {
  String? initialCityId,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _IranLocationPickerSheet(initialCityId: initialCityId),
  );
}

class _IranLocationPickerSheet extends StatefulWidget {
  const _IranLocationPickerSheet({this.initialCityId});
  final String? initialCityId;

  @override
  State<_IranLocationPickerSheet> createState() => _IranLocationPickerSheetState();
}

class _IranLocationPickerSheetState extends State<_IranLocationPickerSheet> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  String? _provinceId;
  String? _cityId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final provinces = List<Map<String, dynamic>>.from(
        await _client.from('provinces').select('id,name').eq('is_active', true).order('name'),
      );
      String? provinceId;
      String? cityId;
      if (widget.initialCityId != null) {
        final current = await _client.from('cities')
            .select('id,province_id')
            .eq('id', widget.initialCityId!)
            .maybeSingle();
        provinceId = current?['province_id']?.toString();
        cityId = current?['id']?.toString();
      }
      List<Map<String, dynamic>> cities = [];
      if (provinceId != null) {
        cities = List<Map<String, dynamic>>.from(
          await _client.from('cities').select('id,name,province_id')
              .eq('province_id', provinceId).eq('is_active', true).order('name'),
        );
      }
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _provinceId = provinceId;
        _cityId = cityId;
        _cities = cities;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت فهرست استان و شهر انجام نشد: $error')),
      );
    }
  }

  Future<void> _selectProvince(String? value) async {
    if (value == null) return;
    setState(() {
      _provinceId = value;
      _cityId = null;
      _cities = [];
      _loading = true;
    });
    try {
      final cities = List<Map<String, dynamic>>.from(
        await _client.from('cities').select('id,name,province_id')
            .eq('province_id', value).eq('is_active', true).order('name'),
      );
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('دریافت شهرها انجام نشد: $error')),
      );
    }
  }

  void _confirm() {
    if (_provinceId == null || _cityId == null) return;
    final province = _provinces.firstWhere((e) => e['id'].toString() == _provinceId);
    final city = _cities.firstWhere((e) => e['id'].toString() == _cityId);
    Navigator.pop(context, {
      'province_id': _provinceId,
      'province_name': province['name'].toString(),
      'city_id': _cityId,
      'city_name': city['name'].toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: _loading && _provinces.isEmpty
            ? const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('انتخاب استان و شهر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _provinceId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'استان'),
                    items: _provinces.map((p) => DropdownMenuItem<String>(
                      value: p['id'].toString(), child: Text(p['name'].toString()),
                    )).toList(),
                    onChanged: _selectProvince,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _cityId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'شهر'),
                    hint: const Text('ابتدا استان را انتخاب کنید'),
                    items: _cities.map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(), child: Text(c['name'].toString()),
                    )).toList(),
                    onChanged: _loading ? null : (v) => setState(() => _cityId = v),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _cityId == null || _loading ? null : _confirm,
                    child: const Text('تأیید انتخاب'),
                  ),
                ],
              ),
      ),
    );
  }
}
