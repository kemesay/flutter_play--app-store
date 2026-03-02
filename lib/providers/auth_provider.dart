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

  /// Deletes the current user's account permanently.
  /// This complies with App Store Guideline 5.1.1(v) - Data Collection and Storage.
  /// Returns true if deletion was successful, false otherwise.
  Future<bool> deleteAccount() async {
    _setLoadingState(true);
    try {
      await _authService.deleteAccount();
      _currentUser = null;
      _setError(null);
      return true;
    } catch (error) {
      _setError(error.toString());
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  /// Changes the current user's password.
  /// Returns true if password change was successful, false otherwise.
  /// Automatically logs out the user after successful password change.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoadingState(true);
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setError(null);
      // Log out user after successful password change
      await logout();
      return true;
    } catch (error) {
      _setError(error.toString());
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  /// Requests a password reset by sending a reset token to the user's email.
  /// Returns true if the request was successful, false otherwise.
  Future<bool> requestPasswordReset({required String email}) async {
    _setLoadingState(true);
    try {
      await _authService.requestPasswordReset(email: email);
      _setError(null);
      return true;
    } catch (error) {
      _setError(error.toString());
      return false;
    } finally {
      _setLoadingState(false);
    }
  }

  /// Resets the user's password using a token sent to their email.
  /// Returns true if the reset was successful, false otherwise.
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoadingState(true);
    try {
      await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
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

  void _setLoadingState(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
}
