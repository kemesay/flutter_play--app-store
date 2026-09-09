export '../core/config/square_credentials.dart';

/// App-wide config: API host and storage keys.
class AppConfig {
  AppConfig._();

  /// Single source of truth for the backend host. ODA Transportation has
  /// no local/dev backend — every build, debug or release, talks to production.
  static const String apiBaseUrl = 'https://api.odatransportation.com/api/v1';

  // Booking submission (Square charge + DB write) can legitimately take
  // longer than a simple GET under load; a generous timeout here reduces
  // false "request timed out" errors on requests the server actually
  // completes (see ApiException.isTimeout for why that distinction matters).
  static const Duration requestTimeout = Duration(seconds: 45);
  static const String accessTokenStorageKey = 'access_token';
  static const String userProfileStorageKey = 'user_profile';
}
