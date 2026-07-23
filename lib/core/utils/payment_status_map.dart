/// Maps Square ledger status (`payment.transaction.updated`) to booking paymentStatus.
String mapTransactionStatusToPaymentStatus(String txStatus) {
  switch (txStatus.toUpperCase()) {
    case 'AUTHORIZED':
      return 'AUTHORIZED';
    case 'COMPLETED':
      return 'PAID';
    case 'CANCELED':
    case 'FAILED':
      return 'CANCELLED';
    case 'REFUNDED':
      return 'REFUNDED';
    default:
      return txStatus;
  }
}

bool isPaymentSettled(String? paymentStatus) {
  return paymentStatus == 'PAID';
}

bool isPaymentAuthorized(String? paymentStatus) {
  return paymentStatus == 'AUTHORIZED';
}

String getCheckoutPaymentHint({String paymentMode = 'authorize_capture'}) {
  if (paymentMode == 'charge_immediate') {
    return 'Your card will be charged when you confirm this booking.';
  }
  return 'Your card will be authorized at checkout. Payment is captured later when our team completes the trip.';
}

String getSavedCardCheckoutHint({String paymentMode = 'authorize_capture'}) {
  if (paymentMode == 'charge_immediate') {
    return 'This card will be charged when you confirm the booking.';
  }
  return 'This card will be authorized when you confirm. Payment is captured when the trip is completed.';
}

String formatPaymentStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'AUTHORIZED':
      return 'Authorized';
    case 'PAID':
      return 'Paid';
    case 'NOT_PAID':
      return 'Not Paid';
    case 'AWAITING_PAYMENT':
      return 'Awaiting Payment';
    case 'CANCELLED':
      return 'Cancelled';
    case 'REFUNDED':
      return 'Refunded';
    default:
      return status.replaceAll('_', ' ');
  }
}

String formatPaymentMethodLabel(String method) {
  switch (method.toUpperCase()) {
    case 'SQUARE_NEW_CARD':
      return 'Square — New Card';
    case 'SQUARE_SAVED_CARD':
      return 'Square — Saved Card';
    case 'PRIMARY_CARD':
      return 'Primary Card';
    case 'EXISTING_CARD':
      return 'Saved Card';
    case 'NEW_CARD':
      return 'New Card';
    case 'CASH':
      return 'Cash';
    default:
      return method.replaceAll('_', ' ');
  }
}

String? paymentStatusHint(String? paymentStatus) {
  if (paymentStatus == 'AUTHORIZED') {
    return 'Your card is authorized. Payment will be captured when the trip is completed.';
  }
  if (paymentStatus == 'PAID') {
    return 'Payment completed.';
  }
  return null;
}
