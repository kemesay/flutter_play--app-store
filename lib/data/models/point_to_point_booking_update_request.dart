import 'selected_extra_option.dart';

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
    return data;
  }
}
