import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/place_model.dart';
import '../utils/constants.dart';

/// Legacy Google Maps service for Places Autocomplete & Place Details.
///
/// Uses the same API key strategy as the React app:
/// the key is provided centrally via `Constatnts.API_KEY`,
/// similar to how `useLoadScript({ googleMapsApiKey })` works in React.
class GoogleMapServices {
  final String sessionToken;

  GoogleMapServices({required this.sessionToken});

  /// Fetch autocomplete suggestions for a query.
  ///
  /// - Uses the shared `Constatnts.API_KEY` (same concept as React `googleMapsApiKey`).
  /// - Restricts results by 2‑letter ISO country code (default: US).
  Future<List<Place>> getSuggestions(
    String query, {
    String country = 'US',
  }) async {
    if (query.trim().isEmpty) return const [];

    final sanitizedCountry = country.trim().toUpperCase();
    if (sanitizedCountry.length != 2) {
      throw ArgumentError('Country code must be a 2-letter ISO code.');
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query,
        'key': Constatnts.API_KEY,
        'sessiontoken': sessionToken,
        'language': 'en',
        'components': 'country:$sanitizedCountry',
      },
    );

    final response = await http.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message =
          decoded['error_message']?.toString() ?? 'Autocomplete request failed';
      throw Exception(message);
    }

    final predictions = decoded['predictions'] as List<dynamic>? ?? const [];
    return predictions
        .whereType<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList();
  }

  /// Fetch full place details for a given `placeId`.
  ///
  /// Uses the same centralized API key as the React app.
  Future<PlaceDetail> getPlaceDetail(String placeId, String token) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'key': Constatnts.API_KEY,
        'place_id': placeId,
        'language': 'en',
        'sessiontoken': token,
      },
    );

    final response = await http.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message =
          decoded['error_message']?.toString() ?? 'Place details request failed';
      throw Exception(message);
    }

    final result = decoded['result'] as Map<String, dynamic>? ?? const {};
    return PlaceDetail.fromJson(result);
  }
}
