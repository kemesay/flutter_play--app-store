import 'package:flutter/foundation.dart';

import '../../config/app_config.dart';

/// App-facing Square settings — delegates to [SquareCredentials].
///
/// Import this file or `square_credentials.dart`; do not duplicate IDs elsewhere.
///
/// Production release: SDK reads [SquareRuntimeConfig] from
/// `GET ${AppConfig.apiBaseUrl}/payments/square/config` first.
class SquareConfig {
  SquareConfig._();

  static bool get useSquarePayments => SquareCredentials.useSquarePayments;

  static SquareEnvironment get environment => SquareCredentials.activeEnvironment;

  static String get applicationId => SquareCredentials.applicationId;

  static String get locationId => SquareCredentials.locationId;

  static String get accessToken => SquareCredentials.accessToken;

  static bool get isSandbox => SquareCredentials.isSandbox;

  static bool get isProduction => SquareCredentials.isProduction;

  static bool get hasClientConfig => SquareCredentials.hasClientConfig;

  /// Server-only — paste into `ODA-TRANSPORTATION/.env` ([SquareCredentials.webhookSignatureKeyEnvName]).
  static String get webhookSignatureKey => SquareCredentials.webhookSignatureKey;

  static String get webhookNotificationUrl =>
      SquareCredentials.webhookNotificationUrl;

  static String get androidPackageName => SquareCredentials.androidPackageName;

  static String get iosBundleId => SquareCredentials.iosBundleId;

  /// Resolved API root for Square config fetch (production in release).
  static String get apiBaseUrl => AppConfig.apiBaseUrl;

  /// True when building for live Square + live API.
  static bool get isProductionBuild =>
      kReleaseMode ||
      SquareCredentials.activeEnvironment == SquareEnvironment.production;
}
