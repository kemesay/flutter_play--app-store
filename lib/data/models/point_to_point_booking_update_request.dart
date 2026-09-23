import 'selected_extra_option.dart';
import 'square_payment_payload.dart';

class PointToPointBookingUpdateRequest {
  PointToPointBookingUpdateRequest({
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
    required this.passengerFullName,
    required this.passengerEmail,
    required this.passengerCellPhone,
    this.additionalStopId,
    this.additionalStopOnTheWayDescription,
    required this.carId,
    required this.gratuityId,
    this.extraOptions = const <SelectedExtraOption>[],
    this.sidePicks = const <Map<String, dynamic>>[],
    this.promoCode,
    this.square,
    this.squareCardId,
    this.paymentDetailId,
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
  final String passengerFullName;
  final String passengerEmail;
  final String passengerCellPhone;
  final int? additionalStopId;
  final String? additionalStopOnTheWayDescription;
  final int carId;
  final int gratuityId;
  final List<SelectedExtraOption> extraOptions;
  // Always sent, even empty — unlike create, an update must be able to
  // clear stops the booking already has, not just add new ones.
  final List<Map<String, dynamic>> sidePicks;
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
      'passengerCellPhone': passengerCellPhone,
      'carId': carId,
      'gratuityId': gratuityId,
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
    data['sidePicks'] = sidePicks;
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
