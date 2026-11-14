import 'package:flutter/material.dart';

import '../../data/service_categories.dart';
import '../../models/worker.dart';
import '../../services/marketplace_repository.dart';
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
  final _city = TextEditingController(text: 'آبادان');
  final _repository = MarketplaceRepository();
  String _categoryId = 'motorcycle';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      _city.text = widget.worker!.city;
      _categoryId = widget.worker!.categoryId;
      _title.text = 'درخواست خدمت از ${widget.worker!.name}';
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_repository.isOnline) {
      _show('پایگاه داده هنوز فعال و پیکربندی نشده است؛ درخواست ذخیره نشد.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _repository.createWorkRequest(
        title: _title.text.trim(),
        description: _description.text.trim(),
        city: _city.text.trim(),
        categoryId: _categoryId,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'عنوان درخواست'),
              validator: (value) => value == null || value.trim().length < 4
                  ? 'عنوان را کامل وارد کنید.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'تخصص موردنیاز'),
              items: serviceCategories
                  .map((item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.title),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _categoryId = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'شهر محل انجام کار'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'شهر را وارد کنید.'
                  : null,
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
                  ? 'شرح کار باید حداقل ۱۰ حرف باشد.'
                  : null,
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
