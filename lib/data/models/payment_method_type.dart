enum PaymentMethodType {
  primaryCard,
  existingCard,
  newCard,
  squareNewCard,
  squareSavedCard,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get value {
    switch (this) {
      case PaymentMethodType.primaryCard:
        return 'PRIMARY_CARD';
      case PaymentMethodType.existingCard:
        return 'EXISTING_CARD';
      case PaymentMethodType.newCard:
        return 'NEW_CARD';
      case PaymentMethodType.squareNewCard:
        return 'SQUARE_NEW_CARD';
      case PaymentMethodType.squareSavedCard:
        return 'SQUARE_SAVED_CARD';
    }
  }

  static PaymentMethodType fromValue(String value) {
    switch (value) {
      case 'PRIMARY_CARD':
        return PaymentMethodType.primaryCard;
      case 'EXISTING_CARD':
        return PaymentMethodType.existingCard;
      case 'SQUARE_NEW_CARD':
        return PaymentMethodType.squareNewCard;
      case 'SQUARE_SAVED_CARD':
        return PaymentMethodType.squareSavedCard;
      case 'NEW_CARD':
      default:
        return PaymentMethodType.newCard;
    }
  }

  bool get usesSquare =>
      this == PaymentMethodType.squareNewCard ||
      this == PaymentMethodType.squareSavedCard;
}

