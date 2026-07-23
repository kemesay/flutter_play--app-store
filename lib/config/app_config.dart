export '../core/config/square_credentials.dart';

/// App-wide config: API host and storage keys.
class AppConfig {
  AppConfig._();

  /// Single source of truth for the backend host. ODA Transportation has
  /// no local/dev backend — every build, debug or release, talks to production.
  static const String apiBaseUrl = 'https://api.odatransportation.com/api/v1';

  static const Duration requestTimeout = Duration(seconds: 30);
  static const String accessTokenStorageKey = 'access_token';
  static const String userProfileStorageKey = 'user_profile';
}
