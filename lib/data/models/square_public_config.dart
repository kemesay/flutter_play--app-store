class SquarePublicConfig {
  const SquarePublicConfig({
    required this.squareEnabled,
    required this.applicationId,
    required this.locationId,
    required this.environment,
    required this.paymentProvider,
    required this.paymentMode,
  });

  final bool squareEnabled;
  final String applicationId;
  final String locationId;
  final String environment; // "sandbox" | "production"
  final String paymentProvider;
  final String paymentMode;

  bool get isSandbox => environment.toLowerCase() != 'production';

  factory SquarePublicConfig.fromJson(Map<String, dynamic> json) {
    return SquarePublicConfig(
      squareEnabled: json['squareEnabled'] == true,
      applicationId: (json['applicationId'] ?? '').toString(),
      locationId: (json['locationId'] ?? '').toString(),
      environment: (json['environment'] ?? 'sandbox').toString(),
      paymentProvider: (json['paymentProvider'] ?? '').toString(),
      paymentMode: (json['paymentMode'] ?? '').toString(),
    );
  }
}

