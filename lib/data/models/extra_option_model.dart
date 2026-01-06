class ExtraOptionModel {
  const ExtraOptionModel({
    required this.extraOptionId,
    required this.name,
    required this.description,
    required this.pricePerItem,
    this.currency = 'USD',
    required this.hasMaxAllowedLimit,
    this.maxAllowedItems,
  });

  final int extraOptionId;
  final String name;
  final String description;
  final double pricePerItem;
  final String currency;
  final bool hasMaxAllowedLimit;
  final int? maxAllowedItems;

  factory ExtraOptionModel.fromJson(Map<String, dynamic> json) {
    return ExtraOptionModel(
      extraOptionId: _parseInt(json['extraOptionId']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      pricePerItem: _parseDouble(json['pricePerItem']),
      currency: json['currency']?.toString() ?? 'USD',
      hasMaxAllowedLimit: _parseBool(json['hasMaxAllowedLimit']),
      maxAllowedItems: _parseNullableInt(json['maxAllowedItems']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extraOptionId': extraOptionId,
      'name': name,
      'description': description,
      'pricePerItem': pricePerItem,
      'currency': currency,
      'hasMaxAllowedLimit': hasMaxAllowedLimit,
      'maxAllowedItems': maxAllowedItems,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}

