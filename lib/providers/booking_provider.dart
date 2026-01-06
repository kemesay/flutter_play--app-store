import 'package:flutter/foundation.dart';

import '../data/models/booking_history_item.dart';
import '../data/models/travel_type.dart';
import '../data/services/booking_service.dart';
import '../data/models/point_to_point_booking_request.dart';
import '../data/models/airport_booking_request.dart';
import '../data/models/hourly_charter_booking_request.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({BookingService? bookingService})
      : _bookingService = bookingService ?? BookingService();

  final BookingService _bookingService;

  TravelType _selectedTravelType = TravelType.airport;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  String? _successMessage;
  List<BookingHistoryItem> _bookings = const [];

  TravelType get selectedTravelType => _selectedTravelType;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<BookingHistoryItem> get bookings => _bookings;

  void setTravelType(TravelType travelType) {
    if (_selectedTravelType == travelType) return;
    _selectedTravelType = travelType;
    notifyListeners();
  }

  Future<void> refreshBookings() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _bookings = await _bookingService.fetchUserBookings();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<bool> submitPointToPointBooking(
    PointToPointBookingRequest request, {
    required bool authenticated,
  }) async {
    return _submitBooking(
      () => _bookingService.createPointToPointBooking(
        request,
        authenticated: authenticated,
      ),
    );
  }

  Future<bool> submitAirportBooking(
    AirportBookingRequest request, {
    required bool authenticated,
  }) async {
    return _submitBooking(
      () => _bookingService.createAirportBooking(
        request,
        authenticated: authenticated,
      ),
    );
  }

  Future<bool> submitHourlyCharterBooking(
    HourlyCharterBookingRequest request, {
    required bool authenticated,
  }) async {
    return _submitBooking(
      () => _bookingService.createHourlyCharterBooking(
        request,
        authenticated: authenticated,
      ),
    );
  }

  Future<bool> _submitBooking(
    Future<Map<String, dynamic>> Function() submitFn,
  ) async {
    _isSubmitting = true;
    _successMessage = null;
    notifyListeners();
    try {
      final response = await submitFn();
      final confirmation = response['confirmationNumber']?.toString();
      if (confirmation != null && confirmation.isNotEmpty) {
        _successMessage =
            'Booking confirmed! Confirmation #$confirmation has been emailed to you.';
      } else {
        _successMessage = 'Booking submitted successfully.';
      }
      _errorMessage = null;
      await refreshBookings();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _successMessage = null;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
