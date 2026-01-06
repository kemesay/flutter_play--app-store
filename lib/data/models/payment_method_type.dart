enum PaymentMethodType { primaryCard, existingCard, newCard }

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get value {
    switch (this) {
      case PaymentMethodType.primaryCard:
        return 'PRIMARY_CARD';
      case PaymentMethodType.existingCard:
        return 'EXISTING_CARD';
      case PaymentMethodType.newCard:
        return 'NEW_CARD';
    }
  }

  static PaymentMethodType fromValue(String value) {
    switch (value) {
      case 'PRIMARY_CARD':
        return PaymentMethodType.primaryCard;
      case 'EXISTING_CARD':
        return PaymentMethodType.existingCard;
      case 'NEW_CARD':
      default:
        return PaymentMethodType.newCard;
    }
  }
}

