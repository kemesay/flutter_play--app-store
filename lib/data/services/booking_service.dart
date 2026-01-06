import '../../core/network/api_client.dart';
import '../models/airport_booking_request.dart';
import '../models/booking_history_item.dart';
import '../models/hourly_charter_booking_request.dart';
import '../models/point_to_point_booking_request.dart';

class BookingService {
  BookingService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createPointToPointBooking(
    PointToPointBookingRequest request, {
    required bool authenticated,
  }) async {
    final response = await _apiClient.post(
      '/point-to-point-books',
      authenticated: authenticated,
      body: request.toJson(),
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> createAirportBooking(
    AirportBookingRequest request, {
    required bool authenticated,
  }) async {
    final response = await _apiClient.post(
      '/airport-books',
      authenticated: authenticated,
      body: request.toJson(),
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> createHourlyCharterBooking(
    HourlyCharterBookingRequest request, {
    required bool authenticated,
  }) async {
    final response = await _apiClient.post(
      '/hourly-charter-books',
      authenticated: authenticated,
      body: request.toJson(),
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'success': true};
  }

  Future<List<BookingHistoryItem>> fetchUserBookings() async {
    final response = await _apiClient.get(
      '/users/bookings/mine',
      authenticated: true,
    );

    if (response is! Map<String, dynamic>) return [];

    final pointToPoint = response['pointToPointBookings'] as List<dynamic>? ?? const [];
    final hourly = response['hourlyCharterBookings'] as List<dynamic>? ?? const [];
    final airport = response['airportBookings'] as List<dynamic>? ?? const [];

    final bookings = <BookingHistoryItem>[];

    bookings.addAll(
      pointToPoint
          .whereType<Map<String, dynamic>>()
          .map(BookingHistoryItem.fromJson),
    );

    bookings.addAll(
      airport
          .whereType<Map<String, dynamic>>()
          .map(BookingHistoryItem.fromJson),
    );

    bookings.addAll(
      hourly
          .whereType<Map<String, dynamic>>()
          .map(BookingHistoryItem.fromJson),
    );

    bookings.sort((a, b) {
      final aDate = a.pickupDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.pickupDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return bookings;
  }
}

