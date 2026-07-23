import 'package:flutter/foundation.dart';

import 'square_credentials.dart';
import '../../data/models/square_public_config.dart';
import '../../data/services/square_config_service.dart';

/// Runtime Square configuration loaded from backend.
///
/// This avoids hardcoded sandbox ids in release builds and ensures the mobile
/// client matches backend's Square environment and location.
class SquareRuntimeConfig extends ChangeNotifier {
  SquareRuntimeConfig({SquareConfigService? service})
      : _service = service ?? SquareConfigService();

  final SquareConfigService _service;

  SquarePublicConfig? _config;
  Object? _lastError;
  bool _loading = false;
  bool _disposed = false;

  SquarePublicConfig? get config => _config;
  bool get hasConfig => _config != null;
  bool get isLoading => _loading;
  Object? get lastError => _lastError;

  bool get squareEnabled =>
      _config?.squareEnabled == true && SquareCredentials.useSquarePayments;

  String get applicationId =>
      _nonEmpty(_config?.applicationId) ?? SquareCredentials.applicationId;

  String get locationId =>
      _nonEmpty(_config?.locationId) ?? SquareCredentials.locationId;

  String get environment =>
      _nonEmpty(_config?.environment) ?? SquareCredentials.environmentName;

  String get paymentMode =>
      _nonEmpty(_config?.paymentMode) ?? 'authorize_capture';

  bool get isAuthorizeCaptureMode =>
      paymentMode == 'authorize_capture' ||
      paymentMode == 'authorize' ||
      paymentMode == 'charge_on_take';

  static String? _nonEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _config != null) return;

    _loading = true;
    _lastError = null;
    _safeNotify();

    try {
      final cfg = await _service.fetchPublicConfig();
      if (_disposed) return;
      _config = cfg;
    } catch (e) {
      _lastError = e;
      // Keep previous config if any; don't hard-fail app startup.
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

