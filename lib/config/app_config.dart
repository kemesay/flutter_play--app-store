class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = 'https://api.odatransportation.com/api/v1';

  static const Duration requestTimeout = Duration(seconds: 30);

  static const String accessTokenStorageKey = 'access_token';
  static const String userProfileStorageKey = 'user_profile';
}

