class CarModel {
  const CarModel({
    required this.carId,
    required this.carName,
    required this.carDescription,
    this.carImageUrl,
    required this.maxPassengers,
    required this.maxSuitcases,
    required this.carType,
    required this.pricePerMile,
    required this.pricePerHour,
    required this.minimumStartFee,
    this.currency = 'USD',
    this.engineType,
    this.length,
    this.interiorColor,
    this.exteriorColor,
    this.power,
    this.transmissionType,
    this.fuelType,
    this.extras,
  });

  final int carId;
  final String carName;
  final String carDescription;
  final String? carImageUrl;
  final int maxPassengers;
  final int maxSuitcases;
  final String carType;
  final double pricePerMile;
  final double pricePerHour;
  final double minimumStartFee;
  final String currency;
  final String? engineType;
  final double? length;
  final String? interiorColor;
  final String? exteriorColor;
  final String? power;
  final String? transmissionType;
  final String? fuelType;
  final String? extras;

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      carId: _parseInt(json['carId']),
      carName: json['carName']?.toString() ?? '',
      carDescription: json['carDescription']?.toString() ?? '',
      carImageUrl: json['carImageUrl']?.toString(),
      maxPassengers: _parseInt(json['maxPassengers']),
      maxSuitcases: _parseInt(json['maxSuitcases']),
      carType: json['carType']?.toString() ?? '',
      pricePerMile: _parseDouble(json['pricePerMile']),
      pricePerHour: _parseDouble(json['pricePerHour']),
      minimumStartFee: _parseDouble(json['minimumStartFee']),
      currency: json['currency']?.toString() ?? 'USD',
      engineType: json['engineType']?.toString(),
      length: _parseNullableDouble(json['length']),
      interiorColor: json['interiorColor']?.toString(),
      exteriorColor: json['exteriorColor']?.toString(),
      power: json['power']?.toString(),
      transmissionType: json['transmissionType']?.toString(),
      fuelType: json['fuelType']?.toString(),
      extras: json['extras']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carId': carId,
      'carName': carName,
      'carDescription': carDescription,
      'carImageUrl': carImageUrl,
      'maxPassengers': maxPassengers,
      'maxSuitcases': maxSuitcases,
      'carType': carType,
      'pricePerMile': pricePerMile,
      'pricePerHour': pricePerHour,
      'minimumStartFee': minimumStartFee,
      'currency': currency,
      'engineType': engineType,
      'length': length,
      'interiorColor': interiorColor,
      'exteriorColor': exteriorColor,
      'power': power,
      'transmissionType': transmissionType,
      'fuelType': fuelType,
      'extras': extras,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

