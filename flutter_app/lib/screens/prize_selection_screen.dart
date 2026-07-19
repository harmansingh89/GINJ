import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import 'submission_lock_state.dart';

class PrizeSelectionScreen extends StatefulWidget {
  const PrizeSelectionScreen({super.key});

  @override
  State<PrizeSelectionScreen> createState() => _PrizeSelectionScreenState();
}

class _PrizeSelectionScreenState extends State<PrizeSelectionScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _prizes = [];
  int? _selectedPrizeId;
  String? _selectedPrizeName;
  bool _hasActiveDelivery = false;
  String? _lockMessage;
  String? _buttonMessage;

  bool _isDeliveredSubmission(Map<String, dynamic> submission) {
    final dispatch = submission['dispatch'] as Map<String, dynamic>?;
    final deliveryStatus = dispatch?['deliveryStatus'] as String?;
    return deliveryStatus == 'Delivered';
  }

  void _applyLockState(Map<String, dynamic>? submission) {
    final lockState = deriveSubmissionLockState(submission);
    setState(() {
      _hasActiveDelivery = lockState.isBlocked;
      _lockMessage = lockState.message;
      _buttonMessage = lockState.buttonMessage;
    });
  }

  String? _normalizePrizeImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }

    if (imageUrl.startsWith('/')) {
      return '${AppState.apiBaseUrl}$imageUrl';
    }

    return imageUrl;
  }

  Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final ct = resp.headers['content-type'] ?? '';
        if (ct.startsWith('image/')) {
          return resp.bodyBytes;
        }
      }
    } catch (e) {
      // ignore network errors here and let the UI fallback
      if (kDebugMode) print('Image fetch failed: $e');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadPrizesAndCheckDispatch();
  }

  Future<void> _loadPrizesAndCheckDispatch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load submissions first to restore prize only for the current Gurbani cycle.
      if (AppState.userProfileId != null) {
        try {
          final submResp = await AppState.api.get(
              '/api/submissions/by-user-profile/${AppState.userProfileId}');
          if (submResp.statusCode == 200) {
            final submList = jsonDecode(submResp.body) as List<dynamic>;
            if (submList.isNotEmpty) {
              var currentGurbaniId = AppState.gurbaniId;
              Map<String, dynamic>? matchingSubmission;

              if (currentGurbaniId == null) {
                final latestSubmission = submList.first as Map<String, dynamic>;
                final latestGurbaniId = latestSubmission['gurbaniId'] as int?;
                final latestDeliveryStatus = (latestSubmission['dispatch']
                    as Map<String, dynamic>?)?['deliveryStatus'] as String?;
                final latestIsDelivered = latestDeliveryStatus == 'Delivered';
                if (latestGurbaniId != null && !latestIsDelivered) {
                  currentGurbaniId = latestGurbaniId;
                  AppState.gurbaniId = latestGurbaniId;
                }
              }

              if (currentGurbaniId != null) {
                for (final item in submList) {
                  final submission = item as Map<String, dynamic>;
                  final submissionGurbaniId = submission['gurbaniId'] as int?;
                  if (submissionGurbaniId == currentGurbaniId) {
                    matchingSubmission = submission;
                    break;
                  }
                }
              }

              if (matchingSubmission != null) {
                final isDelivered = _isDeliveredSubmission(matchingSubmission);
                final selectedPrizeId =
                    isDelivered ? null : matchingSubmission['prizeId'] as int?;
                final selectedPrizeName = isDelivered
                    ? null
                    : matchingSubmission['prizeName'] as String? ??
                        'Selected Prize';

                setState(() {
                  _selectedPrizeId = selectedPrizeId;
                  _selectedPrizeName = selectedPrizeName;
                  AppState.prizeId = selectedPrizeId;
                });
                _applyLockState(matchingSubmission);
              } else if (AppState.prizeId != null) {
                setState(() {
                  _selectedPrizeId = AppState.prizeId;
                  _selectedPrizeName = null;
                });
                _applyLockState(null);
              }
            }
          }
        } catch (e) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: e,
            stack: StackTrace.current,
          ));
        }
      }

      // Now validate we have Gurbani ID (either from AppState or from submission)
      if (AppState.userProfileId == null ||
          (AppState.gurbaniId == null && _selectedPrizeId == null)) {
        setState(() {
          _error = 'User profile or Gurbani selection is missing.';
          _loading = false;
        });
        return;
      }

      final gurbaniId = AppState.gurbaniId;
      if (gurbaniId == null) {
        setState(() {
          _error = 'Gurbani selection is missing.';
          _loading = false;
        });
        return;
      }

      final response = await AppState.api.get(
        '/api/prizelist/eligible/${AppState.userProfileId}/$gurbaniId',
      );
      if (response.statusCode == 200) {
        setState(() {
          _prizes = jsonDecode(response.body) as List<dynamic>;
          // Update the prize name if we have a selected prize
          if (_selectedPrizeId != null) {
            for (var prize in _prizes) {
              if (prize['id'] as int == _selectedPrizeId) {
                _selectedPrizeName = prize['name'] as String;
                break;
              }
            }
          }
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _error = body['error'] ?? 'Failed to load prizes.';
        });
      }
    } catch (error) {
      setState(() {
        _error = 'Failed to load prizes: $error';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _submitPrize() {
    if (_hasActiveDelivery) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_buttonMessage ??
              "The prize has already been dispatched. Once it is delivered, you can select or change anything you'd like."),
        ),
      );
      return;
    }

    if (_selectedPrizeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prize.')),
      );
      return;
    }

    if (AppState.userId == null ||
        AppState.userProfileId == null ||
        AppState.gurbaniId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User or profile data is missing.')),
      );
      return;
    }

    AppState.prizeId = _selectedPrizeId;
    Navigator.pushNamed(context, '/delivery-address');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Prize / ਇਨਾਮ ਚੁਣੋ'),
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
                    children: [
                      if (_hasActiveDelivery)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Container(
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
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _prizes.length,
                          itemBuilder: (context, index) {
                            final prize = _prizes[index];
                            final prizeId = prize['id'] as int;
                            final prizeName = prize['name'] as String;
                            final rawPrizeImage = prize['imageUrl'] as String?;
                            final prizeImage =
                                _normalizePrizeImageUrl(rawPrizeImage);
                            final isSelected = _selectedPrizeId == prizeId;
                            return GestureDetector(
                              onTap: _hasActiveDelivery
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedPrizeId = prizeId;
                                        _selectedPrizeName = prizeName;
                                      });
                                    },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected ? Colors.blue : Colors.grey,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (prizeImage != null &&
                                        prizeImage.isNotEmpty)
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: FutureBuilder<Uint8List?>(
                                              future:
                                                  _fetchImageBytes(prizeImage),
                                              builder: (context, snap) {
                                                if (snap.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                }
                                                if (snap.hasData &&
                                                    snap.data != null) {
                                                  return Image.memory(
                                                    snap.data!,
                                                    fit: BoxFit.cover,
                                                  );
                                                }

                                                return Image.network(
                                                  prizeImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (c, e, s) =>
                                                      const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 32,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.card_giftcard,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      prizeName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    if (isSelected)
                                      const Text(
                                        'Selected',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedPrizeName != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            'Selected prize: $_selectedPrizeName',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _selectedPrizeId == null
                            ? null
                            : () {
                                if (_hasActiveDelivery) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_buttonMessage ??
                                          "The prize has already been dispatched. Once it is delivered, you can select or change anything you'd like."),
                                    ),
                                  );
                                  return;
                                }
                                _submitPrize();
                              },
                        child: const Text('Continue to Address'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
