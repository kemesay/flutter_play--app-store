class PaymentDetailModel {
  const PaymentDetailModel({
    required this.paymentDetailId,
    required this.creditCardNumber,
    required this.expirationDate,
    required this.securityCode,
    required this.zipCode,
    required this.cardOwnerName,
    required this.isPrimary,
    this.squareCardId,
    this.squareCustomerId,
    this.cardBrand,
    this.last4,
    this.expMonth,
    this.expYear,
  });

  final int paymentDetailId;
  final String creditCardNumber;
  final String expirationDate;
  final String securityCode;
  final String zipCode;
  final String cardOwnerName;
  final bool isPrimary;
  final String? squareCardId;
  final String? squareCustomerId;
  final String? cardBrand;
  final String? last4;
  final int? expMonth;
  final int? expYear;

  String get maskedCardNumber {
    if (last4 != null && last4!.isNotEmpty) {
      final digits = last4!.replaceAll(RegExp(r'\D'), '');
      final last = digits.length >= 4
          ? digits.substring(digits.length - 4)
          : digits.padLeft(4, '0');
      return '**** **** **** $last';
    }
    if (creditCardNumber.length < 4) return creditCardNumber;
    final digits = creditCardNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '•••• •••• •••• ****';
    final last = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : digits;
    return '**** **** **** $last';
  }

  factory PaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return PaymentDetailModel(
      paymentDetailId: _parseInt(
        json['paymentDetailId'] ??
            json['payment_detail_id'] ??
            json['id'] ??
            json['paymentDetailID'],
      ),
      creditCardNumber: json['creditCardNumber']?.toString() ?? '',
      expirationDate: json['expirationDate']?.toString() ?? '',
      securityCode: json['securityCode']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      cardOwnerName: json['cardOwnerName']?.toString() ?? '',
      isPrimary: _parseBool(json['isPrimary']),
      squareCardId: (json['squareCardId'] ?? json['square_card_id'])
          ?.toString(),
      squareCustomerId: json['squareCustomerId']?.toString(),
      cardBrand: json['cardBrand']?.toString(),
      last4: json['last4']?.toString(),
      expMonth: _parseNullableInt(json['expMonth']),
      expYear: _parseNullableInt(json['expYear']),
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
      if (squareCardId != null) 'squareCardId': squareCardId,
      if (squareCustomerId != null) 'squareCustomerId': squareCustomerId,
      if (cardBrand != null) 'cardBrand': cardBrand,
      if (last4 != null) 'last4': last4,
      if (expMonth != null) 'expMonth': expMonth,
      if (expYear != null) 'expYear': expYear,
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
