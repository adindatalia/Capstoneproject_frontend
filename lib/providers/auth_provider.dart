
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../api/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      await fetchUserProfile();
    }
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    if (_token == null) return;
    try {
      final userData = await _apiService.getProfile(_token!);
      _user = User.fromJson(userData);
    } catch (e) {
      await logout();
    }
    notifyListeners();
  }

  Future<void> login(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    _user = User.fromJson(userData);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
