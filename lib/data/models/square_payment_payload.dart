class SquarePaymentPayload {
  const SquarePaymentPayload({
    required this.sourceId,
    this.verificationToken,
  });

  final String sourceId;
  final String? verificationToken;

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        if (verificationToken != null && verificationToken!.isNotEmpty)
          'verificationToken': verificationToken,
      };
}
