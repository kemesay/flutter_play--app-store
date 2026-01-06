import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../utils/constants.dart';

class DirectionsRoute {
  const DirectionsRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
    required this.distanceText,
    required this.durationText,
  });

  final double distanceMeters;
  final double durationSeconds;
  final List<LatLng> polyline;
  final String? distanceText;
  final String? durationText;

  // Match website: distance is stored with 2 decimal places precision
  // Website: distanceInMile.toFixed(2) - converts meters to miles and rounds to 2 decimals
  double get distanceMiles {
    final miles = distanceMeters / 1609.344;
    // Round to 2 decimal places to match website precision
    return double.parse(miles.toStringAsFixed(2));
  }
}

class DirectionsService {
  DirectionsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _endpoint = 'maps.googleapis.com';
  static const _directionsPath = '/maps/api/directions/json';

  Future<DirectionsRoute?> fetchRoute({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
  }) async {
    final queryParameters = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelMode': mode,
      'mode': mode,
      'key': Constatnts.API_KEY,
    };

    final uri = Uri.https(_endpoint, _directionsPath, queryParameters);
    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final errorMessage =
          decoded['error_message']?.toString() ?? 'Directions request failed';
      throw Exception(errorMessage);
    }

    final routes = decoded['routes'] as List<dynamic>? ?? const [];
    if (routes.isEmpty) return null;
    final firstRoute = routes.first as Map<String, dynamic>;
    final legs = firstRoute['legs'] as List<dynamic>? ?? const [];
    if (legs.isEmpty) return null;
    final firstLeg = legs.first as Map<String, dynamic>;
    final distance = firstLeg['distance'] as Map<String, dynamic>? ?? const {};
    final duration = firstLeg['duration'] as Map<String, dynamic>? ?? const {};
    final polylineData =
        firstRoute['overview_polyline'] as Map<String, dynamic>? ?? const {};
    final encoded = polylineData['points']?.toString();

    final points = <LatLng>[];
    if (encoded != null) {
      points.addAll(_decodePolyline(encoded));
    }

    final distanceValue = (distance['value'] as num?)?.toDouble() ?? 0;
    final durationValue = (duration['value'] as num?)?.toDouble() ?? 0;

    return DirectionsRoute(
      distanceMeters: distanceValue,
      durationSeconds: durationValue,
      polyline: points,
      distanceText: distance['text']?.toString(),
      durationText: duration['text']?.toString(),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      result = 0;
      shift = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(
        LatLng(lat / 1e5, lng / 1e5),
      );
    }
    return points;
  }
}
