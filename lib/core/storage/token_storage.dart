import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../config/app_config.dart';

class TokenStorage {
  const TokenStorage();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.accessTokenStorageKey, token);
  }

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.accessTokenStorageKey);
  }

  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.accessTokenStorageKey);
  }

  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConfig.userProfileStorageKey,
      jsonEncode(profile),
    );
  }

  Future<Map<String, dynamic>?> readUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(AppConfig.userProfileStorageKey);
    if (profileJson == null) return null;
    try {
      return jsonDecode(profileJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.userProfileStorageKey);
  }
}
