import '../../core/network/api_client.dart';

class DriverService {
  DriverService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// All active trips (LIVE + PRE_BOOKED) that are ACCEPTED or EN_ROUTE.
  Future<List<dynamic>> getActiveDriverTrips() async {
    final data = await _apiClient.get(
      '/hourly-charter-books/driver/active-trips',
      authenticated: true,
    );
    if (data is List) return data;
    return [];
  }

  /// Fetch a single booking by ID.
  Future<Map<String, dynamic>> getBooking(int id) async {
    final data = await _apiClient.get(
      '/hourly-charter-books/$id',
      authenticated: true,
    );
    return data as Map<String, dynamic>;
  }

  /// Start the trip clock.
  /// Pass [convertToLive] = true to convert a PRE_BOOKED trip to live meter (Feature 2).
  Future<Map<String, dynamic>> startTrip(int id,
      {bool convertToLive = false}) async {
    final data = await _apiClient.patch(
      '/hourly-charter-books/$id/start-trip',
      body: {'convertToLive': convertToLive},
      authenticated: true,
    );
    return data as Map<String, dynamic>;
  }

  /// Extend a PRE_BOOKED trip with a live meter after the booked hours expire (Feature 1).
  Future<Map<String, dynamic>> extendLive(int id) async {
    final data = await _apiClient.patch(
      '/hourly-charter-books/$id/extend-live',
      authenticated: true,
    );
    return data as Map<String, dynamic>;
  }

  /// End the trip — calculates overtime / extension fare and reconciles payment.
  Future<Map<String, dynamic>> endTrip(int id) async {
    final data = await _apiClient.patch(
      '/hourly-charter-books/$id/end-trip',
      authenticated: true,
    );
    return data as Map<String, dynamic>;
  }

  /// Live status: elapsed time, running fare, overtime flag, mode.
  Future<Map<String, dynamic>> getLiveStatus(int id) async {
    final data = await _apiClient.get(
      '/hourly-charter-books/$id/live-status',
      authenticated: true,
    );
    return data as Map<String, dynamic>;
  }

  /// Past trips (COMPLETED/CANCELLED/REJECTED), paginated.
  /// Returns the pagination envelope: {pageNumber, pageSize, totalElements, totalPages, data}.
  Future<Map<String, dynamic>> getTripHistory(
      {int page = 1, int pageSize = 10}) async {
    final data = await _apiClient.get(
      '/hourly-charter-books/driver/history',
      queryParameters: {'page': '$page', 'pageSize': '$pageSize'},
      authenticated: true,
    );
    return data as Map<String, dynamic>;
  }
}
