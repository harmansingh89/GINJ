import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _fatherNameController = TextEditingController();
  String? _sex;
  DateTime? _selectedDob;
  bool _loading = false;

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    var age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _selectedDob == null ||
        _sex == null ||
        _fatherNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the user profile.')),
      );
      return;
    }

    final age = _calculateAge(_selectedDob!);
    if (age < 1 || age > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Child age must be between 1 and 100 years.')),
      );
      return;
    }

    if (AppState.userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not signed in.')));
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await AppState.api
          .post('/api/userprofiles/create/${AppState.userId}', {
        'name': _nameController.text,
        'dateOfBirth': _selectedDob?.toIso8601String(),
        'age': _selectedDob != null ? _calculateAge(_selectedDob!) : null,
        'sex': _sex,
        'fatherName': _fatherNameController.text,
      });

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final userProfileId = body['id'] as int?;
        if (userProfileId != null) {
          await AppState.persistSession(userProfileId: userProfileId);
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      if (response.statusCode == 409) {
        // Profile already exists; fetch and go to home
        final resp = await AppState.api
            .get('/api/userprofiles/by-user/${AppState.userId}');
        if (resp.statusCode == 200) {
          final list = jsonDecode(resp.body) as List<dynamic>;
          if (list.isNotEmpty) {
            final userProfileId = list[0]['id'] as int?;
            if (userProfileId != null) {
              await AppState.persistSession(userProfileId: userProfileId);
            }
          }
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      final errorBody = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorBody['error'] ?? 'Failed to save user profile.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save profile: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Partcipant Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dobController,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Date of Birth'),
              onTap: () async {
                final now = DateTime.now();
                final firstDate = DateTime(now.year - 100, now.month, now.day);
                final lastDate = DateTime(now.year - 1, now.month, now.day);
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDob ?? lastDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDob = pickedDate;
                    _dobController.text =
                        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _sex,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              decoration: const InputDecoration(labelText: 'Sex'),
              onChanged: (value) {
                setState(() {
                  _sex = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fatherNameController,
              decoration: const InputDecoration(labelText: 'Father Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
