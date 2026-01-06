class PaymentDetailModel {
  const PaymentDetailModel({
    required this.paymentDetailId,
    required this.creditCardNumber,
    required this.expirationDate,
    required this.securityCode,
    required this.zipCode,
    required this.cardOwnerName,
    required this.isPrimary,
  });

  final int paymentDetailId;
  final String creditCardNumber;
  final String expirationDate;
  final String securityCode;
  final String zipCode;
  final String cardOwnerName;
  final bool isPrimary;

  String get maskedCardNumber {
    if (creditCardNumber.length < 4) return creditCardNumber;
    final last4 = creditCardNumber.substring(creditCardNumber.length - 4);
    return '**** **** **** $last4';
  }

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailModel(
      paymentDetailId: _parseInt(json['paymentDetailId']),
      creditCardNumber: json['creditCardNumber']?.toString() ?? '',
      expirationDate: json['expirationDate']?.toString() ?? '',
      securityCode: json['securityCode']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      cardOwnerName: json['cardOwnerName']?.toString() ?? '',
      isPrimary: _parseBool(json['isPrimary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentDetailId': paymentDetailId,
      'creditCardNumber': creditCardNumber,
      'expirationDate': expirationDate,
      'securityCode': securityCode,
      'zipCode': zipCode,
      'cardOwnerName': cardOwnerName,
      'isPrimary': isPrimary,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
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

