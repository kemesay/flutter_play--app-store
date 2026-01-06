import '../../core/network/api_client.dart';
import '../models/additional_stop_model.dart';
import '../models/airport_model.dart';
import '../models/airport_pickup_preference_model.dart';
import '../models/car_model.dart';
import '../models/extra_option_model.dart';
import '../models/gratuity_model.dart';
import '../models/popular_place_model.dart';

class CatalogService {
  CatalogService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CarModel>> fetchCars() async {
    final response = await _apiClient.get('/cars') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(CarModel.fromJson)
        .toList();
  }

  Future<List<ExtraOptionModel>> fetchExtraOptions() async {
    final response = await _apiClient.get('/extra-options') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(ExtraOptionModel.fromJson)
        .toList();
  }

  Future<List<GratuityModel>> fetchGratuities() async {
    final response = await _apiClient.get('/gratuities') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(GratuityModel.fromJson)
        .toList();
  }

  Future<List<AdditionalStopModel>> fetchAdditionalStops() async {
    final response = await _apiClient.get('/additional-stops') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(AdditionalStopModel.fromJson)
        .toList();
  }

  Future<List<AirportModel>> fetchAirports() async {
    final response = await _apiClient.get('/airports') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(AirportModel.fromJson)
        .toList();
  }

  Future<List<AirportPickupPreferenceModel>> fetchAirportPickupPreferences() async {
    final response =
        await _apiClient.get('/airport/pickup-preference') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(AirportPickupPreferenceModel.fromJson)
        .toList();
  }

  Future<List<PopularPlaceModel>> fetchPopularPlaces() async {
    final response =
        await _apiClient.get('/popular-places') as List<dynamic>;
    return response
        .whereType<Map<String, dynamic>>()
        .map(PopularPlaceModel.fromJson)
        .toList();
  }
}

