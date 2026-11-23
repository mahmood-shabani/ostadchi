import 'package:flutter/material.dart';

import '../../models/worker.dart';
import '../../services/marketplace_repository.dart';
import '../../widgets/iran_location_picker.dart';
import '../auth/phone_auth_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, this.worker});
  final Worker? worker;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _repository = MarketplaceRepository();

  List<Map<String, dynamic>> _categories = [];
  String? _categoryId;
  String? _cityId;
  String _cityLabel = '';
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _title.text = 'درخواست خدمت از ${widget.worker!.name}';
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final categories = await _repository.getCategories();
      String? categoryId = widget.worker?.categoryId;
      if (categoryId == null || !categories.any((c) => c['id'].toString() == categoryId)) {
        categoryId = await _repository.getCategoryIdForSlug('motorcycle');
      }
      Map<String, dynamic>? city;
      if (widget.worker != null) {
        city = await _repository.getCityByName(widget.worker!.city);
      } else {
        city = await _repository.getCityByName('آبادان');
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryId = categoryId != null && categories.any((c) => c['id'].toString() == categoryId)
            ? categoryId
            : (categories.isNotEmpty ? categories.first['id'].toString() : null);
        _cityId = city?['id']?.toString();
        _cityLabel = city == null ? '' : '${city['name']} - ${city['province'] ?? ''}';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _show('دریافت اطلاعات فرم انجام نشد: $error');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseLocation() async {
    final selected = await showIranLocationPicker(context, initialCityId: _cityId);
    if (selected == null || !mounted) return;
    setState(() {
      _cityId = selected['city_id']?.toString();
      _cityLabel = '${selected['city_name']} - ${selected['province_name']}';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cityId == null || _categoryId == null) {
      _show('استان، شهر و تخصص را انتخاب کنید.');
      return;
    }
    if (!_repository.isOnline) {
      _show('پایگاه داده هنوز فعال و پیکربندی نشده است؛ درخواست ذخیره نشد.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _repository.createWorkRequest(
        title: _title.text.trim(),
        description: _description.text.trim(),
        cityId: _cityId!,
        categoryId: _categoryId!,
        workerId: widget.worker?.userId,
      );
      if (!mounted) return;
      _show('درخواست با موفقیت ثبت شد.');
      Navigator.of(context).pop();
    } catch (error) {
      if (error.toString().contains('وارد حساب')) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PhoneAuthScreen()),
        );
      } else {
        _show('ثبت درخواست انجام نشد: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت درخواست کار')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'عنوان درخواست'),
                    validator: (value) => value == null || value.trim().length < 4
                        ? 'عنوان را کامل وارد کنید.' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'تخصص موردنیاز'),
                    items: _categories.map((item) => DropdownMenuItem<String>(
                      value: item['id'].toString(),
                      child: Text(item['name'].toString()),
                    )).toList(),
                    onChanged: _busy ? null : (value) => setState(() => _categoryId = value),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _chooseLocation,
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(_cityLabel.isEmpty ? 'انتخاب استان و شهر' : _cityLabel),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'شرح کار و جزئیات',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.trim().length < 10
                        ? 'شرح کار باید حداقل ۱۰ حرف باشد.' : null,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const CircularProgressIndicator()
                        : const Text('ثبت درخواست'),
                  ),
                ],
              ),
            ),
    );
  }
}
