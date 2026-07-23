import 'card_details.dart';
import 'payment_method_type.dart';
import 'selected_extra_option.dart';
import 'square_payment_payload.dart';

class AirportBookingRequest {
  AirportBookingRequest({
    required this.tripType,
    required this.airportLocationAddress,
    required this.airportLocationLatitude,
    required this.airportLocationLongitude,
    required this.numberOfPassengers,
    required this.numberOfSuitcases,
    required this.accommodationAddress,
    required this.accommodationLongitude,
    required this.accommodationLatitude,
    required this.pickupDateTime,
    this.returnPickupDateTime,
    this.airline,
    this.arrivalFlightNumber,
    this.returnAirline,
    this.returnFlightNumber,
    required this.distanceInMiles,
    required this.carId,
    this.additionalStopId,
    this.additionalStopOnTheWayDescription,
    this.pickupPreferenceId,
    this.extraOptions = const <SelectedExtraOption>[],
    required this.bookingFor,
    required this.passengerFullName,
    required this.passengerCellPhone,
    required this.passengerEmail,
    required this.gratuityId,
    required this.isGuestBooking,
    required this.paymentMethod,
    this.paymentDetailId,
    this.cardDetails,
    this.square,
    this.squareCardId,
    this.specialInstructions,
    this.sidePicks = const <Map<String, dynamic>>[],
  });

  final String tripType;
  final String airportLocationAddress;
  final double airportLocationLatitude;
  final double airportLocationLongitude;
  final int numberOfPassengers;
  final int numberOfSuitcases;
  final String accommodationAddress;
  final double accommodationLongitude;
  final double accommodationLatitude;
  final String pickupDateTime;
  final String? returnPickupDateTime;
  final String? airline;
  final String? arrivalFlightNumber;
  final String? returnAirline;
  final String? returnFlightNumber;
  final double distanceInMiles;
  final int carId;
  final int? additionalStopId;
  final String? additionalStopOnTheWayDescription;
  final int? pickupPreferenceId;
  final List<SelectedExtraOption> extraOptions;
  final String bookingFor;
  final String passengerFullName;
  final String passengerCellPhone;
  final String passengerEmail;
  final int gratuityId;
  final bool isGuestBooking;
  final PaymentMethodType paymentMethod;
  final int? paymentDetailId;
  final CardDetails? cardDetails;
  final SquarePaymentPayload? square;
  final String? squareCardId;
  final String? specialInstructions;
  final List<Map<String, dynamic>> sidePicks;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'tripType': tripType,
      'airportLocationAddress': airportLocationAddress,
      'airportLocationLatitude': airportLocationLatitude,
      'airportLocationLongitude': airportLocationLongitude,
      'numberOfPassengers': numberOfPassengers,
      'numberOfSuitcases': numberOfSuitcases,
      'accommodationAddress': accommodationAddress,
      'accommodationLongitude': accommodationLongitude,
      'accommodationLatitude': accommodationLatitude,
      'pickupDateTime': pickupDateTime,
      'distanceInMiles': distanceInMiles,
      'carId': carId,
      'bookingFor': bookingFor,
      'passengerFullName': passengerFullName,
      'passengerCellPhone': passengerCellPhone,
      'passengerEmail': passengerEmail,
      'gratuityId': gratuityId,
      'isGuestBooking': isGuestBooking,
      'paymentMethod': paymentMethod.value,
    };

    if (returnPickupDateTime != null && returnPickupDateTime!.isNotEmpty) {
      data['returnPickupDateTime'] = returnPickupDateTime;
    }
    if (airline != null && airline!.isNotEmpty) {
      data['airline'] = airline;
    }
    if (arrivalFlightNumber != null && arrivalFlightNumber!.isNotEmpty) {
      data['arrivalFlightNumber'] = arrivalFlightNumber;
    }
    if (returnAirline != null && returnAirline!.isNotEmpty) {
      data['returnAirline'] = returnAirline;
    }
    if (returnFlightNumber != null && returnFlightNumber!.isNotEmpty) {
      data['returnFlightNumber'] = returnFlightNumber;
    }
    if (additionalStopId != null && additionalStopId! > 0) {
      data['additionalStopId'] = additionalStopId;
      if (additionalStopOnTheWayDescription != null &&
          additionalStopOnTheWayDescription!.isNotEmpty) {
        data['additionalStopOnTheWayDescription'] =
            additionalStopOnTheWayDescription;
      }
    }
    if (pickupPreferenceId != null) {
      data['pickupPreferenceId'] = pickupPreferenceId;
    }
    if (extraOptions.isNotEmpty) {
      data['extraOptions'] = extraOptions.map((e) => e.toJson()).toList();
    }
    if (sidePicks.isNotEmpty) {
      data['sidePicks'] = sidePicks;
    }
    if (paymentDetailId != null &&
        paymentMethod == PaymentMethodType.existingCard) {
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
    if (cardDetails != null && paymentMethod == PaymentMethodType.newCard) {
      data['cardDetails'] = cardDetails!.toJson();
    }
    if (square != null && paymentMethod == PaymentMethodType.squareNewCard) {
      data['square'] = square!.toJson();
    }
    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      data['specialInstructions'] = specialInstructions;
    }

    return data;
  }
}

