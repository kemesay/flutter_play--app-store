import 'dart:math';

double haversineDistanceInMiles({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
}) {
  const earthRadiusMiles = 3958.8;

  final dLat = _degreesToRadians(endLat - startLat);
  final dLon = _degreesToRadians(endLng - startLng);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(startLat)) *
          cos(_degreesToRadians(endLat)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return double.parse((earthRadiusMiles * c).toStringAsFixed(2));
}

double _degreesToRadians(double degrees) {
  return degrees * (pi / 180);
}
