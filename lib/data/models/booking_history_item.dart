enum BookingType {
  pointToPoint,
  airport,
  hourlyCharter,
}

class BookingHistoryItem {
  BookingHistoryItem({
    required this.type,
    required this.id,
    required this.confirmationNumber,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.paymentMethod,
    this.pickupDateTime,
    this.returnPickupDateTime,
    this.pickupAddress,
    this.dropoffAddress,
    this.totalFee,
    this.tripType,
    this.passengerName,
    this.carImageUrl,
    Map<String, dynamic>? rawData,
  }) : rawData = rawData ?? <String, dynamic>{};

  final BookingType type;
  final int id;
  final String confirmationNumber;
  final String paymentStatus;
  final String bookingStatus;
  final String paymentMethod;
  final DateTime? pickupDateTime;
  final DateTime? returnPickupDateTime;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? totalFee;
  final String? tripType;
  final String? passengerName;
  final String? carImageUrl;
  final Map<String, dynamic> rawData;

  String get displayTitle {
    switch (type) {
      case BookingType.pointToPoint:
        return 'Point to Point';
      case BookingType.airport:
        return 'Airport Transfer';
      case BookingType.hourlyCharter:
        return 'Hourly Charter';
    }
  }

  String get referenceLabel => '#$confirmationNumber';

  factory BookingHistoryItem.fromJson(Map<String, dynamic> json) {
    final type = _detectBookingType(json);
    final id = _resolveBookingId(json, type);
    return BookingHistoryItem(
      type: type,
      id: id,
      confirmationNumber: json['confirmationNumber']?.toString() ?? '$id',
      paymentStatus: json['paymentStatus']?.toString() ?? 'NOT_PAID',
      bookingStatus: json['bookingStatus']?.toString() ?? 'PENDING_APPROVAL',
      paymentMethod: json['paymentMethod']?.toString() ?? 'UNKNOWN',
      pickupDateTime: _parseDate(json['pickupDateTime'] ?? json['createdAt']),
      returnPickupDateTime: _parseDate(json['returnPickupDateTime']),
      pickupAddress: _resolvePickupAddress(json, type),
      dropoffAddress: _resolveDropoffAddress(json, type),
      totalFee: _parseDouble(json['totalTripFeeInDollars']),
      tripType: json['tripType']?.toString(),
      passengerName: json['passengerFullName']?.toString(),
      carImageUrl: _resolveCarImageUrl(json),
      rawData: json,
    );
  }

  static BookingType _detectBookingType(Map<String, dynamic> json) {
    if (json.containsKey('pointToPointBookId')) {
      return BookingType.pointToPoint;
    }
    if (json.containsKey('airportBookId')) {
      return BookingType.airport;
    }
    return BookingType.hourlyCharter;
  }

  static int _resolveBookingId(Map<String, dynamic> json, BookingType type) {
    switch (type) {
      case BookingType.pointToPoint:
        return _parseInt(json['pointToPointBookId']);
      case BookingType.airport:
        return _parseInt(json['airportBookId']);
      case BookingType.hourlyCharter:
        return _parseInt(json['hourlyCharterBookId']);
    }
  }

  static String? _resolvePickupAddress(
    Map<String, dynamic> json,
    BookingType type,
  ) {
    switch (type) {
      case BookingType.pointToPoint:
        return json['pickupPhysicalAddress']?.toString();
      case BookingType.airport:
        // Match API response: nested object is 'Airport' (capitalized)
        if (json['tripType']?.toString().contains('from') ?? false) {
          return json['Airport']?['airportName']?.toString() ??
              json['airport']?['airportName']?.toString() ??
              json['airportName']?.toString();
        }
        return json['accommodationAddress']?.toString();
      case BookingType.hourlyCharter:
        return json['pickupLocation']?.toString() ??
            json['pickupPhysicalAddress']?.toString();
    }
  }

  static String? _resolveDropoffAddress(
    Map<String, dynamic> json,
    BookingType type,
  ) {
    switch (type) {
      case BookingType.pointToPoint:
        return json['dropoffPhysicalAddress']?.toString();
      case BookingType.airport:
        // Match API response: nested object is 'Airport' (capitalized)
        if (json['tripType']?.toString().contains('to the airport') ?? false) {
          return json['Airport']?['airportName']?.toString() ??
              json['airport']?['airportName']?.toString() ??
              json['airportName']?.toString();
        }
        return json['accommodationAddress']?.toString();
      case BookingType.hourlyCharter:
        return json['destination']?.toString() ??
            json['dropoffPhysicalAddress']?.toString();
    }
  }

  static String? _resolveCarImageUrl(Map<String, dynamic> json) {
    final car = json['Car'];
    if (car is Map<String, dynamic>) {
      return car['carImageUrl']?.toString();
    }
    if (json['carImageUrl'] != null) {
      return json['carImageUrl'].toString();
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      // Parse ISO 8601 string (e.g., "2025-12-25T04:00:00.000Z")
      // DateTime.tryParse handles UTC dates correctly (Z suffix)
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        // If the string ends with 'Z', it's UTC - ensure it's treated as UTC
        if (value.toUpperCase().endsWith('Z')) {
          return parsed.toUtc();
        }
        return parsed;
      }
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
