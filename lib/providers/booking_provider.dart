import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/exceptions/api_exception.dart';
import '../core/realtime/socket_client_service.dart';
import '../core/utils/payment_status_map.dart';
import '../data/models/airport_booking_request.dart';
import '../data/models/airport_booking_update_request.dart';
import '../data/models/booking_history_item.dart';
import '../data/models/hourly_charter_booking_request.dart';
import '../data/models/hourly_charter_booking_update_request.dart';
import '../data/models/point_to_point_booking_request.dart';
import '../data/models/point_to_point_booking_update_request.dart';
import '../data/models/travel_type.dart';
import '../data/services/booking_realtime_token_service.dart';
import '../data/services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({
    BookingService? bookingService,
    BookingRealtimeTokenService? realtimeTokenService,
  })  : _bookingService = bookingService ?? BookingService(),
        _realtimeTokenService =
            realtimeTokenService ?? BookingRealtimeTokenService();

  final BookingService _bookingService;
  final BookingRealtimeTokenService _realtimeTokenService;
  StreamSubscription<PaymentTransactionUpdatedEvent>? _paymentTxSub;
  final Set<String> _joinedRoomTokens = {};
  bool _disposed = false;

  TravelType _selectedTravelType = TravelType.airport;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;
  String? _successMessage;
  // Kept separate from `_errorMessage`: a background history refresh (or its
  // realtime-room wiring) failing right after a successful booking must
  // never overwrite the success message the user is already seeing.
  String? _historyErrorMessage;
  List<BookingHistoryItem> _bookings = const [];

  TravelType get selectedTravelType => _selectedTravelType;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get historyErrorMessage => _historyErrorMessage;
  List<BookingHistoryItem> get bookings => _bookings;

  void setTravelType(TravelType travelType) {
    if (_selectedTravelType == travelType) return;
    _selectedTravelType = travelType;
    _notify();
  }

  Future<void> refreshBookings() async {
    if (_disposed) return;
    _isLoadingHistory = true;
    _notify();
    try {
      _bookings = await _bookingService.fetchUserBookings();
      _historyErrorMessage = null;
      await _wireActiveBookingsRealtime();
    } catch (error) {
      _historyErrorMessage = _formatError(error);
    } finally {
      _isLoadingHistory = false;
      _notify();
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

  Future<bool> updateAirportBooking(
    int bookingId,
    AirportBookingUpdateRequest request,
  ) async {
    return _updateBooking(
      () => _bookingService.updateAirportBooking(bookingId, request),
    );
  }

  Future<bool> updatePointToPointBooking(
    int bookingId,
    PointToPointBookingUpdateRequest request,
  ) async {
    return _updateBooking(
      () => _bookingService.updatePointToPointBooking(bookingId, request),
    );
  }

  Future<bool> updateHourlyCharterBooking(
    int bookingId,
    HourlyCharterBookingUpdateRequest request,
  ) async {
    return _updateBooking(
      () => _bookingService.updateHourlyCharterBooking(bookingId, request),
    );
  }

  Future<bool> _updateBooking(
    Future<Map<String, dynamic>> Function() updateFn,
  ) async {
    _isSubmitting = true;
    _successMessage = null;
    _notify();
    try {
      await updateFn();
      _successMessage = 'Booking updated successfully.';
      _errorMessage = null;
      await refreshBookings();
      return true;
    } catch (error) {
      _errorMessage = _formatSubmissionError(error);
      _successMessage = null;
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<bool> _submitBooking(
    Future<Map<String, dynamic>> Function() submitFn,
  ) async {
    _isSubmitting = true;
    _successMessage = null;
    _notify();
    try {
      final response = await submitFn();
      _joinBookingRoomFromResponse(response);
      final confirmation = response['confirmationNumber']?.toString();
      final paymentStatus = response['paymentStatus']?.toString();
      if (confirmation != null && confirmation.isNotEmpty) {
        if (paymentStatus == 'AUTHORIZED') {
          _successMessage =
              'Booking confirmed! Confirmation #$confirmation. Your card is authorized — payment will be captured when the trip is completed.';
        } else if (paymentStatus == 'PAID') {
          _successMessage =
              'Booking confirmed and paid! Confirmation #$confirmation has been emailed to you.';
        } else {
          _successMessage =
              'Booking confirmed! Confirmation #$confirmation has been emailed to you.';
        }
      } else {
        _successMessage = paymentStatus == 'AUTHORIZED'
            ? 'Booking submitted. Your card is authorized for this trip.'
            : 'Booking submitted successfully.';
      }
      _errorMessage = null;
      await refreshBookings();
      return true;
    } catch (error) {
      _errorMessage = _formatSubmissionError(error);
      _successMessage = null;
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  /// Like [_formatError], but for a create/update call specifically: a
  /// client-side timeout there doesn't mean the operation was rejected — the
  /// server may have gone on to complete it — so tell the user to check
  /// before resubmitting rather than implying it's safe to just try again.
  static String _formatSubmissionError(Object error) {
    if (error is ApiException && error.isTimeout) {
      return "We didn't hear back in time, but your booking may have gone "
          'through. Please check your trip history before submitting again.';
    }
    return _formatError(error);
  }

  void _joinBookingRoomFromResponse(Map<String, dynamic> bookingResponse) {
    try {
      final realtime = bookingResponse['realtime'];
      if (realtime is! Map) return;
      final map = realtime.map((k, v) => MapEntry(k.toString(), v));

      final provider = (map['provider'] ?? '').toString();
      final event = (map['event'] ?? '').toString();
      final roomToken = (map['roomToken'] ?? '').toString();
      if (provider != 'socket.io' ||
          event != 'payment.transaction.updated' ||
          roomToken.isEmpty) {
        return;
      }

      _joinRoomToken(roomToken);
      _ensurePaymentListener();
    } catch (_) {
      // Don't block booking flow on realtime wiring.
    }
  }

  Future<void> _wireActiveBookingsRealtime() async {
    _ensurePaymentListener();

    for (final booking in _bookings) {
      if (isPaymentSettled(booking.paymentStatus)) continue;
      if (booking.id <= 0) continue;

      final token = await _realtimeTokenService.fetchRoomToken(
        bookingType: booking.type,
        bookingId: booking.id,
      );
      if (token != null && token.isNotEmpty) {
        _joinRoomToken(token);
      }
    }
  }

  void _joinRoomToken(String roomToken) {
    if (_joinedRoomTokens.contains(roomToken)) return;
    SocketClientService.instance.joinBookingRoom(roomToken: roomToken);
    _joinedRoomTokens.add(roomToken);
  }

  void _ensurePaymentListener() {
    if (_paymentTxSub != null) return;
    SocketClientService.instance.ensureConnected();
    _paymentTxSub =
        SocketClientService.instance.paymentTransactionUpdated.listen(
      _handlePaymentTransactionUpdated,
    );
  }

  void _handlePaymentTransactionUpdated(PaymentTransactionUpdatedEvent event) {
    if (_disposed || event.bookingId <= 0) return;

    final mappedStatus = mapTransactionStatusToPaymentStatus(event.status);
    var changed = false;

    _bookings = _bookings.map((booking) {
      if (booking.id != event.bookingId) return booking;
      if (!_eventMatchesBooking(event, booking)) return booking;
      if (booking.paymentStatus == mappedStatus) return booking;
      changed = true;
      return booking.copyWith(paymentStatus: mappedStatus);
    }).toList(growable: false);

    if (changed) _notify();
  }

  bool _eventMatchesBooking(
    PaymentTransactionUpdatedEvent event,
    BookingHistoryItem booking,
  ) {
    final expected =
        BookingRealtimeTokenService.ledgerBookingType(booking.type);
    return event.bookingType.toUpperCase() == expected;
  }

  static String _formatError(Object error) {
    if (error is ApiException) return error.message;
    final text = error.toString();
    const maxLen = 240;
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}…';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _paymentTxSub?.cancel();
    super.dispose();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _notify();
  }

  /// Tears down the realtime wiring tied to the just-ended session (room
  /// subscriptions, the payment-update listener, the socket itself), so the
  /// next login starts a genuinely fresh connection instead of silently
  /// reusing one still subscribed to the previous user's booking rooms.
  void resetRealtimeState() {
    _paymentTxSub?.cancel();
    _paymentTxSub = null;
    _joinedRoomTokens.clear();
    SocketClientService.instance.reset();
  }
}
