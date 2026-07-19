import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_state.dart';

class SubmissionHistoryScreen extends StatefulWidget {
  const SubmissionHistoryScreen({super.key});

  @override
  State<SubmissionHistoryScreen> createState() =>
      _SubmissionHistoryScreenState();
}

class _SubmissionHistoryScreenState extends State<SubmissionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _history = [];
  String _userProfileName = 'Unknown Profile';
  String _parentPhone = 'Unknown Phone';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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
          _error = 'Unable to load submission history.';
        });
        return;
      }

      final list = jsonDecode(response.body) as List<dynamic>;

      if (AppState.userId != null) {
        final parentResponse =
            await AppState.api.get('/api/users/${AppState.userId}');
        if (parentResponse.statusCode == 200) {
          final parentBody = jsonDecode(parentResponse.body);
          final phone = parentBody['phone'] as String?;
          if (phone != null && phone.trim().isNotEmpty) {
            _parentPhone = phone;
          }
        }

        final childrenResponse = await AppState.api
            .get('/api/userprofiles/by-user/${AppState.userId}');
        if (childrenResponse.statusCode == 200) {
          final children = jsonDecode(childrenResponse.body) as List<dynamic>;
          for (final item in children) {
            final child = item as Map<String, dynamic>;
            if (child['id'] == AppState.userProfileId) {
              final name = child['name'] as String?;
              if (name != null && name.trim().isNotEmpty) {
                _userProfileName = name;
              }
              break;
            }
          }
        }
      }

      final gurbaniResponse = await AppState.api.get('/api/gurbanilist');
      final gurbaniNameById = <int, String>{};
      if (gurbaniResponse.statusCode == 200) {
        final gurbaniItems = jsonDecode(gurbaniResponse.body) as List<dynamic>;
        for (final item in gurbaniItems) {
          final gurbaniItem = item as Map<String, dynamic>;
          final id = gurbaniItem['id'] as int?;
          final title = gurbaniItem['title'] as String?;
          if (id != null && title != null && title.trim().isNotEmpty) {
            gurbaniNameById[id] = title;
          }
        }
      }

      final enrichedList = list.map((item) {
        final submission =
            Map<String, dynamic>.from(item as Map<String, dynamic>);
        final gurbaniId = submission['gurbaniId'] as int?;
        submission['gurbaniTitle'] = gurbaniId != null
            ? (gurbaniNameById[gurbaniId] ?? 'Gurbani #$gurbaniId')
            : '-';
        return submission;
      }).toList();

      setState(() {
        _history = enrichedList;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Unable to load submission history.';
      });
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'N/A';

    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.year}-$month-$day $hour:$minute';
  }

  String _dispatchStatus(Map<String, dynamic>? dispatch) {
    return (dispatch?['deliveryStatus'] as String?) ?? 'None';
  }

  String _docket(Map<String, dynamic>? dispatch) {
    final val = dispatch?['docketNumber'] as String?;
    if (val == null || val.trim().isEmpty) return 'None';
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission History'),
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
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_userProfileName ($_parentPhone)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        const Text('No history available.')
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('No.')),
                                  DataColumn(label: Text('Gurbani')),
                                  DataColumn(label: Text('Prize')),
                                  DataColumn(label: Text('WhatsApp')),
                                  DataColumn(label: Text('Dispatch')),
                                  DataColumn(label: Text('Docket')),
                                  DataColumn(label: Text('Created At')),
                                ],
                                rows: _history.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final submission =
                                      entry.value as Map<String, dynamic>;
                                  final dispatch = submission['dispatch']
                                      as Map<String, dynamic>?;

                                  return DataRow(
                                    cells: [
                                      DataCell(Text('${index + 1}')),
                                      DataCell(Text(
                                          '${submission['gurbaniTitle'] ?? '-'}')),
                                      DataCell(Text(
                                          '${submission['prizeName'] ?? submission['prizeId'] ?? '-'}')),
                                      DataCell(Text(
                                          '${submission['whatsAppTestStatus'] ?? 'Pending'}')),
                                      DataCell(Text(_dispatchStatus(dispatch))),
                                      DataCell(Text(_docket(dispatch))),
                                      DataCell(Text(_formatDate(
                                          submission['createdAt'] as String?))),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Refresh History'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
