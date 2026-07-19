import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _consentAccepted = false;
  bool _loading = false;

  bool _isAlreadyRegisteredError(String? message) {
    if (message == null) return false;
    final normalized = message.toLowerCase();
    return normalized.contains('already') &&
        (normalized.contains('register') ||
            normalized.contains('exists') ||
            normalized.contains('taken'));
  }

  Future<void> _showAlreadyRegisteredAndGoToLogin(
    String phone,
    String password,
  ) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('phone no is already regitered, please login here'),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/login',
      arguments: {
        'phone': phone,
        'password': password,
      },
    );
  }

  Future<void> _submit() async {
    if (!_consentAccepted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parental consent is required.')),
      );
      return;
    }

    final phone =
        _phoneController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final password = _passwordController.text;

    if (phone.length != 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Enter a valid 10-digit phone number. (got ${phone.length} digits: "$phone")'),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final sendOtpResp = await AppState.api.post('/api/auth/send-otp', {
        'phone': phone,
      });

      if (sendOtpResp.statusCode != 200) {
        final err = jsonDecode(sendOtpResp.body);
        final errMsg = err['error']?.toString();
        if (_isAlreadyRegisteredError(errMsg)) {
          if (!mounted) return;
          await _showAlreadyRegisteredAndGoToLogin(phone, password);
          return;
        }
        _showSnackBar(errMsg ?? 'Failed to send OTP.');
        return;
      }

      final otpBody = jsonDecode(sendOtpResp.body);
      final serverOtp = otpBody['otp']?.toString() ?? '';
      final enteredCode = await _promptForOtp(serverOtp);
      if (enteredCode == null || enteredCode.isEmpty) {
        return;
      }

      final verifyResp = await AppState.api.post('/api/auth/verify-otp', {
        'phone': phone,
        'code': enteredCode,
      });

      if (verifyResp.statusCode != 200) {
        final err = jsonDecode(verifyResp.body);
        if (!mounted) return;
        _showSnackBar(err['error'] ?? 'OTP verification failed.');
        return;
      }

      final signupResponse = await AppState.api.post('/api/auth/signup', {
        'phone': phone,
        'password': password,
        'consentAccepted': _consentAccepted,
      });

      if (signupResponse.statusCode == 201) {
        final loginResponse = await AppState.api.post('/api/auth/login', {
          'phone': phone,
          'password': password,
        });

        if (loginResponse.statusCode == 200) {
          final body = jsonDecode(loginResponse.body);
          final token = body['token'] as String?;
          final userId = body['userId'] as int?;
          if (token != null && userId != null) {
            AppState.api.token = token;
            await AppState.persistSession(token: token, userId: userId);
          }

          final resp = await AppState.api
              .get('/api/userprofiles/by-user/${AppState.userId}');
          if (resp.statusCode == 200) {
            final list = jsonDecode(resp.body) as List<dynamic>;
            if (list.isNotEmpty) {
              final userProfileId = list[0]['id'] as int?;
              if (userProfileId != null) {
                AppState.userProfileId = userProfileId;
                await AppState.persistSession(userProfileId: userProfileId);
              }
              _navigateToHome();
              return;
            }
          }
          _navigateToUserProfile();
          return;
        }
      }

      final errorBody = jsonDecode(signupResponse.body);
      final signupErrMsg = errorBody['error']?.toString();
      if (_isAlreadyRegisteredError(signupErrMsg)) {
        if (!mounted) return;
        await _showAlreadyRegisteredAndGoToLogin(phone, password);
        return;
      }
      _showSnackBar(signupErrMsg ?? 'Signup failed.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Signup failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _promptForOtp(String serverOtp) async {
    if (!mounted) return null;
    return _showOtpDialog(context, serverOtp);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _navigateToUserProfile() {
    if (!mounted) return;
    Navigator.pushNamed(context, '/user-profile');
  }

  Future<String?> _showOtpDialog(
      BuildContext dialogContext, String serverOtp) async {
    final codeController = TextEditingController(text: serverOtp);
    return showDialog<String?>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter OTP'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'OTP'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(codeController.text.trim()),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
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
              maxLength: 10,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Set Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _consentAccepted,
                  onChanged: (checked) {
                    setState(() {
                      _consentAccepted = checked ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text('I agree to parental consent terms.'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have account? '),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
