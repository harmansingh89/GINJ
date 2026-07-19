import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class SubmissionStatusScreen extends StatefulWidget {
  const SubmissionStatusScreen({super.key});

  @override
  State<SubmissionStatusScreen> createState() => _SubmissionStatusScreenState();
}

class _SubmissionStatusScreenState extends State<SubmissionStatusScreen> {
  bool _loading = true;
  String? _error;
  String _whatsAppTestStatus = 'Pending';
  String _reviewStatus = 'Pending';
  String _dispatchDocket = 'N/A';
  String _deliveryStatus = 'N/A';

  @override
  void initState() {
    super.initState();
    _loadLatestSubmissionStatus();
  }

  Future<void> _loadLatestSubmissionStatus() async {
    if (AppState.userProfileId == null) {
      setState(() {
        _loading = false;
        _error = 'User profile not found.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await AppState.api
          .get('/api/submissions/by-user-profile/${AppState.userProfileId}');

      if (response.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'Unable to load submission status.';
        });
        return;
      }

      final List<dynamic> list = jsonDecode(response.body) as List<dynamic>;

      if (list.isEmpty) {
        setState(() {
          _loading = false;
          _whatsAppTestStatus = 'N/A';
          _reviewStatus = 'N/A';
          _dispatchDocket = 'N/A';
          _deliveryStatus = 'N/A';
        });
        return;
      }

      final Map<String, dynamic> latest = list.first as Map<String, dynamic>;
      final dispatch = latest['dispatch'] as Map<String, dynamic>?;
      final deliveryStatus = (dispatch?['deliveryStatus'] as String?) ?? 'N/A';
      final whatsAppStatus =
          (latest['whatsAppTestStatus'] as String?) ?? 'Pending';
      final reviewStatus = deliveryStatus == 'Delivered'
          ? 'Your prize is delivered successfully.'
          : deliveryStatus == 'Dispatched'
              ? 'Your prize is in transit.'
              : deliveryStatus == 'Returned'
                  ? 'Your prize was returned. We are looking into the issue and are working to resolve it. Please wait for further updates.'
                  : whatsAppStatus == 'Passed'
                      ? 'Your prize is being prepared for dispatch.'
                      : (latest['status'] as String?) ?? 'Pending';

      setState(() {
        _loading = false;
        _whatsAppTestStatus = whatsAppStatus;
        _reviewStatus = reviewStatus;
        _dispatchDocket = (dispatch?['docketNumber'] as String?) ?? 'N/A';
        _deliveryStatus = deliveryStatus;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Unable to load submission status.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.red[50],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Unable to load status',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red)),
                              const SizedBox(height: 8),
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _loadLatestSubmissionStatus,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Submission Overview',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text(
                                    'Track where your application is in the review and delivery process.',
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _statusTile(
                          icon: Icons.message,
                          title: 'WhatsApp Test',
                          subtitle: _whatsAppTestStatus,
                        ),
                        const SizedBox(height: 12),
                        _statusTile(
                          icon: Icons.rate_review,
                          title: 'Review Status',
                          subtitle: _reviewStatus,
                        ),
                        const SizedBox(height: 12),
                        _statusTile(
                          icon: Icons.local_shipping,
                          title: 'Dispatch Docket',
                          subtitle: _dispatchDocket,
                        ),
                        const SizedBox(height: 12),
                        _statusTile(
                          icon: Icons.check_circle,
                          title: 'Delivery Status',
                          subtitle: _deliveryStatus,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadLatestSubmissionStatus,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.0),
                            child: Text('Refresh Status'),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
