import 'package:flutter/services.dart';

enum CardBrand { visa, mastercard, amex, discover, unknown }

extension CardBrandDisplay on CardBrand {
  String get label {
    switch (this) {
      case CardBrand.visa:
        return 'Visa';
      case CardBrand.mastercard:
        return 'Mastercard';
      case CardBrand.amex:
        return 'American Express';
      case CardBrand.discover:
        return 'Discover';
      case CardBrand.unknown:
        return 'Card';
    }
  }
}

CardBrand detectCardBrand(String rawInput) {
  final digits = _onlyDigits(rawInput);
  if (RegExp(r'^4').hasMatch(digits)) return CardBrand.visa;
  if (RegExp(r'^(5[1-5]|2(2[2-9]|[3-6]\d|7[01]|720))').hasMatch(digits)) {
    return CardBrand.mastercard;
  }
  if (RegExp(r'^3[47]').hasMatch(digits)) return CardBrand.amex;
  if (RegExp(r'^6(011|5|4[4-9])').hasMatch(digits)) return CardBrand.discover;
  return CardBrand.unknown;
}

int cardNumberExpectedLength(CardBrand brand) {
  switch (brand) {
    case CardBrand.amex:
      return 15;
    case CardBrand.visa:
      return 16; // Visa can be 13/16/19; we allow up to 19 below
    case CardBrand.mastercard:
    case CardBrand.discover:
    case CardBrand.unknown:
      return 16;
  }
}

int cardNumberMaxLength(CardBrand brand) {
  switch (brand) {
    case CardBrand.amex:
      return 15;
    case CardBrand.visa:
      return 19;
    default:
      return 19;
  }
}

int cvvExpectedLength(CardBrand brand) => brand == CardBrand.amex ? 4 : 3;

String formatCardNumber(String input) {
  final digits = _onlyDigits(input);
  final brand = detectCardBrand(digits);
  final buffer = StringBuffer();
  final pattern = brand == CardBrand.amex ? [4, 6, 5] : [4, 4, 4, 4, 3];
  var idx = 0;

  for (final groupLen in pattern) {
    if (idx >= digits.length) break;
    final end =
        (idx + groupLen) > digits.length ? digits.length : idx + groupLen;
    buffer.write(digits.substring(idx, end));
    idx = end;
    if (idx < digits.length) buffer.write(' ');
  }
  return buffer.toString();
}

String formatExpiryInput(String input) {
  final digits = _onlyDigits(input);
  if (digits.isEmpty) return '';
  final month = digits.substring(0, digits.length.clamp(0, 2));
  final year =
      digits.length > 2 ? digits.substring(2, digits.length.clamp(2, 4)) : '';
  if (year.isEmpty) return month;
  final formatted = '$month/$year';
  return formatted;
}

String? validateExpiry(String? value) {
  if (value == null || value.trim().isEmpty) return 'Expiry date is required';
  final trimmed = value.trim();
  if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(trimmed)) {
    return 'Use MM/YY format';
  }
  final parts = trimmed.split('/');
  final month = int.tryParse(parts[0]) ?? 0;
  final year = int.tryParse(parts[1]) ?? -1;
  if (month < 1 || month > 12) return 'Month must be 01-12';

  final now = DateTime.now();
  final fourDigitYear = 2000 + year;
  final lastDayOfMonth = DateTime(fourDigitYear, month + 1, 0);
  if (!lastDayOfMonth.isAfter(now)) {
    return 'Card is expired';
  }
  return null;
}

String? validateZip(String? value) {
  if (value == null || value.trim().isEmpty) return 'ZIP code is required';
  final trimmed = value.trim();
  if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(trimmed)) {
    return 'Use 5 digits or ZIP+4';
  }
  return null;
}

String? validateCardNumber(String? value) {
  if (value == null || value.trim().isEmpty) return 'Card number is required';
  final digits = _onlyDigits(value);
  final brand = detectCardBrand(digits);
  final minLength =
      brand == CardBrand.visa ? 13 : cardNumberExpectedLength(brand);
  final maxLength = cardNumberMaxLength(brand);

  if (digits.length < minLength || digits.length > maxLength) {
    return brand == CardBrand.amex
        ? 'American Express numbers are 15 digits'
        : 'Enter a valid card number';
  }

  if (!_passesLuhn(digits)) return 'Card number is invalid';
  return null;
}

String? validateCvv(String? value, CardBrand brand) {
  if (value == null || value.trim().isEmpty) return 'CVV is required';
  final digits = _onlyDigits(value);
  final expected = cvvExpectedLength(brand);
  if (digits.length != expected) {
    return brand == CardBrand.amex
        ? 'AMEX CVV is 4 digits'
        : 'CVV must be 3 digits';
  }
  return null;
}

TextInputFormatter zipInputFormatter() =>
    FilteringTextInputFormatter.allow(RegExp(r'\d|-'));

TextInputFormatter expiryInputFormatter() =>
    FilteringTextInputFormatter.allow(RegExp(r'\d|/'));

String _onlyDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

bool _passesLuhn(String digits) {
  var sum = 0;
  var shouldDouble = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var digit = int.parse(digits[i]);
    if (shouldDouble) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    shouldDouble = !shouldDouble;
  }
  return sum % 10 == 0;
}
