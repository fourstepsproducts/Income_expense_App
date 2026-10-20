import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.refreshTokenKey);
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _sendWithRetry((token) async {
      final uri = _buildUri(endpoint, queryParams);
      final response = await _client.get(uri, headers: _buildHeaders(token));
      return _processResponse(response);
    });
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    return _sendWithRetry((token) async {
      final uri = _buildUri(endpoint);
      final response = await _client.post(
        uri,
        headers: _buildHeaders(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    return _sendWithRetry((token) async {
      final uri = _buildUri(endpoint);
      final response = await _client.put(
        uri,
        headers: _buildHeaders(token),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    });
  }

  Future<dynamic> delete(String endpoint) async {
    return _sendWithRetry((token) async {
      final uri = _buildUri(endpoint);
      final response = await _client.delete(uri, headers: _buildHeaders(token));
      return _processResponse(response);
    });
  }

  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final base = ApiConfig.baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final fullUrl = '$base$path';

    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          cleanParams[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: cleanParams);
    }

    return Uri.parse(fullUrl);
  }

  Future<dynamic> _sendWithRetry(Future<dynamic> Function(String? token) requestFn) async {
    try {
      final token = await getAccessToken();
      return await requestFn(token);
    } on UnauthorizedException {
      // Attempt token refresh
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final newToken = await getAccessToken();
        return await requestFn(newToken);
      } else {
        await clearAuth();
        rethrow;
      }
    } on SocketException {
      throw NetworkException();
    } on http.ClientException {
      throw NetworkException();
    }
  }

  Future<bool> _attemptTokenRefresh() async {
    try {
      final rToken = await getRefreshToken();
      if (rToken == null || rToken.isEmpty) return false;

      final uri = _buildUri('/auth/refresh');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['data'] != null) {
          await saveTokens(
            accessToken: data['data']['accessToken'],
            refreshToken: data['data']['refreshToken'],
          );
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      json = null;
    }

    final message = json is Map && json['message'] != null
        ? json['message']
        : 'Request failed with status: $statusCode';

    if (statusCode >= 200 && statusCode < 300) {
      return json;
    } else if (statusCode == 401) {
      throw UnauthorizedException(message);
    } else if (statusCode == 400 || statusCode == 422) {
      throw ValidationException(message, details: json is Map ? json['errors'] : null);
    } else if (statusCode >= 500) {
      throw ServerException(message);
    } else {
      throw AppException(message, statusCode: statusCode);
    }
  }
}
