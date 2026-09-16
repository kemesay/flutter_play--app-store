import '../../core/network/api_client.dart';
import '../models/side_detour_settings.dart';

class SideDetourSettingsService {
  SideDetourSettingsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SideDetourSettings> fetchSettings() async {
    final response = await _apiClient.get(
      '/side-detour-settings',
      authenticated: false,
    );

    if (response is Map<String, dynamic>) {
      return SideDetourSettings.fromJson(response);
    }
    throw const FormatException('Invalid side detour settings response');
  }
}
