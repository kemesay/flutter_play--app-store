import '../../core/network/api_client.dart';
import '../models/square_public_config.dart';

class SquareConfigService {
  SquareConfigService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<SquarePublicConfig> fetchPublicConfig() async {
    final response = await _apiClient.get(
      '/payments/square/config',
      authenticated: false,
    );

    if (response is Map<String, dynamic>) {
      return SquarePublicConfig.fromJson(response);
    }
    throw const FormatException('Invalid Square config response');
  }
}

