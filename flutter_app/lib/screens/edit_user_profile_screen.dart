import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _nameController = TextEditingController();
  final _fatherController = TextEditingController();
  DateTime? _dob;
  String _sex = 'Male';
  bool _loading = false;
  bool _isProfileLocked = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (AppState.userId == null) return;
    setState(() => _loading = true);
    try {
      final resp = await AppState.api
          .get('/api/userprofiles/by-user/${AppState.userId}');
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final item = list[0] as Map<String, dynamic>;
          _nameController.text = item['name'] ?? '';
          _fatherController.text = item['fatherName'] ?? '';
          _sex = item['sex'] ?? 'Male';
          _dob = DateTime.tryParse(item['dateOfBirth'] ?? '')?.toLocal();
          AppState.userProfileId = item['id'];
          await _checkEditLock();
        }
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (AppState.userId == null) return;
    final name = _nameController.text.trim();
    final father = _fatherController.text.trim();
    if (name.isEmpty || _dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and DOB required.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final age = DateTime.now().difference(_dob!).inDays ~/ 365;
      final body = {
        'name': name,
        'dateOfBirth': _dob!.toUtc().toIso8601String(),
        'age': age,
        'sex': _sex,
        'fatherName': father,
      };
      final resp = await AppState.api
          .put('/api/userprofiles/update/${AppState.userId}', body);
      if (resp.statusCode == 200) {
        final obj = jsonDecode(resp.body);
        AppState.userProfileId = obj['id'];
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated.')));
        Navigator.pop(context);
        return;
      }
      final error = jsonDecode(resp.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['error'] ?? 'Update failed.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDob() async {
    if (_isProfileLocked) return;

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(now.year - 100, now.month, now.day),
      lastDate: DateTime(now.year - 1, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _checkEditLock() async {
    if (AppState.userProfileId == null) return;
    try {
      final resp = await AppState.api
          .get('/api/submissions/by-user-profile/${AppState.userProfileId}');
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        if (!mounted) return;
        setState(() {
          _isProfileLocked = list.isNotEmpty;
        });
      }
    } catch (e) {
      // ignore lock check failure
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm sign out'),
        content: const Text('Do you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AppState.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isProfileLocked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'The user profile cannot be edited after a submission has been processed.',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  TextField(
                      controller: _nameController,
                      enabled: !_isProfileLocked,
                      decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _fatherController,
                      enabled: !_isProfileLocked,
                      decoration:
                          const InputDecoration(labelText: 'Father name')),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('DOB: '),
                    Text(_dob == null
                        ? 'Not set'
                        : '${_dob!.toLocal()}'.split(' ')[0]),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isProfileLocked ? null : _pickDob,
                      child: const Text('Pick'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                      value: _sex,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: _isProfileLocked
                          ? null
                          : (v) => setState(() => _sex = v ?? 'Male')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isProfileLocked ? null : _submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }
}
