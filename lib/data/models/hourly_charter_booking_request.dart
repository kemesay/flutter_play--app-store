import 'card_details.dart';
import 'payment_method_type.dart';
import 'selected_extra_option.dart';
import 'square_payment_payload.dart';

/// Billing mode for hourly charter bookings.
/// PRE_BOOKED: fixed charge = pricePerHour × selectedHours (default).
/// LIVE:       pre-authorizes booked hours + 2-hr buffer; driver ends the meter;
///             charge = max(booked hours, actual time used) × hourly rate —
///             the booked hours are a minimum charge, no overtime premium.
enum HourlyBillingMode {
  preBooked('PRE_BOOKED'),
  live('LIVE');

  const HourlyBillingMode(this.value);
  final String value;
}

class HourlyCharterBookingRequest {
  HourlyCharterBookingRequest({
    required this.pickupPhysicalAddress,
    required this.pickupLongitude,
    required this.pickupLatitude,
    required this.dropoffPhysicalAddress,
    required this.dropoffLongitude,
    required this.dropoffLatitude,
    required this.pickupDateTime,
    required this.selectedHours,
    required this.occasion,
    this.billingMode = HourlyBillingMode.preBooked,
    this.specialInstructions,
    required this.isGuestBooking,
    required this.bookingFor,
    required this.passengerFullName,
    required this.paymentMethod,
    required this.passengerCellPhone,
    required this.passengerEmail,
    required this.numberOfPassengers,
    required this.numberOfSuitcases,
    required this.gratuityId,
    required this.carId,
    this.extraOptions = const <SelectedExtraOption>[],
    this.paymentDetailId,
    this.cardDetails,
    this.square,
    this.squareCardId,
  });

  final String pickupPhysicalAddress;
  final double pickupLongitude;
  final double pickupLatitude;
  final String dropoffPhysicalAddress;
  final double dropoffLongitude;
  final double dropoffLatitude;
  final String pickupDateTime;
  final int selectedHours;
  final String occasion;
  final HourlyBillingMode billingMode;
  final String? specialInstructions;
  final bool isGuestBooking;
  final String bookingFor;
  final String passengerFullName;
  final PaymentMethodType paymentMethod;
  final String passengerCellPhone;
  final String passengerEmail;
  final int numberOfPassengers;
  final int numberOfSuitcases;
  final int gratuityId;
  final int carId;
  final List<SelectedExtraOption> extraOptions;
  final int? paymentDetailId;
  final CardDetails? cardDetails;
  final SquarePaymentPayload? square;
  final String? squareCardId;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'pickupPhysicalAddress': pickupPhysicalAddress,
      'pickupLongitude': pickupLongitude,
      'pickupLatitude': pickupLatitude,
      'dropoffPhysicalAddress': dropoffPhysicalAddress,
      'dropoffLongitude': dropoffLongitude,
      'dropoffLatitude': dropoffLatitude,
      'pickupDateTime': pickupDateTime,
      'selectedHours': selectedHours,
      'occasion': occasion,
      'billingMode': billingMode.value,
      'isGuestBooking': isGuestBooking,
      'bookingFor': bookingFor,
      'passengerFullName': passengerFullName,
      'paymentMethod': paymentMethod.value,
      'passengerCellPhone': passengerCellPhone,
      'passengerEmail': passengerEmail,
      'numberOfPassengers': numberOfPassengers,
      'numberOfSuitcases': numberOfSuitcases,
      'gratuityId': gratuityId,
      'carId': carId,
    };

    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      data['specialInstructions'] = specialInstructions;
    }
    if (extraOptions.isNotEmpty) {
      data['extraOptions'] = extraOptions.map((e) => e.toJson()).toList();
    }
    if (paymentMethod == PaymentMethodType.existingCard &&
        paymentDetailId != null) {
      data['paymentDetailId'] = paymentDetailId;
    }
    if (paymentMethod == PaymentMethodType.squareSavedCard) {
      if (paymentDetailId != null) {
        data['paymentDetailId'] = paymentDetailId;
      }
      if (squareCardId != null && squareCardId!.isNotEmpty) {
        data['squareCardId'] = squareCardId;
      }
    }
    if (paymentMethod == PaymentMethodType.newCard && cardDetails != null) {
      data['cardDetails'] = cardDetails!.toJson();
    }
    if (paymentMethod == PaymentMethodType.squareNewCard && square != null) {
      data['square'] = square!.toJson();
    }

    return data;
  }
}
