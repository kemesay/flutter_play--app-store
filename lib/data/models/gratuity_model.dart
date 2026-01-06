class GratuityModel {
  const GratuityModel({
    required this.gratuityId,
    required this.percentage,
    required this.description,
  });

  final int gratuityId;
  final double percentage;
  final String description;

  factory GratuityModel.fromJson(Map<String, dynamic> json) {
    return GratuityModel(
      gratuityId: _parseInt(json['gratuityId']),
      percentage: _parseDouble(json['percentage']),
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gratuityId': gratuityId,
      'percentage': percentage,
      'description': description,
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

