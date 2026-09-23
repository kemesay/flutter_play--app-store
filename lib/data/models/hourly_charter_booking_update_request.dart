import 'selected_extra_option.dart';
import 'square_payment_payload.dart';

class HourlyCharterBookingUpdateRequest {
  HourlyCharterBookingUpdateRequest({
    required this.pickupPhysicalAddress,
    required this.pickupLongitude,
    required this.pickupLatitude,
    required this.dropoffPhysicalAddress,
    required this.dropoffLongitude,
    required this.dropoffLatitude,
    required this.selectedHours,
    required this.occasion,
    required this.numberOfPassengers,
    required this.numberOfSuitcases,
    required this.pickupDateTime,
    this.specialInstructions,
    required this.bookingFor,
    required this.passengerFullName,
    required this.passengerCellPhone,
    required this.passengerEmail,
    required this.carId,
    required this.gratuityId,
    this.extraOptions = const <SelectedExtraOption>[],
    this.promoCode,
    this.square,
    this.squareCardId,
    this.paymentDetailId,
  });

  final String pickupPhysicalAddress;
  final double pickupLongitude;
  final double pickupLatitude;
  final String dropoffPhysicalAddress;
  final double dropoffLongitude;
  final double dropoffLatitude;
  final int selectedHours;
  final String occasion;
  final int numberOfPassengers;
  final int numberOfSuitcases;
  final String pickupDateTime;
  final String? specialInstructions;
  final String bookingFor;
  final String passengerFullName;
  final String passengerCellPhone;
  final String passengerEmail;
  final int carId;
  final int gratuityId;
  final List<SelectedExtraOption> extraOptions;
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
      'pickupPhysicalAddress': pickupPhysicalAddress,
      'pickupLongitude': pickupLongitude,
      'pickupLatitude': pickupLatitude,
      'dropoffPhysicalAddress': dropoffPhysicalAddress,
      'dropoffLongitude': dropoffLongitude,
      'dropoffLatitude': dropoffLatitude,
      'selectedHours': selectedHours,
      'occasion': occasion,
      'numberOfPassengers': numberOfPassengers,
      'numberOfSuitcases': numberOfSuitcases,
      'pickupDateTime': pickupDateTime,
      'bookingFor': bookingFor,
      'passengerFullName': passengerFullName,
      'passengerCellPhone': passengerCellPhone,
      'passengerEmail': passengerEmail,
      'carId': carId,
      'gratuityId': gratuityId,
    };

    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      data['specialInstructions'] = specialInstructions;
    }
    if (extraOptions.isNotEmpty) {
      data['extraOptions'] = extraOptions.map((e) => e.toJson()).toList();
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
