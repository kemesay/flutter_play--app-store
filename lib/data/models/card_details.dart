class CardDetails {
  const CardDetails({
    required this.creditCardNumber,
    required this.cardOwnerName,
    required this.expirationDate,
    required this.securityCode,
    required this.zipCode,
    this.isPrimary = false,
  });

  final String creditCardNumber;
  final String cardOwnerName;
  final String expirationDate;
  final String securityCode;
  final String zipCode;
  final bool isPrimary;

  Map<String, dynamic> toJson() => {
        'creditCardNumber': creditCardNumber,
        'cardOwnerName': cardOwnerName,
        'expirationDate': expirationDate,
        'securityCode': securityCode,
        'zipCode': zipCode,
        'isPrimary': isPrimary,
      };
}

