import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _nameController = TextEditingController();
  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _pinController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    if (AppState.userId == null) {
      return;
    }

    try {
      final response = await AppState.api.get('/api/users/${AppState.userId}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final recipientName = body['recipientName'] as String?;
        final houseOrFlatNo = body['houseOrFlatNo'] as String?;
        final streetOrLocality = body['streetOrLocality'] as String?;
        final city = body['city'] as String?;
        final pinCode = body['pinCode'] as String?;
        final savedAddress = body['savedAddress'] as String?;

        if ((recipientName ?? '').isNotEmpty ||
            (houseOrFlatNo ?? '').isNotEmpty ||
            (streetOrLocality ?? '').isNotEmpty ||
            (city ?? '').isNotEmpty ||
            (pinCode ?? '').isNotEmpty) {
          _nameController.text = recipientName ?? '';
          _houseController.text = houseOrFlatNo ?? '';
          _streetController.text = streetOrLocality ?? '';
          _cityController.text = city ?? '';
          _pinController.text = pinCode ?? '';
        } else if (savedAddress != null && savedAddress.isNotEmpty) {
          final match = RegExp(r'^(.*), (.*), (.*), (.*), PIN: (.*)?')
              .firstMatch(savedAddress);
          if (match != null) {
            _nameController.text = match.group(1) ?? '';
            _houseController.text = match.group(2) ?? '';
            _streetController.text = match.group(3) ?? '';
            _cityController.text = match.group(4) ?? '';
            _pinController.text = match.group(5) ?? '';
          } else {
            _streetController.text = savedAddress;
          }
        }
      }
    } catch (_) {
      // ignore failures; user can enter address manually
    }
  }

  Future<void> _submitAddress() async {
    if (_nameController.text.isEmpty ||
        _houseController.text.isEmpty ||
        _streetController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the delivery address.')),
      );
      return;
    }

    if (AppState.userId == null ||
        AppState.userProfileId == null ||
        AppState.gurbaniId == null ||
        AppState.prizeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission data is missing.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final fullAddress =
        '${_nameController.text}, ${_houseController.text}, ${_streetController.text}, ${_cityController.text}, PIN: ${_pinController.text}';

    try {
      if (AppState.userId != null) {
        await AppState.api.put('/api/users/address/${AppState.userId}', {
          'recipientName': _nameController.text,
          'houseOrFlatNo': _houseController.text,
          'streetOrLocality': _streetController.text,
          'city': _cityController.text,
          'pinCode': _pinController.text,
        });
      }

      final response = await AppState.api
          .post('/api/submissions/create/${AppState.userId}', {
        'userProfileId': AppState.userProfileId,
        'gurbaniId': AppState.gurbaniId,
        'prizeId': AppState.prizeId,
        'address': fullAddress,
        'whatsAppNumber': AppState.whatsAppNumber,
        'whatsAppTestDate': AppState.whatsAppTestDate?.toIso8601String(),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/status');
        return;
      }

      String errorMessage = 'Submission failed.';
      try {
        final body = jsonDecode(response.body);
        errorMessage = body['error'] ?? errorMessage;
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }

      debugPrint('Submission failed: ${response.statusCode} ${response.body}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Address')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Recipient Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _houseController,
              decoration: const InputDecoration(labelText: 'House / Flat No'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Street / Locality'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN Code'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submitAddress,
              child: _submitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Delivery Address'),
            ),
          ],
        ),
      ),
    );
  }
}
