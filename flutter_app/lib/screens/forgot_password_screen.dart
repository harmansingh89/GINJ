import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone is required.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await AppState.api.post('/api/auth/forgot-password', {
        'phone': phone,
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final otp = body['otp']?.toString() ?? '456456';

        // Prefill OTP for dev convenience
        _otpController.text = otp;

        if (!mounted) return;
        setState(() {
          _otpSent = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent. Dummy OTP is auto-filled. Continue.'),
          ),
        );
        return;
      }

      final errorBody = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorBody['error'] ?? 'Failed to send OTP.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;

    if (phone.isEmpty || otp.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await AppState.api.post('/api/auth/reset-password', {
        'phone': phone,
        'code': otp,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final errorBody = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorBody['error'] ?? 'Password reset failed.'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset failed: $error')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              enabled: !_otpSent,
            ),
            const SizedBox(height: 16),
            if (!_otpSent)
              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Send OTP'),
              ),
            if (_otpSent) ...[
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'OTP'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _resetPassword,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Reset Password'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _otpSent = false;
                    _phoneController.clear();
                    _otpController.clear();
                    _passwordController.clear();
                  });
                },
                child: const Text('Back'),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
