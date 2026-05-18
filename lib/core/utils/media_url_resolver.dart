import '../../config/app_config.dart';

/// Resolves vehicle (and other) media paths from the API into absolute URLs.
String? resolveMediaUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }

  final apiRoot = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  if (trimmed.startsWith('/')) {
    return '$apiRoot$trimmed';
  }
  return '$apiRoot/$trimmed';
}
