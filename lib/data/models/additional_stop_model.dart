class AdditionalStopModel {
  const AdditionalStopModel({
    required this.additionalStopId,
    required this.stopType,
    required this.additionalStopPrice,
    this.currency = 'USD',
  });

  final int additionalStopId;
  final String stopType;
  final double additionalStopPrice;
  final String currency;

  factory AdditionalStopModel.fromJson(Map<String, dynamic> json) {
    return AdditionalStopModel(
      additionalStopId: _parseInt(json['additionalStopId']),
      stopType: json['stopType']?.toString() ?? '',
      additionalStopPrice: _parseDouble(json['additionalStopPrice']),
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'additionalStopId': additionalStopId,
      'stopType': stopType,
      'additionalStopPrice': additionalStopPrice,
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

