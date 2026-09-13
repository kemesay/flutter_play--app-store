/// Single source of truth for Square payment credentials and environment.
///
/// Master env template: `ODA-TRANSPORTATION/square.env.example`
/// Backend secrets: `ODA-TRANSPORTATION/src/config/squareCredentials.js` + `.env`
///
/// ## Two different “signatures” (do not mix them up)
///
/// 1. **Mobile Payments SDK** (Square Dashboard → Mobile Payments SDK → Add signature)
///    - Android: [androidPackageName] + SHA-256 from `./gradlew signingReport`
///    - iOS: [iosBundleId] + Apple Team ID — registered in the dashboard only; **not** passed in Dart.
///    - This is **not** `webhookSignatureKey`.
///
/// 2. **Webhooks** (Square Dashboard → Webhooks → subscription → Signature key)
///    - Server-only: set [webhookSignatureKey] in `ODA-TRANSPORTATION/.env` as
///      `SQUARE_PRODUCTION_WEBHOOK_SIGNATURE_KEY` or `SQUARE_SANDBOX_WEBHOOK_SIGNATURE_KEY`.
///    - Used by `squareWebhookService.js` to verify `POST /api/v1/webhooks/square`.
///
/// ## ODA production `.env` → this Flutter app
///
/// | Backend only (`.env`) | Flutter (`square_credentials` / runtime API) |
/// |----------------------|---------------------------------------------|
/// | `SQUARE_ACCESS_TOKEN` | **Do not add** |
/// | `SQUARE_APPLICATION_ID=sq0idp-...` | [productionApplicationId] fallback |
/// | `SQUARE_LOCATION_ID=45AM047H464XK` | [productionLocationId] fallback |
/// | `SQUARE_PRODUCTION_WEBHOOK_SIGNATURE_KEY` | **Do not add** |
/// | `PAYMENT_PROVIDER` / `PAYMENT_MODE` | Server only |
library;

/// Square API environment (matches backend `SQUARE_ENV`).
enum SquareEnvironment {
  sandbox,
  production;

  String get value => name;

  static SquareEnvironment parse(String? raw) {
    if (raw == null) return SquareEnvironment.sandbox;
    switch (raw.trim().toLowerCase()) {
      case 'production':
      case 'prod':
        return SquareEnvironment.production;
      default:
        return SquareEnvironment.sandbox;
    }
  }
}

/// All Square credentials and environment toggles for ODA Black Car Service.
class SquareCredentials {
  SquareCredentials._();

  // ---------------------------------------------------------------------------
  // Active environment
  //   ACTIVE — live production. Flip back to `SquareEnvironment.sandbox` to
  //   test again (or pass --dart-define=SQUARE_ENV=sandbox at build time).
  // ---------------------------------------------------------------------------
  static const SquareEnvironment defaultEnvironment = SquareEnvironment.production;

  static bool get _preferProductionBuild {
    const force = bool.fromEnvironment('PRODUCTION_API', defaultValue: false);
    return force;
  }

  static SquareEnvironment get activeEnvironment {
    const raw = String.fromEnvironment('SQUARE_ENV', defaultValue: '');
    if (raw.isNotEmpty) return SquareEnvironment.parse(raw);
    if (_preferProductionBuild) return SquareEnvironment.production;
    return defaultEnvironment;
  }

  // ---------------------------------------------------------------------------
  // Sandbox (Square Developer Dashboard → Sandbox)
  // ---------------------------------------------------------------------------

  /// Server-only. Set in `ODA-TRANSPORTATION/.env` as `SQUARE_ACCESS_TOKEN`.
  /// Optional `--dart-define` for local tooling only — not used by the mobile SDK.
  static const String sandboxAccessToken = String.fromEnvironment(
    'SQUARE_SANDBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String sandboxApplicationId = String.fromEnvironment(
    'SQUARE_SANDBOX_APPLICATION_ID',
    defaultValue: 'sandbox-sq0idb-3FtfRZJZuhx76hDTMmWWpA',
  );

  static const String sandboxLocationId = String.fromEnvironment(
    'SQUARE_SANDBOX_LOCATION_ID',
    defaultValue: 'LDM77465MQARF',
  );

  static const String sandboxWebhookSignatureKey = String.fromEnvironment(
    'SQUARE_SANDBOX_WEBHOOK_SIGNATURE_KEY',
    defaultValue: '',
  );

  static const String sandboxWebhookNotificationUrl = String.fromEnvironment(
    'SQUARE_SANDBOX_WEBHOOK_NOTIFICATION_URL',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Production (Square Developer Dashboard → Production)
  // ---------------------------------------------------------------------------

  static const String productionAccessToken = String.fromEnvironment(
    'SQUARE_PRODUCTION_ACCESS_TOKEN',
    defaultValue: '',
  );

  /// Public — same as `SQUARE_APPLICATION_ID` in production `.env`.
  static const String productionApplicationId = String.fromEnvironment(
    'SQUARE_PRODUCTION_APPLICATION_ID',
    defaultValue: 'sq0idp-KGHJzmdtUHXPJAPWR0cbjA',
  );

  /// Public — same as `SQUARE_LOCATION_ID` in production `.env`.
  static const String productionLocationId = String.fromEnvironment(
    'SQUARE_PRODUCTION_LOCATION_ID',
    defaultValue: '45AM047H464XK',
  );

  static const String productionWebhookSignatureKey = String.fromEnvironment(
    'SQUARE_PRODUCTION_WEBHOOK_SIGNATURE_KEY',
    defaultValue: '',
  );

  static const String productionWebhookNotificationUrl = String.fromEnvironment(
    'SQUARE_PRODUCTION_WEBHOOK_NOTIFICATION_URL',
    defaultValue: 'https://api.odatransportation.com/api/v1/webhooks/square',
  );

  // ---------------------------------------------------------------------------
  // Legacy dart-define overrides (apply to whichever environment is active)
  // ---------------------------------------------------------------------------

  static const String _applicationIdOverride = String.fromEnvironment(
    'SQUARE_APPLICATION_ID',
    defaultValue: '',
  );

  static const String _locationIdOverride = String.fromEnvironment(
    'SQUARE_LOCATION_ID',
    defaultValue: '',
  );

  static const String _accessTokenOverride = String.fromEnvironment(
    'SQUARE_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String _webhookSignatureKeyOverride = String.fromEnvironment(
    'SQUARE_WEBHOOK_SIGNATURE_KEY',
    defaultValue: '',
  );

  static const String _webhookNotificationUrlOverride = String.fromEnvironment(
    'SQUARE_WEBHOOK_NOTIFICATION_URL',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Mobile Payments SDK — dashboard registration (public, not secrets)
  // ---------------------------------------------------------------------------

  /// Must match `applicationId` in `android/app/build.gradle` and Square → Android signature.
  static const String androidPackageName = 'com.odatransportation.app';

  /// Must match Xcode `PRODUCT_BUNDLE_IDENTIFIER` and Square → iOS signature.
  static const String iosBundleId = String.fromEnvironment(
    'SQUARE_IOS_BUNDLE_ID',
    defaultValue: 'com.odatransportation.app',
  );

  /// Apple Developer Team ID (Square → iOS signature). Example from dashboard: VB7U8RMMV9.
  static const String iosTeamId = String.fromEnvironment(
    'SQUARE_IOS_TEAM_ID',
    defaultValue: '',
  );

  // ---------------------------------------------------------------------------
  // Resolved values for the active environment
  // ---------------------------------------------------------------------------

  static String get accessToken {
    if (_accessTokenOverride.isNotEmpty) return _accessTokenOverride;
    return switch (activeEnvironment) {
      SquareEnvironment.sandbox => sandboxAccessToken,
      SquareEnvironment.production => productionAccessToken,
    };
  }

  static String get applicationId {
    if (_applicationIdOverride.isNotEmpty) return _applicationIdOverride;
    return switch (activeEnvironment) {
      SquareEnvironment.sandbox => sandboxApplicationId,
      SquareEnvironment.production => productionApplicationId,
    };
  }

  static String get locationId {
    if (_locationIdOverride.isNotEmpty) return _locationIdOverride;
    return switch (activeEnvironment) {
      SquareEnvironment.sandbox => sandboxLocationId,
      SquareEnvironment.production => productionLocationId,
    };
  }

  static String get webhookSignatureKey {
    if (_webhookSignatureKeyOverride.isNotEmpty) {
      return _webhookSignatureKeyOverride;
    }
    return switch (activeEnvironment) {
      SquareEnvironment.sandbox => sandboxWebhookSignatureKey,
      SquareEnvironment.production => productionWebhookSignatureKey,
    };
  }

  static String get webhookNotificationUrl {
    if (_webhookNotificationUrlOverride.isNotEmpty) {
      return _webhookNotificationUrlOverride;
    }
    return switch (activeEnvironment) {
      SquareEnvironment.sandbox => sandboxWebhookNotificationUrl,
      SquareEnvironment.production => productionWebhookNotificationUrl,
    };
  }

  /// Env var name for [webhookSignatureKey] on the backend (for `.env` copy/paste).
  static String get webhookSignatureKeyEnvName => switch (activeEnvironment) {
        SquareEnvironment.sandbox => 'SQUARE_SANDBOX_WEBHOOK_SIGNATURE_KEY',
        SquareEnvironment.production => 'SQUARE_PRODUCTION_WEBHOOK_SIGNATURE_KEY',
      };

  static bool get isSandbox => activeEnvironment == SquareEnvironment.sandbox;

  static bool get isProduction =>
      activeEnvironment == SquareEnvironment.production;

  /// Matches backend `SQUARE_ENV` string.
  static String get environmentName => activeEnvironment.value;

  /// Whether the mobile SDK can initialize (public application id present).
  static bool get hasClientConfig => applicationId.trim().isNotEmpty;

  /// Whether server-side Square API calls can run (backend `.env`).
  static bool get hasServerAccessToken => accessToken.trim().isNotEmpty;

  /// Feature flag: disable Square flows entirely in the app.
  static const bool useSquarePayments = bool.fromEnvironment(
    'USE_SQUARE_PAYMENTS',
    defaultValue: true,
  );

  /// Checklist for Square Dashboard → Mobile Payments SDK (not webhook keys).
  static String toMobilePaymentsSdkChecklist() {
    final iosTeam =
        iosTeamId.isEmpty ? '<Apple Team ID from developer.apple.com>' : iosTeamId;
    return '''
Mobile Payments SDK (${activeEnvironment.name}) — register in Square Dashboard only:
  Android package: $androidPackageName
  Android SHA-256:   run: cd android && ./gradlew signingReport
  iOS bundle ID:   $iosBundleId
  iOS Team ID:     $iosTeam

Webhook signature key goes under Webhooks → your subscription → Signature key,
then paste into ODA-TRANSPORTATION/.env as $webhookSignatureKeyEnvName
'''.trim();
  }

  /// Copy/paste block for `ODA-TRANSPORTATION/.env` (keep in sync with this file).
  static String toBackendEnvSnippet() {
    final token = accessToken.isEmpty ? '<your_access_token>' : accessToken;
    final webhookKey = webhookSignatureKey.isEmpty
        ? '<from Square Dashboard → Webhooks → Signature key>'
        : webhookSignatureKey;
    final webhookUrl = webhookNotificationUrl.isEmpty
        ? 'https://api.odatransportation.com/api/v1/webhooks/square'
        : webhookNotificationUrl;
    final tokenEnv = activeEnvironment == SquareEnvironment.production
        ? 'SQUARE_PRODUCTION_ACCESS_TOKEN'
        : 'SQUARE_SANDBOX_ACCESS_TOKEN';
    final appIdEnv = activeEnvironment == SquareEnvironment.production
        ? 'SQUARE_PRODUCTION_APPLICATION_ID'
        : 'SQUARE_SANDBOX_APPLICATION_ID';
    final locationEnv = activeEnvironment == SquareEnvironment.production
        ? 'SQUARE_PRODUCTION_LOCATION_ID'
        : 'SQUARE_SANDBOX_LOCATION_ID';
    final webhookUrlEnv = activeEnvironment == SquareEnvironment.production
        ? 'SQUARE_PRODUCTION_WEBHOOK_NOTIFICATION_URL'
        : 'SQUARE_SANDBOX_WEBHOOK_NOTIFICATION_URL';

    return '''
PAYMENT_PROVIDER=square
PAYMENT_MODE=authorize_capture
SQUARE_ENV=$environmentName
$tokenEnv=$token
$appIdEnv=$applicationId
$locationEnv=$locationId
$webhookSignatureKeyEnvName=$webhookKey
$webhookUrlEnv=$webhookUrl
'''.trim();
  }
}
