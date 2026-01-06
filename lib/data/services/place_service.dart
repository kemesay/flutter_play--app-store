import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../utils/constants.dart';
import '../../model/place_model.dart';

class PlaceService {
  PlaceService({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'maps.googleapis.com';
  static const _autocompletePath = '/maps/api/place/autocomplete/json';
  static const _detailsPath = '/maps/api/place/details/json';
  static const _geocodePath = '/maps/api/geocode/json';

  final http.Client _client;
  final Uuid _uuid = const Uuid();

  Future<List<Place>> fetchSuggestions(
    String input, {
    String? sessionToken,
    String? country,
  }) async {
    if (input.isEmpty) return const [];

    final token = sessionToken ?? _uuid.v4();
    final queryParameters = <String, String>{
      'input': input.trim(),
      'key': Constatnts.API_KEY,
      'sessiontoken': token,
      'language': 'en',
    };

    if (country != null && country.trim().isNotEmpty) {
      final code = country.trim().toUpperCase();
      if (code.length != 2) {
        throw ArgumentError(
            'Country code must be 2 letters (e.g., "US", "CA").');
      }
      queryParameters['components'] = 'country:$code';
    }

    final uri = Uri.https(_host, _autocompletePath, queryParameters);
    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMessage =
          decoded['error_message']?.toString() ?? 'Autocomplete request failed';
      throw Exception(errorMessage);
    }

    final predictions = decoded['predictions'] as List<dynamic>? ?? const [];
    return predictions
        .whereType<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList();
  }

  Future<PlaceDetail> fetchPlaceDetail(
    String placeId, {
    String? sessionToken,
  }) async {
    final token = sessionToken ?? _uuid.v4();
    final queryParameters = <String, String>{
      'place_id': placeId,
      'key': Constatnts.API_KEY,
      'sessiontoken': token,
      'language': 'en',
    };

    final uri = Uri.https(_host, _detailsPath, queryParameters);
    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMessage =
          decoded['error_message']?.toString() ?? 'Place detail request failed';
      throw Exception(errorMessage);
    }

    final result = decoded['result'] as Map<String, dynamic>? ?? const {};
    return PlaceDetail.fromJson(result);
  }

  Future<PlaceDetail?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final queryParameters = <String, String>{
      'latlng': '$latitude,$longitude',
      'key': Constatnts.API_KEY,
      'language': 'en',
      'result_type': 'street_address|premise|point_of_interest',
    };

    final uri = Uri.https(_host, _geocodePath, queryParameters);
    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMessage =
          decoded['error_message']?.toString() ?? 'Reverse geocoding failed';
      throw Exception(errorMessage);
    }

    final results = decoded['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) return null;
    return PlaceDetail.fromJson(results.first as Map<String, dynamic>);
  }
}
