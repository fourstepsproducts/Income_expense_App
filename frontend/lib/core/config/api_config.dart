import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _customUrlKey = 'custom_api_base_url';

  static String _currentBaseUrl = '';

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customUrlKey);
    if (custom != null && custom.isNotEmpty) {
      _currentBaseUrl = custom;
      return;
    }

    if (_envApiUrl.isNotEmpty) {
      _currentBaseUrl = _envApiUrl;
    } else {
      // Default dev fallback based on platform
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _currentBaseUrl = 'http://10.0.2.2:5000/api';
      } else {
        _currentBaseUrl = 'http://localhost:5000/api';
      }
    }
  }

  static String get baseUrl => _currentBaseUrl.isNotEmpty
      ? _currentBaseUrl
      : (_envApiUrl.isNotEmpty ? _envApiUrl : 'http://localhost:5000/api');

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    _currentBaseUrl = url.trim();
    await prefs.setString(_customUrlKey, _currentBaseUrl);
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customUrlKey);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _currentBaseUrl = 'http://10.0.2.2:5000/api';
    } else {
      _currentBaseUrl = 'http://localhost:5000/api';
    }
  }
}
