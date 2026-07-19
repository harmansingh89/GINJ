import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _prefilledFromArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_prefilledFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final phone = args['phone']?.toString();
      final password = args['password']?.toString();

      if (phone != null && phone.isNotEmpty) {
        _phoneController.text = phone;
      }
      if (password != null && password.isNotEmpty) {
        _passwordController.text = password;
      }
    }

    _prefilledFromArgs = true;
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone and password are required.')),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await AppState.api.post('/api/auth/login', {
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body['token'] as String?;
        final userId = body['userId'] as int?;
        if (token != null && userId != null) {
          AppState.api.token = token;
          await AppState.persistSession(token: token, userId: userId);
          if (!mounted) return;
          await _postLoginNavigate();
          return;
        }
      }

      if (response.statusCode == 401) {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['error'] ??
            'Phone number or password does not match. Please try again.';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: 'Sign Up',
              onPressed: () {
                if (!mounted) return;
                Navigator.pushNamed(context, '/signup');
              },
            ),
          ),
        );
        return;
      }

      final errorBody = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorBody['error'] ?? 'Login failed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _postLoginNavigate() async {
    if (AppState.userId == null) return;
    try {
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
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      }
    } catch (e) {
      // ignore and fall back to user profile creation
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/user-profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
              child: const Text('Forgot Password?'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New user? '),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Sign Up'),
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
    super.dispose();
  }
}
