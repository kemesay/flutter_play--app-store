import 'selected_extra_option.dart';
import 'square_payment_payload.dart';

class AirportBookingUpdateRequest {
  AirportBookingUpdateRequest({
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
    this.sidePicks = const <Map<String, dynamic>>[],
    required this.bookingFor,
    required this.passengerFullName,
    required this.passengerCellPhone,
    required this.passengerEmail,
    required this.gratuityId,
    this.specialInstructions,
    this.promoCode,
    this.square,
    this.squareCardId,
    this.paymentDetailId,
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
  // Always sent, even empty — unlike create, an update must be able to
  // clear stops the booking already has, not just add new ones.
  final List<Map<String, dynamic>> sidePicks;
  final String bookingFor;
  final String passengerFullName;
  final String passengerCellPhone;
  final String passengerEmail;
  final int gratuityId;
  final String? specialInstructions;
  // Null: customer never touched the promo box this session, leave whatever
  // is already applied untouched. "": customer removed it. Non-empty:
  // apply/replace. Only included in the JSON body when non-null.
  final String? promoCode;
  // Payment method — all three null unless the customer explicitly opened
  // "Change payment method" this session (see update_booking_page.dart).
  // `square` (a fresh Square nonce) means "charge a new card"; `squareCardId`
  // + `paymentDetailId` together mean "switch to this saved card." Never
  // both at once — the backend picks the effective method from whichever is
  // actually present.
  final SquarePaymentPayload? square;
  final String? squareCardId;
  final int? paymentDetailId;

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
    };

    if (returnPickupDateTime != null && returnPickupDateTime!.isNotEmpty) {
      data['returnPickupDateTime'] = returnPickupDateTime;
    }
    if (airline != null && airline!.isNotEmpty) data['airline'] = airline;
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
    data['sidePicks'] = sidePicks;
    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      data['specialInstructions'] = specialInstructions;
    }
    if (promoCode != null) {
      // Uppercase is the one canonical case for every promo code — the UI
      // already forces this, but normalized again here for defense in
      // depth (matches the create-request models' own model-level safety
      // net for this same field).
      data['promoCode'] = promoCode!.toUpperCase();
    }
    if (square != null) {
      data['square'] = square!.toJson();
    }
    if (squareCardId != null) {
      data['squareCardId'] = squareCardId;
    }
    if (paymentDetailId != null) {
      data['paymentDetailId'] = paymentDetailId;
    }
    return data;
  }
}
