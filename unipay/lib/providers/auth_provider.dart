// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;
  Map<String, dynamic>? _userData;

  Map<String, dynamic>? get userData => _userData;

  AuthNotifier(this._ref) : super(const AsyncValue.data(false)) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      await _fetchUser(token);
    } else {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final client = _ref.read(apiClientProvider).client;
      final response = await client.post('/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['access_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      await _fetchUser(token);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _fetchUser(String token) async {
    try {
      final client = _ref.read(apiClientProvider).client;
      final response = await client.get('/user');
      _userData = response.data;
      final prefs = await SharedPreferences.getInstance();
      
      // Cache basic info
      if (_userData != null) {
         await prefs.setString('user_name', _userData!['name']);
         await prefs.setString('user_email', _userData!['email']);
      }
      
      state = const AsyncValue.data(true);
    } catch (e) {
      // If fetch user fails but token exists, try to load from cache
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('user_name');
      final cachedEmail = prefs.getString('user_email');
      
      if (cachedName != null) {
        _userData = {'name': cachedName, 'email': cachedEmail};
         state = const AsyncValue.data(true);
      } else {
        // Token invalid or expired
        await logout();
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    _userData = null;
    state = const AsyncValue.data(false);
  }
}

