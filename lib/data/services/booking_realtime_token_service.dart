import '../../core/network/api_client.dart';
import '../models/booking_history_item.dart';

class BookingRealtimeTokenService {
  BookingRealtimeTokenService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<String?> fetchRoomToken({
    required BookingType bookingType,
    required int bookingId,
  }) async {
    final segment = _realtimePathSegment(bookingType);
    if (segment == null || bookingId <= 0) return null;

    try {
      final response = await _apiClient.get(
        '/users/bookings/mine/realtime/$segment/$bookingId',
        authenticated: true,
      );
      if (response is Map<String, dynamic>) {
        final token = response['roomToken']?.toString();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {
      // Realtime is optional — callers fall back to polling refresh.
    }
    return null;
  }

  static String? _realtimePathSegment(BookingType type) {
    switch (type) {
      case BookingType.airport:
        return 'airport';
      case BookingType.pointToPoint:
        return 'p2p';
      case BookingType.hourlyCharter:
        return 'hourly';
    }
  }

  static String ledgerBookingType(BookingType type) {
    switch (type) {
      case BookingType.airport:
        return 'AIRPORT';
      case BookingType.pointToPoint:
        return 'P2P';
      case BookingType.hourlyCharter:
        return 'HOURLY';
    }
  }
}
