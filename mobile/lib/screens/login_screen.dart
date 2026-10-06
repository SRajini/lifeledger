import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() job) async {
    setState(() { _busy = true; _error = null; });
    try {
      await job();
    } catch (e) {
      setState(() => _error = 'Could not reach the server. Check that the backend is running.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('LifeLedger',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Color(0xFF0E4D4A))),
              const SizedBox(height: 8),
              const Text('Never let a medical bill become a financial crisis.',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number', border: OutlineInputBorder()),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'OTP (demo: 123456)', border: OutlineInputBorder()),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          if (!_otpSent) {
                            await ApiService.sendOtp(_phone.text.trim());
                            setState(() => _otpSent = true);
                          } else {
                            await ApiService.verifyOtp(_phone.text.trim(), _otp.text.trim());
                            if (!mounted) return;
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomeShell()));
                          }
                        }),
                child: Text(_otpSent ? 'Verify and continue' : 'Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
