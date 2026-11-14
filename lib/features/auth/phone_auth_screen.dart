import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_config.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!AppConfig.isSupabaseConfigured) {
      _message('اتصال سامانه هنوز تنظیم نشده است. ورود پیامکی فعلاً فعال نیست.');
      return;
    }
    final phone = _phoneController.text.trim();
    if (!phone.startsWith('+') || phone.length < 10) {
      _message('شماره را با پیش‌شماره کشور وارد کنید؛ مانند ‎+98912xxxxxxx');
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);
      if (!mounted) return;
      setState(() => _otpSent = true);
      _message('کد تأیید ارسال شد.');
    } catch (error) {
      _message('ارسال کد انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!AppConfig.isSupabaseConfigured) return;
    final phone = _phoneController.text.trim();
    final token = _otpController.text.trim();
    if (token.length != 6) {
      _message('کد شش‌رقمی را وارد کنید.');
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      final user = response.user;
      if (user != null) {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'phone': user.phone,
        }, onConflict: 'id');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      _message('کد تأیید نشد: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ورود یا ثبت‌نام')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.lock_person_outlined, size: 64),
          const SizedBox(height: 16),
          const Text(
            'با شماره تلفن وارد استادچی شوید',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'برای مشاهده استادکارها ثبت‌نام لازم نیست. ورود زمانی لازم می‌شود که بخواهید درخواست ثبت کنید یا با متخصص ارتباط بگیرید.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'شماره تلفن همراه',
              hintText: '+98912xxxxxxx',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          if (_otpSent) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'کد تأیید پیامک‌شده',
                prefixIcon: Icon(Icons.password),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : (_otpSent ? _verifyOtp : _sendOtp),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_otpSent ? 'تأیید و ورود' : 'ارسال کد تأیید'),
          ),
          if (_otpSent)
            TextButton(
              onPressed: _busy ? null : _sendOtp,
              child: const Text('ارسال دوباره کد'),
            ),
        ],
      ),
    );
  }
}
