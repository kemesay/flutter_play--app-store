class AirportPickupPreferenceModel {
  const AirportPickupPreferenceModel({
    required this.pickupPreferenceId,
    required this.preferenceName,
    required this.preferencePrice,
    this.currency = 'USD',
  });

  final int pickupPreferenceId;
  final String preferenceName;
  final double preferencePrice;
  final String currency;

  factory AirportPickupPreferenceModel.fromJson(Map<String, dynamic> json) {
    return AirportPickupPreferenceModel(
      pickupPreferenceId: _parseInt(json['pickupPreferenceId']),
      preferenceName: json['preferenceName']?.toString() ?? '',
      preferencePrice: _parseDouble(json['preferencePrice']),
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickupPreferenceId': pickupPreferenceId,
      'preferenceName': preferenceName,
      'preferencePrice': preferencePrice,
      'currency': currency,
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

