import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ginj/services/api_service.dart';

class AppState {
  static const String _prefKeyToken = 'auth_token';
  static const String _prefKeyUserId = 'user_id';
  static const String _prefKeyUserProfileId = 'user_profile_id';

  static bool _initialized = false;

  // Choose an appropriate backend URL depending on platform.
  // Override for a real device by using --dart-define=API_BASE_URL=http://<host-ip>:5000
  static String get _baseUrl {
    const envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (envApiBaseUrl.isNotEmpty) {
      return envApiBaseUrl;
    }

    if (kIsWeb) return 'https://localhost:5001';
    // For Android emulator, use the host machine address.
    // Use HTTP on the emulator to avoid self-signed certificate validation failures.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    // Fallback to localhost for other platforms (desktop, iOS simulator, etc.)
    return 'https://localhost:5001';
  }

  static final ApiService api = ApiService(
    _baseUrl,
    onTokenUpdated: _onTokenUpdated,
  );

  static String get apiBaseUrl => _baseUrl;
  static int? userId;
  static int? userProfileId;
  static int? gurbaniId;
  static int? prizeId;
  static String? whatsAppNumber;
  static DateTime? whatsAppTestDate;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefKeyToken);
    if (token != null && token.isNotEmpty) {
      api.token = token;
    }

    userId = prefs.getInt(_prefKeyUserId);
    userProfileId = prefs.getInt(_prefKeyUserProfileId);

    if (kDebugMode) {
      print(
          'AppState.initialize token=${api.token != null} userId=$userId userProfileId=$userProfileId');
    }

    if (api.token != null && userId != null && userProfileId == null) {
      try {
        final response = await api.get('/api/userprofiles/by-user/$userId');
        if (response.statusCode == 200) {
          final list = response.body.isNotEmpty
              ? jsonDecode(response.body) as List<dynamic>
              : <dynamic>[];
          if (list.isNotEmpty) {
            userProfileId = list[0]['id'] as int?;
            if (userProfileId != null) {
              await prefs.setInt(_prefKeyUserProfileId, userProfileId!);
            }
          }
        }
      } catch (_) {
        // Ignore network failures during startup restore.
      }
    }
  }

  static Future<void> persistSession(
      {String? token, int? userId, int? userProfileId}) async {
    final prefs = await SharedPreferences.getInstance();

    if (token != null) {
      api.token = token;
      await prefs.setString(_prefKeyToken, token);
    }

    if (userId != null) {
      AppState.userId = userId;
      await prefs.setInt(_prefKeyUserId, userId);
    }

    if (userProfileId != null) {
      AppState.userProfileId = userProfileId;
      await prefs.setInt(_prefKeyUserProfileId, userProfileId);
    }
  }

  static Future<void> _onTokenUpdated(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyToken, token);
  }

  static Future<void> clearSession() async {
    api.token = null;
    userId = null;
    userProfileId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyToken);
    await prefs.remove(_prefKeyUserId);
    await prefs.remove(_prefKeyUserProfileId);
  }
}
