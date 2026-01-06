enum TravelType {
  pointToPoint,
  airport,
  hourlyCharter,
}

extension TravelTypeExtension on TravelType {
  String get label {
    switch (this) {
      case TravelType.pointToPoint:
        return 'Point to Point';
      case TravelType.airport:
        return 'Airport Transfer';
      case TravelType.hourlyCharter:
        return 'Hourly Charter';
    }
  }
}

