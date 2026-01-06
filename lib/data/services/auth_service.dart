import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      body: {
        'username': username,
        'password': password,
      },
    ) as Map<String, dynamic>;

    final token = response['auth-token']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException('Authentication token not found in response');
    }

    await _tokenStorage.saveToken(token);
    return token;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/users',
      body: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      },
    ) as Map<String, dynamic>;

    final user = UserModel.fromJson(response);
    await _tokenStorage.saveUserProfile(user.toJson());
    return user;
  }

  Future<UserModel> fetchProfile({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _tokenStorage.readUserProfile();
      if (cached != null) {
        return UserModel.fromJson(cached);
      }
    }

    final response = await _apiClient.get(
      '/users/me',
      authenticated: true,
    ) as Map<String, dynamic>;

    final user = UserModel.fromJson(response);
    await _tokenStorage.saveUserProfile(user.toJson());
    return user;
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    final response = await _apiClient.put(
      '/users',
      authenticated: true,
      body: body,
    ) as Map<String, dynamic>;

    final user = UserModel.fromJson(response);
    await _tokenStorage.saveUserProfile(user.toJson());
    return user;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/auth/change-password',
      authenticated: true,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _apiClient.post(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '/auth/reset-password',
      body: {
        'token': token,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    await _tokenStorage.clearUserProfile();
  }
}

