import '../models/booking_history_item.dart';
import '../models/selected_extra_option.dart';
import '../../model/place_model.dart';

/// Editable snapshot built from GET `/users/bookings/mine` item payloads.
class BookingEditFormData {
  BookingEditFormData({
    required this.bookingId,
    required this.type,
    required this.tripType,
    required this.bookingFor,
    required this.passengerFullName,
    required this.passengerEmail,
    required this.passengerCellPhone,
    required this.numberOfPassengers,
    required this.numberOfSuitcases,
    required this.pickupDateTime,
    this.returnPickupDateTime,
    this.specialInstructions,
    this.distanceInMiles,
    this.carId,
    this.gratuityId,
    this.additionalStopId,
    this.additionalStopDescription,
    this.extraOptions = const [],
    this.airportLocationAddress,
    this.airportLocationLatitude,
    this.airportLocationLongitude,
    this.accommodationAddress,
    this.accommodationLatitude,
    this.accommodationLongitude,
    this.airline,
    this.arrivalFlightNumber,
    this.returnAirline,
    this.returnFlightNumber,
    this.pickupPreferenceId,
    this.pickupPhysicalAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffPhysicalAddress,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.selectedHours,
    this.occasion,
  });

  final int bookingId;
  final BookingType type;
  final String tripType;
  final String bookingFor;
  final String passengerFullName;
  final String passengerEmail;
  final String passengerCellPhone;
  final int numberOfPassengers;
  final int numberOfSuitcases;
  final DateTime pickupDateTime;
  final DateTime? returnPickupDateTime;
  final String? specialInstructions;
  final double? distanceInMiles;
  final int? carId;
  final int? gratuityId;
  final int? additionalStopId;
  final String? additionalStopDescription;
  final List<SelectedExtraOption> extraOptions;

  // Airport
  final String? airportLocationAddress;
  final double? airportLocationLatitude;
  final double? airportLocationLongitude;
  final String? accommodationAddress;
  final double? accommodationLatitude;
  final double? accommodationLongitude;
  final String? airline;
  final String? arrivalFlightNumber;
  final String? returnAirline;
  final String? returnFlightNumber;
  final int? pickupPreferenceId;

  // Point-to-point / hourly
  final String? pickupPhysicalAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? dropoffPhysicalAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final int? selectedHours;
  final String? occasion;

  PlaceDetail? get airportPlaceDetail {
    if (airportLocationAddress == null ||
        airportLocationLatitude == null ||
        airportLocationLongitude == null) {
      return null;
    }
    return PlaceDetail(
      placeId: 'booking-airport-$bookingId',
      formattedAddress: airportLocationAddress!,
      lat: airportLocationLatitude!,
      lng: airportLocationLongitude!,
      countryCode: 'US',
      administrativeAreaShortName: 'CA',
    );
  }

  PlaceDetail? get accommodationPlaceDetail {
    if (accommodationAddress == null ||
        accommodationLatitude == null ||
        accommodationLongitude == null) {
      return null;
    }
    return PlaceDetail(
      placeId: 'booking-accommodation-$bookingId',
      formattedAddress: accommodationAddress!,
      lat: accommodationLatitude!,
      lng: accommodationLongitude!,
      countryCode: 'US',
    );
  }

  PlaceDetail? get pickupPlaceDetail {
    final address = pickupPhysicalAddress;
    if (address == null || pickupLatitude == null || pickupLongitude == null) {
      return null;
    }
    return PlaceDetail(
      placeId: 'booking-pickup-$bookingId',
      formattedAddress: address,
      lat: pickupLatitude!,
      lng: pickupLongitude!,
      countryCode: 'US',
      administrativeAreaShortName: 'CA',
    );
  }

  PlaceDetail? get dropoffPlaceDetail {
    final address = dropoffPhysicalAddress;
    if (address == null || dropoffLatitude == null || dropoffLongitude == null) {
      return null;
    }
    return PlaceDetail(
      placeId: 'booking-dropoff-$bookingId',
      formattedAddress: address,
      lat: dropoffLatitude!,
      lng: dropoffLongitude!,
      countryCode: 'US',
    );
  }

  bool get isRoundTrip =>
      tripType.toLowerCase().contains('round trip') ||
      tripType == 'Round-Trip';
}

class BookingUpdateMapper {
  const BookingUpdateMapper._();

  static BookingEditFormData fromBooking(BookingHistoryItem booking) {
    final json = booking.rawData;
    final type = booking.type;

    return BookingEditFormData(
      bookingId: booking.id,
      type: type,
      tripType: json['tripType']?.toString() ??
          (type == BookingType.hourlyCharter ? 'Hourly' : 'One-Way'),
      bookingFor: json['bookingFor']?.toString() ?? 'Myself',
      passengerFullName: json['passengerFullName']?.toString() ?? '',
      passengerEmail: json['passengerEmail']?.toString() ?? '',
      passengerCellPhone: json['passengerCellPhone']?.toString() ?? '',
      numberOfPassengers: _parseInt(json['numberOfPassengers'], fallback: 1),
      numberOfSuitcases: _parseInt(json['numberOfSuitcases']),
      pickupDateTime: _parseDate(json['pickupDateTime']) ?? DateTime.now(),
      returnPickupDateTime: _parseDate(json['returnPickupDateTime']),
      specialInstructions: json['specialInstructions']?.toString(),
      distanceInMiles: _parseDouble(json['distanceInMiles']),
      carId: _resolveCarId(json),
      gratuityId: _resolveGratuityId(json),
      additionalStopId: _resolveAdditionalStopId(json),
      additionalStopDescription:
          json['additionalStopOnTheWayDescription']?.toString(),
      extraOptions: _resolveExtraOptions(json),
      airportLocationAddress: json['airportLocationAddress']?.toString(),
      airportLocationLatitude: _parseDouble(json['airportLocationLatitude']),
      airportLocationLongitude: _parseDouble(json['airportLocationLongitude']),
      accommodationAddress: json['accommodationAddress']?.toString(),
      accommodationLatitude: _parseDouble(json['accommodationLatitude']),
      accommodationLongitude: _parseDouble(json['accommodationLongitude']),
      airline: json['airline']?.toString(),
      arrivalFlightNumber: json['arrivalFlightNumber']?.toString(),
      returnAirline: json['returnAirline']?.toString(),
      returnFlightNumber: json['returnFlightNumber']?.toString(),
      pickupPreferenceId: _resolvePickupPreferenceId(json),
      pickupPhysicalAddress: json['pickupPhysicalAddress']?.toString() ??
          json['pickupLocation']?.toString(),
      pickupLatitude: _parseDouble(json['pickupLatitude']),
      pickupLongitude: _parseDouble(json['pickupLongitude']),
      dropoffPhysicalAddress: json['dropoffPhysicalAddress']?.toString() ??
          json['destination']?.toString(),
      dropoffLatitude: _parseDouble(json['dropoffLatitude']),
      dropoffLongitude: _parseDouble(json['dropoffLongitude']),
      selectedHours: _parseInt(json['selectedHours'], fallback: 5),
      occasion: _normalizeOccasion(json['occasion']?.toString()),
    );
  }

  /// Canonical occasion labels used by hourly charter forms and PATCH bodies.
  static const List<String> hourlyOccasionOptions = [
    'Wedding',
    'Tour',
    'Promotion',
    'Graduation',
    'Concert',
  ];

  static String _normalizeOccasion(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Wedding';
    final normalized = raw.trim().toLowerCase();
    for (final option in hourlyOccasionOptions) {
      if (option.toLowerCase() == normalized) return option;
    }
    return 'Wedding';
  }

  static int? _resolveCarId(Map<String, dynamic> json) {
    final direct = _parseIntOrNull(json['carId']);
    if (direct != null && direct > 0) return direct;
    final car = json['Car'];
    if (car is Map<String, dynamic>) {
      return _parseIntOrNull(car['carId']);
    }
    return null;
  }

  static int? _resolveGratuityId(Map<String, dynamic> json) {
    final direct = _parseIntOrNull(json['gratuityId']);
    if (direct != null && direct > 0) return direct;
    final gratuity = json['Gratuity'];
    if (gratuity is Map<String, dynamic>) {
      return _parseIntOrNull(gratuity['gratuityId']);
    }
    return null;
  }

  static int? _resolveAdditionalStopId(Map<String, dynamic> json) {
    final direct = _parseIntOrNull(json['additionalStopId']);
    if (direct != null && direct > 0) return direct;
    final stop = json['AdditionalStopOnTheWay'];
    if (stop is Map<String, dynamic>) {
      return _parseIntOrNull(stop['additionalStopId']);
    }
    return null;
  }

  static int? _resolvePickupPreferenceId(Map<String, dynamic> json) {
    final direct = _parseIntOrNull(json['pickupPreferenceId']);
    if (direct != null && direct > 0) return direct;
    final pref = json['AirportPickupPreference'] ?? json['PickupPreference'];
    if (pref is Map<String, dynamic>) {
      return _parseIntOrNull(pref['pickupPreferenceId']);
    }
    return null;
  }

  static List<SelectedExtraOption> _resolveExtraOptions(
    Map<String, dynamic> json,
  ) {
    final raw = json['ExtraOptions'];
    if (raw is! List) return const [];

    final parsed = <SelectedExtraOption>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      int? extraOptionId = _parseIntOrNull(map['extraOptionId']);
      extraOptionId ??= _parseIntOrNull(map['ExtraOption']?['extraOptionId']);

      int quantity = 1;
      for (final key in [
        'quantity',
        'AirportBookExtraOption',
        'PointToPointBookExtraOption',
        'HourlyCharterBookExtraOption',
      ]) {
        final nested = map[key];
        if (nested is Map) {
          quantity = _parseInt(nested['quantity'], fallback: 1);
          break;
        }
        if (key == 'quantity' && nested != null) {
          quantity = _parseInt(nested, fallback: 1);
          break;
        }
      }

      if (extraOptionId != null && extraOptionId > 0) {
        parsed.add(
          SelectedExtraOption(extraOptionId: extraOptionId, quantity: quantity),
        );
      }
    }
    return parsed;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    return _parseIntOrNull(value) ?? fallback;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
