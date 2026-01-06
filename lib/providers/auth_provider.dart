import 'package:flutter/foundation.dart';

import '../core/storage/token_storage.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    TokenStorage? tokenStorage,
  })  : _authService = authService ?? AuthService(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final AuthService _authService;
  final TokenStorage _tokenStorage;

  UserModel? _currentUser;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        _currentUser = await _authService.fetchProfile(forceRefresh: true);
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setLoadingState(true);
    try {
      await _authService.login(username: username, password: password);
      _currentUser = await _authService.fetchProfile(forceRefresh: true);
      _setError(null);
      return true;
    } catch (error) {
      _setError(error.toString());
      await _authService.logout();
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    _setLoadingState(true);
    try {
      await _authService.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      final loginSuccess = await login(username: email, password: password);
      if (!loginSuccess) {
        throw Exception('Registration succeeded but auto-login failed.');
      }
      return true;
    } catch (error) {
      _setError(error.toString());
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    _setLoadingState(true);
    try {
      _currentUser = await _authService.updateProfile(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
      );
      _setError(null);
      return true;
    } catch (error) {
      _setError(error.toString());
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoadingState(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}

