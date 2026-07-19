import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import 'submission_lock_state.dart';

class GurbaniListScreen extends StatefulWidget {
  const GurbaniListScreen({super.key});

  @override
  State<GurbaniListScreen> createState() => _GurbaniListScreenState();
}

class _GurbaniListScreenState extends State<GurbaniListScreen> {
  bool _loading = true;
  List<dynamic> _gurbaniItems = [];
  String? _error;
  bool _hasActiveDelivery = false;
  String? _lockMessage;
  String? _buttonMessage;
  int? _displayedGurbaniId;
  final _whatsAppNumberController = TextEditingController();
  final _testDateController = TextEditingController();
  DateTime? _whatsAppTestDate;

  String? _selectedGurbaniYoutubeUrl() {
    if (_displayedGurbaniId == null) return null;

    for (final item in _gurbaniItems) {
      final gurbaniItem = item as Map<String, dynamic>;
      if (gurbaniItem['id'] == _displayedGurbaniId) {
        final url = gurbaniItem['youtubeUrl'] as String?;
        if (url != null && url.trim().isNotEmpty) {
          return url.trim();
        }
      }
    }

    return null;
  }

  String? _selectedGurbaniTitle() {
    if (_displayedGurbaniId == null) return null;

    for (final item in _gurbaniItems) {
      final gurbaniItem = item as Map<String, dynamic>;
      if (gurbaniItem['id'] == _displayedGurbaniId) {
        return gurbaniItem['title'] as String?;
      }
    }

    return null;
  }

  int _extractWeightage(Map<String, dynamic> item) {
    final rawValue = item['scoreRequirement'] ??
        item['ScoreRequirement'] ??
        item['weightage'] ??
        item['Weightage'];
    if (rawValue is int) return rawValue;
    if (rawValue is String) {
      return int.tryParse(rawValue) ?? 0;
    }
    return 0;
  }

  void _sortGurbaniItemsByWeightage(List<dynamic> items) {
    items.sort((a, b) {
      final first = _extractWeightage(a as Map<String, dynamic>);
      final second = _extractWeightage(b as Map<String, dynamic>);
      return first.compareTo(second);
    });
  }

  bool _hasSelectedGurbani() {
    return _displayedGurbaniId != null;
  }

  bool _canProceed() {
    final phoneDigits =
        _whatsAppNumberController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return _hasSelectedGurbani() &&
        !_hasActiveDelivery &&
        phoneDigits.length == 10 &&
        _whatsAppTestDate != null;
  }

  Future<void> _openYoutubeLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube link.')),
      );
      return;
    }

    final openedInApp = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!openedInApp) {
      final openedInBrowser = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );

      if (!openedInBrowser && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open YouTube link.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _displayedGurbaniId = AppState.gurbaniId;
    _whatsAppNumberController.text = AppState.whatsAppNumber ?? '';
    _whatsAppTestDate = AppState.whatsAppTestDate;
    _updateTestDateController();
    _loadGurbaniItemsAndCheckDispatch();
  }

  @override
  void dispose() {
    _whatsAppNumberController.dispose();
    _testDateController.dispose();
    super.dispose();
  }

  void _updateTestDateController() {
    _testDateController.text = _whatsAppTestDate == null
        ? ''
        : _whatsAppTestDate!.toLocal().toIso8601String().split('T').first;
  }

  Future<void> _pickWhatsAppTestDate() async {
    if (_hasActiveDelivery) {
      _showDispatchedBlockedMessage();
      return;
    }

    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _whatsAppTestDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() {
        _whatsAppTestDate = selected;
        AppState.whatsAppTestDate = selected;
        _updateTestDateController();
      });
    }
  }

  void _showDispatchedBlockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_buttonMessage ??
            "The prize has already been dispatched. Once it is delivered, you can select or change anything you'd like."),
      ),
    );
  }

  void _updateWhatsAppNumber(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      AppState.whatsAppNumber = cleaned.trim();
    });
  }

  Future<void> _loadGurbaniItemsAndCheckDispatch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await AppState.api.get('/api/gurbanilist');
      if (response.statusCode == 200) {
        final items = jsonDecode(response.body) as List<dynamic>;
        _sortGurbaniItemsByWeightage(items);
        setState(() {
          _gurbaniItems = items;
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _error = body['error'] ?? 'Failed to load gurbani items.';
        });
        return;
      }

      if (AppState.userProfileId != null) {
        try {
          final submResp = await AppState.api.get(
              '/api/submissions/by-user-profile/${AppState.userProfileId}');
          if (submResp.statusCode == 200) {
            final submList = jsonDecode(submResp.body) as List<dynamic>;
            if (submList.isNotEmpty) {
              final deliveredGurbaniIds = <int>{};

              for (final item in submList) {
                final submission = item as Map<String, dynamic>;
                final gurbaniId = submission['gurbaniId'] as int?;
                final dispatch =
                    submission['dispatch'] as Map<String, dynamic>?;
                final deliveryStatus = dispatch?['deliveryStatus'] as String?;

                if (gurbaniId != null && deliveryStatus == 'Delivered') {
                  deliveredGurbaniIds.add(gurbaniId);
                }
              }

              final filteredGurbaniItems = _gurbaniItems.where((gurbaniItem) {
                final id = gurbaniItem['id'] as int?;
                return id == null || !deliveredGurbaniIds.contains(id);
              }).toList();
              _sortGurbaniItemsByWeightage(filteredGurbaniItems);

              final latestSubmission = submList[0] as Map<String, dynamic>;
              final latestGurbaniId = latestSubmission['gurbaniId'] as int?;
              final hasLatestInFiltered = filteredGurbaniItems
                  .any((gurbaniItem) => gurbaniItem['id'] == latestGurbaniId);
              final latestDeliveryStatus = (latestSubmission['dispatch']
                  as Map<String, dynamic>?)?['deliveryStatus'] as String?;
              final latestIsDelivered = latestDeliveryStatus == 'Delivered';
              final lockState = deriveSubmissionLockState(latestSubmission);

              final savedWhatsAppNumber =
                  latestSubmission['whatsAppNumber'] as String?;
              final savedWhatsAppTestDate =
                  latestSubmission['whatsAppTestDate'];
              DateTime? parsedWhatsAppTestDate;
              if (savedWhatsAppTestDate != null) {
                parsedWhatsAppTestDate =
                    DateTime.tryParse(savedWhatsAppTestDate.toString());
              }

              setState(() {
                _gurbaniItems = filteredGurbaniItems;
                _hasActiveDelivery = lockState.isBlocked;
                _lockMessage = lockState.message;
                _buttonMessage = lockState.buttonMessage;

                if (latestIsDelivered) {
                  _displayedGurbaniId = null;
                  AppState.gurbaniId = null;
                  AppState.prizeId = null;
                  AppState.whatsAppNumber = null;
                  AppState.whatsAppTestDate = null;
                  _whatsAppNumberController.text = '';
                  _whatsAppTestDate = null;
                } else {
                  _displayedGurbaniId =
                      hasLatestInFiltered ? latestGurbaniId : null;
                  AppState.gurbaniId =
                      hasLatestInFiltered ? latestGurbaniId : null;
                  if (savedWhatsAppNumber != null &&
                      savedWhatsAppNumber.trim().isNotEmpty) {
                    AppState.whatsAppNumber = savedWhatsAppNumber.trim();
                    _whatsAppNumberController.text = savedWhatsAppNumber.trim();
                  }
                  AppState.whatsAppTestDate = parsedWhatsAppTestDate;
                  _whatsAppTestDate = parsedWhatsAppTestDate;
                }
              });
            }
          }
        } catch (e) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: e,
            stack: StackTrace.current,
          ));
        }
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to load gurbani list: $error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Gurbani, Biography or History / ਗੁਰਬਾਣੀ, ਜੀਵਨੀ ਜਾਂ ਇਤਿਹਾਸ ਚੁਣੋ',
          style: TextStyle(fontSize: 16),
        ),
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
                ? Center(child: Text(_error!))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_hasActiveDelivery)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _lockMessage ??
                                'A previous approved submission is still in delivery. Cannot change.',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey(_displayedGurbaniId),
                        decoration:
                            const InputDecoration(labelText: 'Select / ਚੁਣੋ'),
                        isExpanded: true,
                        menuMaxHeight: 240,
                        initialValue: _displayedGurbaniId,
                        items: _gurbaniItems
                            .map((gurbaniItem) => DropdownMenuItem<int>(
                                  value: gurbaniItem['id'] as int,
                                  child: Text(
                                    (() {
                                      final title =
                                          gurbaniItem['title'] as String;
                                      final youtubeUrl =
                                          gurbaniItem['youtubeUrl'] as String?;
                                      final hasVideo = youtubeUrl != null &&
                                          youtubeUrl.trim().isNotEmpty;
                                      return hasVideo
                                          ? '$title (Video)'
                                          : title;
                                    })(),
                                  ),
                                ))
                            .toList(),
                        onChanged: _hasActiveDelivery
                            ? null
                            : (value) {
                                setState(() {
                                  _displayedGurbaniId = value;
                                  AppState.gurbaniId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      if (_hasSelectedGurbani())
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _whatsAppNumberController,
                              enabled: !_hasActiveDelivery,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              maxLength: 10,
                              decoration: const InputDecoration(
                                labelText: 'WhatsApp Number',
                                hintText: 'Enter WhatsApp number',
                              ),
                              onChanged: _updateWhatsAppNumber,
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ WhatsApp ਨੰਬਰ ਦਰਜ ਕਰੋ। ਤੁਹਾਡਾ ਟੈਸਟ ਲੈਣ ਲਈ ਅਸੀਂ ਇਸ ਨੰਬਰ 'ਤੇ ਵੀਡੀਓ ਕਾਲ ਰਾਹੀਂ ਤੁਹਾਡੇ ਨਾਲ ਸੰਪਰਕ ਕਰਾਂਗੇ।\nPlease provide your WhatsApp number. We will contact you via video call on this number to conduct your test.",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _testDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Test date',
                                hintText: 'Select test date',
                                enabled: !_hasActiveDelivery,
                              ),
                              onTap: _hasActiveDelivery
                                  ? _showDispatchedBlockedMessage
                                  : _pickWhatsAppTestDate,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                "ਕਿਰਪਾ ਕਰਕੇ ਵਟਸਐਪ ਕਾਲ 'ਤੇ ਟੈਸਟ ਦੇਣ ਲਈ ਆਪਣੀ ਸੁਵਿਧਾ ਅਨੁਸਾਰ ਮਿਤੀ ਚੁਣੋ।\nPlease select a date at your convenience to take the test via a WhatsApp call.",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      ElevatedButton(
                        onPressed: _hasActiveDelivery
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_buttonMessage ??
                                        "The prize has already been dispatched. Once it is delivered, you can select or change anything you'd like."),
                                  ),
                                );
                              }
                            : _canProceed()
                                ? () =>
                                    Navigator.pushNamed(context, '/prize-list')
                                : null,
                        child: const Text('Submit'),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          if (!_hasSelectedGurbani()) {
                            return const SizedBox.shrink();
                          }

                          final youtubeUrl = _selectedGurbaniYoutubeUrl();
                          if (youtubeUrl == null) {
                            return const Text(
                              'No YouTube link available for selected gurbani item.',
                              style: TextStyle(color: Colors.grey),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Watch this ${_selectedGurbaniTitle() ?? 'selected gurbani item'} on YouTube:',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () => _openYoutubeLink(youtubeUrl),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  alignment: Alignment.centerLeft,
                                ),
                                child: const Text(
                                  'Click here',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
      ),
    );
  }
}
