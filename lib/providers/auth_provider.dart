import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheera/services/api_services.dart';

//enum AuthStatus { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthProvider with ChangeNotifier {
  // AuthStatus _authStatus = AuthStatus.Uninitialized;
  // AuthStatus get authStatus => _authStatus;
  final ApiServices _apiServices= ApiServices();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user != null && _user!['role'] == 'admin';

  AuthProvider() {
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    final token = await _storage.read(key: 'auth_token');
    final userString = await _storage.read(key: 'user_data');
    if (token != null && userString != null) {
      _token = token;
      _user = jsonDecode(userString);
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiServices.login(email, password);
      _token = response['access_token'];
      _user = response['user'];
      _isAuthenticated = true;

      // Simpan token dan data user ke secure storage
      await _storage.write(key: 'auth_token', value: _token);
      await _storage.write(key: 'user_data', value: jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow; 
    }
  }

  Future<bool> register({
    required String namaLengkap,
    required String email,
    required String nomorTelepon,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Panggil service untuk register
      final response = await _apiServices.register(
        namaLengkap: namaLengkap,
        email: email,
        nomorTelepon: nomorTelepon,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      // Setelah berhasil register, langsung loginkan user
      _token = response['access_token'];
      _user = response['user'];
      _isAuthenticated = true;

      await _storage.write(key: 'auth_token', value: _token);
      await _storage.write(key: 'user_data', value: jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      await _apiServices.logout(_token!);
    }
    _token = null;
    _user = null;
    _isAuthenticated = false;

    // Hapus dari storage
    await _storage.deleteAll();
    notifyListeners();
  }

  
}
