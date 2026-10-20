import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String currency = 'INR',
  }) async {
    final response = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'currency': currency,
    });

    final data = response['data'];
    await _client.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = UserModel.fromJson(data['user']);
    await _saveUserToPrefs(user);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    final data = response['data'];
    await _client.saveTokens(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
    );

    final user = UserModel.fromJson(data['user']);
    await _saveUserToPrefs(user);
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(AppConstants.userKey);
    if (jsonStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }

    final token = await _client.getAccessToken();
    if (token == null) return null;

    try {
      final response = await _client.get('/auth/me');
      final user = UserModel.fromJson(response['data']['user']);
      await _saveUserToPrefs(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateProfile({String? name, String? currency}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (currency != null) body['currency'] = currency;
    final response = await _client.put('/auth/me', body: body);

    final user = UserModel.fromJson(response['data']['user']);
    await _saveUserToPrefs(user);
    return user;
  }

  Future<void> logout() async {
    await _client.clearAuth();
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    await prefs.setString(AppConstants.currencyKey, user.currency);
  }
}
