import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:story_project/domain/models/user.dart';

class AuthPreferences {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  Future<bool> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<bool> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    return prefs.setBool(_isLoggedInKey, false);
  }
} 