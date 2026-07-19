import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  final Future<void> Function(String token)? onTokenUpdated;
  String? token;
  late final http.Client _client;

  ApiService(this.baseUrl, {this.onTokenUpdated}) {
    _client = http.Client();
  }

  Map<String, String> get headers {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    try {
      final url = '$baseUrl$path';
      if (kDebugMode) {
        print('POST $url with body: ${jsonEncode(body)}');
      }

      final response = await _client
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('POST Response: ${response.statusCode}');
      }

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        if (token != null && !path.contains('refresh-token')) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            return _client.post(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode(body),
            );
          }
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('POST Error: $e');
      }
      rethrow;
    }
  }

  Future<http.Response> get(String path) async {
    try {
      final url = '$baseUrl$path';
      if (kDebugMode) {
        print('GET $url');
      }

      final response = await _client
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('GET Response: ${response.statusCode}');
      }

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        if (token != null && !path.contains('refresh-token')) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            return _client.get(
              Uri.parse(url),
              headers: headers,
            );
          }
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('GET Error: $e');
      }
      rethrow;
    }
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    try {
      final url = '$baseUrl$path';
      if (kDebugMode) {
        print('PUT $url with body: ${jsonEncode(body)}');
      }

      final response = await _client
          .put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('PUT Response: ${response.statusCode}');
      }

      if (response.statusCode == 401) {
        if (token != null && !path.contains('refresh-token')) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            return _client.put(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode(body),
            );
          }
        }
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('PUT Error: $e');
      }
      rethrow;
    }
  }

  Future<bool> _refreshToken() async {
    if (token == null) return false;

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final newToken = body['token'] as String?;
        if (newToken != null) {
          token = newToken;
          await onTokenUpdated?.call(newToken);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
