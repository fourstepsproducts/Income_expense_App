import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // VPS Production/Central API Base URL
  static const String defaultBaseUrl = 'http://62.72.29.36:5010/api';

  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _customUrlKey = 'custom_api_base_url';

  static String _currentBaseUrl = defaultBaseUrl;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customUrlKey);

    // If an old local development URL was previously saved (e.g. localhost, 127.0.0.1, 10.0.2.2, port 5000),
    // automatically purge it so it cannot silently override the central VPS backend.
    if (custom != null && custom.isNotEmpty) {
      final isLocalUrl = custom.contains('localhost') ||
          custom.contains('127.0.0.1') ||
          custom.contains('10.0.2.2') ||
          custom.contains(':5000');

      if (isLocalUrl) {
        await prefs.remove(_customUrlKey);
        _currentBaseUrl = _envApiUrl.isNotEmpty ? _envApiUrl : defaultBaseUrl;
        return;
      }

      _currentBaseUrl = custom.trim();
      return;
    }

    if (_envApiUrl.isNotEmpty) {
      _currentBaseUrl = _envApiUrl;
    } else {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  static String get baseUrl => _currentBaseUrl.isNotEmpty
      ? _currentBaseUrl
      : (_envApiUrl.isNotEmpty ? _envApiUrl : defaultBaseUrl);

  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == defaultBaseUrl) {
      await resetBaseUrl();
    } else {
      _currentBaseUrl = trimmed;
      await prefs.setString(_customUrlKey, _currentBaseUrl);
    }
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customUrlKey);
    _currentBaseUrl = _envApiUrl.isNotEmpty ? _envApiUrl : defaultBaseUrl;
  }
}
