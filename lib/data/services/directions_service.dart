import 'dart:convert';
import 'dart:math';

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
    List<LatLng> waypoints = const [],
    String mode = 'driving',
  }) async {
    final firstRoute = await _fetchFirstRoute(
      origin: origin,
      destination: destination,
      waypoints: waypoints,
      mode: mode,
    );
    if (firstRoute == null) return null;

    final legs = firstRoute['legs'] as List<dynamic>? ?? const [];
    if (legs.isEmpty) return null;

    final totals = _sumLegs(legs);
    var totalDistanceMeters = totals.meters;
    final totalDurationSeconds = totals.seconds;

    // Google's routing engine re-optimizes each leg of a multi-stop trip
    // independently — it does not guarantee the route through a detour stop
    // reuses the same roads as the direct route plus a side trip. In
    // practice this occasionally makes the WITH-DETOUR total come back
    // shorter in raw distance than the direct route, while still taking
    // longer (the roads it picks instead are more local/slower) — matches
    // the same fix already shipped on the website (resolveDistanceMeters in
    // rideDetailForm/index.jsx). Riders and admins reasonably expect adding
    // a stop to never make a trip *shorter*, so the billed/displayed
    // distance is floored at whatever the direct (no-waypoint) trip would
    // have been. Duration is left exactly as Google reports it for the
    // actual route driven — that time difference is real either way.
    if (waypoints.isNotEmpty) {
      try {
        final directRoute = await _fetchFirstRoute(
          origin: origin,
          destination: destination,
          waypoints: const [],
          mode: mode,
        );
        final directLegs = directRoute?['legs'] as List<dynamic>? ?? const [];
        if (directLegs.isNotEmpty) {
          final directMeters = _sumLegs(directLegs).meters;
          totalDistanceMeters = max(totalDistanceMeters, directMeters);
        }
      } catch (_) {
        // Best-effort baseline check — a failure here (network, ZERO_RESULTS,
        // ...) never blocks the booking flow; fall back to the with-detour
        // total exactly as computed above.
      }
    }

    final polylineData =
        firstRoute['overview_polyline'] as Map<String, dynamic>? ?? const {};
    final encoded = polylineData['points']?.toString();

    final points = <LatLng>[];
    if (encoded != null) {
      points.addAll(_decodePolyline(encoded));
    }

    // Format total duration as human-readable text
    final totalMins = (totalDurationSeconds / 60).round();
    final hrs = totalMins ~/ 60;
    final mins = totalMins % 60;
    final durationText =
        hrs > 0 ? '$hrs hr $mins min' : '$mins min';

    final totalDistanceMiles = totalDistanceMeters / 1609.344;
    final distanceText = '${totalDistanceMiles.toStringAsFixed(1)} mi';

    return DirectionsRoute(
      distanceMeters: totalDistanceMeters,
      durationSeconds: totalDurationSeconds,
      polyline: points,
      distanceText: distanceText,
      durationText: durationText,
    );
  }

  /// Raw Directions API call, parsed down to just the first route's JSON
  /// (what both the with-waypoints call and the direct-baseline call need).
  /// Returns null on a routeless response (e.g. ZERO_RESULTS) rather than
  /// throwing, matching `fetchRoute`'s existing null-on-empty handling.
  Future<Map<String, dynamic>?> _fetchFirstRoute({
    required LatLng origin,
    required LatLng destination,
    required List<LatLng> waypoints,
    required String mode,
  }) async {
    final queryParameters = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'travelMode': mode,
      'mode': mode,
      'key': Constatnts.API_KEY,
    };

    if (waypoints.isNotEmpty) {
      queryParameters['waypoints'] =
          waypoints.map((w) => '${w.latitude},${w.longitude}').join('|');
    }

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
    return routes.first as Map<String, dynamic>;
  }

  /// Sums distance (meters) and duration (seconds) across every leg of a
  /// route — a multi-stop trip (origin -> waypoint -> ... -> destination)
  /// comes back as one leg per hop, and the real trip total is the sum of
  /// all of them, never just the first or last leg alone.
  ({double meters, double seconds}) _sumLegs(List<dynamic> legs) {
    var meters = 0.0;
    var seconds = 0.0;
    for (final rawLeg in legs) {
      final leg = rawLeg as Map<String, dynamic>;
      final d = leg['distance'] as Map<String, dynamic>? ?? const {};
      final dur = leg['duration'] as Map<String, dynamic>? ?? const {};
      meters += (d['value'] as num?)?.toDouble() ?? 0;
      seconds += (dur['value'] as num?)?.toDouble() ?? 0;
    }
    return (meters: meters, seconds: seconds);
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
