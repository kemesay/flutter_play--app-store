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
    return data;
  }
}
