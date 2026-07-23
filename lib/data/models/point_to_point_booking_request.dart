import 'card_details.dart';
import 'payment_method_type.dart';
import 'selected_extra_option.dart';
import 'square_payment_payload.dart';

class PointToPointBookingRequest {
  PointToPointBookingRequest({
    required this.tripType,
    required this.pickupPhysicalAddress,
    required this.pickupLongitude,
    required this.pickupLatitude,
    required this.dropoffPhysicalAddress,
    required this.dropoffLongitude,
    required this.dropoffLatitude,
    required this.distanceInMiles,
    required this.numberOfPassengers,
    required this.numberOfSuitcases,
    required this.pickupDateTime,
    this.returnPickupDateTime,
    this.specialInstructions,
    required this.bookingFor,
    this.additionalStopId,
    this.additionalStopOnTheWayDescription,
    required this.passengerFullName,
    required this.passengerEmail,
    required this.gratuityId,
    required this.isGuestBooking,
    required this.passengerCellPhone,
    required this.carId,
    this.extraOptions = const <SelectedExtraOption>[],
    required this.paymentMethod,
    this.paymentDetailId,
    this.cardDetails,
    this.square,
    this.squareCardId,
    this.sidePicks = const <Map<String, dynamic>>[],
  });

  final String tripType;
  final String pickupPhysicalAddress;
  final double pickupLongitude;
  final double pickupLatitude;
  final String dropoffPhysicalAddress;
  final double dropoffLongitude;
  final double dropoffLatitude;
  final double distanceInMiles;
  final int numberOfPassengers;
  final int numberOfSuitcases;
  final String pickupDateTime;
  final String? returnPickupDateTime;
  final String? specialInstructions;
  final String bookingFor;
  final int? additionalStopId;
  final String? additionalStopOnTheWayDescription;
  final String passengerFullName;
  final String passengerEmail;
  final int gratuityId;
  final bool isGuestBooking;
  final String passengerCellPhone;
  final int carId;
  final List<SelectedExtraOption> extraOptions;
  final PaymentMethodType paymentMethod;
  final int? paymentDetailId;
  final CardDetails? cardDetails;
  final SquarePaymentPayload? square;
  final String? squareCardId;
  final List<Map<String, dynamic>> sidePicks;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'tripType': tripType,
      'pickupPhysicalAddress': pickupPhysicalAddress,
      'pickupLongitude': pickupLongitude,
      'pickupLatitude': pickupLatitude,
      'dropoffPhysicalAddress': dropoffPhysicalAddress,
      'dropoffLongitude': dropoffLongitude,
      'dropoffLatitude': dropoffLatitude,
      'distanceInMiles': distanceInMiles,
      'numberOfPassengers': numberOfPassengers,
      'numberOfSuitcases': numberOfSuitcases,
      'pickupDateTime': pickupDateTime,
      'bookingFor': bookingFor,
      'passengerFullName': passengerFullName,
      'passengerEmail': passengerEmail,
      'gratuityId': gratuityId,
      'isGuestBooking': isGuestBooking,
      'passengerCellPhone': passengerCellPhone,
      'carId': carId,
      'paymentMethod': paymentMethod.value,
    };

    if (returnPickupDateTime != null && returnPickupDateTime!.isNotEmpty) {
      data['returnPickupDateTime'] = returnPickupDateTime;
    }
    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      data['specialInstructions'] = specialInstructions;
    }
    if (additionalStopId != null && additionalStopId! > 0) {
      data['additionalStopId'] = additionalStopId;
      if (additionalStopOnTheWayDescription != null &&
          additionalStopOnTheWayDescription!.isNotEmpty) {
        data['additionalStopOnTheWayDescription'] =
            additionalStopOnTheWayDescription;
      }
    }
    if (extraOptions.isNotEmpty) {
      data['extraOptions'] = extraOptions.map((e) => e.toJson()).toList();
    }
    if (sidePicks.isNotEmpty) {
      data['sidePicks'] = sidePicks;
    }
    if (paymentMethod == PaymentMethodType.existingCard && paymentDetailId != null) {
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

