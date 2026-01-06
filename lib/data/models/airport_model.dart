class AirportModel {
  const AirportModel({
    required this.airportId,
    required this.airportName,
    required this.airportAddress,
    required this.airportAddressLongitude,
    required this.airportAddressLatitude,
  });

  final int airportId;
  final String airportName;
  final String airportAddress;
  final double airportAddressLongitude;
  final double airportAddressLatitude;

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      airportId: _parseInt(json['airportId']),
      airportName: json['airportName']?.toString() ?? '',
      airportAddress: json['airportAddress']?.toString() ?? '',
      airportAddressLongitude: _parseDouble(json['airportAddressLongitude']),
      airportAddressLatitude: _parseDouble(json['airportAddressLatitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airportId': airportId,
      'airportName': airportName,
      'airportAddress': airportAddress,
      'airportAddressLongitude': airportAddressLongitude,
      'airportAddressLatitude': airportAddressLatitude,
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
}

