import 'package:flutter/foundation.dart';

import '../../data/models/side_detour_settings.dart';
import '../../data/services/side_detour_settings_service.dart';

/// Optional side-pick-detour fee, controlled entirely from the admin
/// dashboard (off by default). Loaded once at startup so booking forms can
/// preview a fare that matches what the backend will actually charge.
class SideDetourSettingsProvider extends ChangeNotifier {
  SideDetourSettingsProvider({SideDetourSettingsService? service})
      : _service = service ?? SideDetourSettingsService();

  final SideDetourSettingsService _service;

  SideDetourSettings _settings = SideDetourSettings.off;
  bool _loading = false;
  bool _disposed = false;

  SideDetourSettings get settings => _settings;
  bool get isActive => _settings.isActive;
  double get startFee => _settings.startFee;
  bool get isLoading => _loading;

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _settings != SideDetourSettings.off) return;

    _loading = true;
    _safeNotify();

    try {
      final fetched = await _service.fetchSettings();
      if (_disposed) return;
      _settings = fetched;
    } catch (e) {
      // Keep "off" default; a guest mid-booking shouldn't see an error over
      // an optional fee preview failing to load.
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
