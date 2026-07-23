import '../../data/models/payment_detail_model.dart';

/// Card can be charged with [PaymentMethodType.squareSavedCard].
bool isSquareReadyCard(PaymentDetailModel card) {
  final id = card.squareCardId;
  if (id != null && id.isNotEmpty && id.startsWith('ccof:')) {
    return true;
  }
  return card.last4 != null && card.last4!.isNotEmpty;
}

/// Stable key for dropdowns / selection (wallet [paymentDetailId] or Square [ccof:…]).
String savedCardSelectionKey(PaymentDetailModel card) {
  if (card.paymentDetailId > 0) {
    return 'pd:${card.paymentDetailId}';
  }
  final squareId = card.squareCardId?.trim();
  if (squareId != null && squareId.isNotEmpty) {
    return 'sq:$squareId';
  }
  final last4 = card.last4?.replaceAll(RegExp(r'\D'), '') ?? '';
  final owner = card.cardOwnerName.trim().toLowerCase();
  return 'legacy:$owner:$last4';
}

PaymentDetailModel? findSavedCardBySelectionKey(
  Iterable<PaymentDetailModel> cards,
  String? key,
) {
  if (key == null || key.isEmpty) return null;
  for (final card in cards) {
    if (savedCardSelectionKey(card) == key) {
      return card;
    }
  }
  return null;
}

PaymentDetailModel? findSavedSquareCard({
  required Iterable<PaymentDetailModel> cards,
  int? paymentDetailId,
  String? squareCardId,
}) {
  if (paymentDetailId != null && paymentDetailId > 0) {
    for (final card in cards) {
      if (card.paymentDetailId == paymentDetailId) {
        return card;
      }
    }
  }
  final sq = squareCardId?.trim();
  if (sq != null && sq.isNotEmpty) {
    for (final card in cards) {
      if (card.squareCardId?.trim() == sq) {
        return card;
      }
    }
  }
  return null;
}

/// Cards shown in “another saved card” dropdown (excludes primary — chosen above).
List<PaymentDetailModel> savedCardsForAlternateDropdown(
  List<PaymentDetailModel> squareCards, {
  PaymentDetailModel? primary,
}) {
  if (primary == null) return List<PaymentDetailModel>.from(squareCards);
  return squareCards
      .where((c) => c.paymentDetailId != primary.paymentDetailId)
      .toList();
}

/// Display label aligned with oda-ride-transport `formatCardForDisplay` / Autocomplete.
String formatSavedCardDropdownLabel(PaymentDetailModel card) {
  final last4Raw =
      card.last4?.replaceAll(RegExp(r'\D'), '') ??
      card.creditCardNumber.replaceAll(RegExp(r'\D'), '');
  final last4 = last4Raw.length >= 4
      ? last4Raw.substring(last4Raw.length - 4)
      : (last4Raw.isNotEmpty ? last4Raw : null);

  final brand = (card.cardBrand?.trim().isNotEmpty == true)
      ? card.cardBrand!.trim().toUpperCase()
      : 'CARD';

  final masked = last4 != null ? '•••• $last4' : 'Saved card';
  final primarySuffix = card.isPrimary ? ' (Primary)' : '';
  final owner = card.cardOwnerName.trim();
  final ownerSuffix = owner.isNotEmpty ? ' · $owner' : '';

  return '$brand $masked$ownerSuffix$primarySuffix';
}

String formatSquareCardDisplay(PaymentDetailModel card) {
  return formatSavedCardDropdownLabel(card);
}

/// Short single-line mask for wallet / card tiles (no cardholder suffix).
String formatSquareWalletCardNumber(PaymentDetailModel card) {
  final last4Raw =
      card.last4?.replaceAll(RegExp(r'\D'), '') ??
      card.creditCardNumber.replaceAll(RegExp(r'\D'), '');
  final last4 = last4Raw.length >= 4
      ? last4Raw.substring(last4Raw.length - 4)
      : (last4Raw.isNotEmpty ? last4Raw : '****');
  final brand = (card.cardBrand?.trim().isNotEmpty == true)
      ? card.cardBrand!.trim().toUpperCase()
      : 'CARD';
  return '$brand •••• $last4';
}

String? formatSquareExpiry(PaymentDetailModel card) {
  if (card.expMonth != null && card.expYear != null) {
    final year = card.expYear! % 100;
    return '${card.expMonth!.toString().padLeft(2, '0')}/${year.toString().padLeft(2, '0')}';
  }
  if (card.expirationDate.isNotEmpty) {
    return card.expirationDate;
  }
  return null;
}
