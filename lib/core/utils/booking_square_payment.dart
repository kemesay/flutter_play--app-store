import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/config/square_runtime_config.dart';
import '../../data/models/card_details.dart';
import '../../data/models/payment_detail_model.dart';
import '../../data/models/payment_method_type.dart';
import '../../data/models/square_payment_payload.dart';
import '../../data/services/square_payment_service.dart';
import '../../providers/payment_provider.dart';

const double _feeEpsilon = 0.01;

bool hasVerifiedSquarePayment(SquarePaymentPayload? payload) {
  final id = payload?.sourceId;
  return id != null && id.isNotEmpty;
}

bool squareFeeChangedSinceTokenize(
  double? tokenizedAtTotal,
  double currentTotal,
) {
  if (tokenizedAtTotal == null) return false;
  return (tokenizedAtTotal - currentTotal).abs() > _feeEpsilon;
}

/// Validates payment selection before booking submit (Square-enabled flows).
String? validateBookingPaymentSelection({
  required PaymentMethodType paymentMethod,
  required int? paymentDetailId,
  required String? squareCardId,
  required CardDetails? cardDetails,
  required PaymentDetailModel? primaryCard,
  SquarePaymentPayload? squarePayload,
  double? squareTokenizedAtTotal,
  double? currentBookingTotal,
  bool squareEnabled = false,
}) {
  if (squareEnabled &&
      (paymentMethod == PaymentMethodType.newCard ||
          paymentMethod == PaymentMethodType.primaryCard ||
          paymentMethod == PaymentMethodType.existingCard)) {
    return 'Select a Square payment option before confirming.';
  }
  switch (paymentMethod) {
    case PaymentMethodType.squareSavedCard:
      final hasWalletId = paymentDetailId != null && paymentDetailId > 0;
      final hasSquareId =
          squareCardId != null && squareCardId.trim().isNotEmpty;
      if (!hasWalletId && !hasSquareId) {
        return 'Select a saved card to proceed.';
      }
      return null;
    case PaymentMethodType.squareNewCard:
      return validateSquareNewCardForSubmit(
        payload: squarePayload,
        tokenizedAtTotal: squareTokenizedAtTotal,
        currentTotal: currentBookingTotal,
      );
    case PaymentMethodType.primaryCard:
      if (primaryCard == null) {
        return 'You do not have a primary card on file.';
      }
      return null;
    case PaymentMethodType.existingCard:
      if (paymentDetailId == null) {
        return 'Select a saved card to proceed.';
      }
      return null;
    case PaymentMethodType.newCard:
      if (cardDetails == null) {
        return 'Enter and validate payment card details before confirming.';
      }
      return null;
  }
}

String? validateSquareNewCardForSubmit({
  required SquarePaymentPayload? payload,
  required double? tokenizedAtTotal,
  required double? currentTotal,
}) {
  if (!hasVerifiedSquarePayment(payload)) {
    return 'Verify your card with Square in the payment section before confirming.';
  }
  if (currentTotal != null &&
      tokenizedAtTotal != null &&
      squareFeeChangedSinceTokenize(tokenizedAtTotal, currentTotal)) {
    return 'Trip total changed. Verify your card again before confirming.';
  }
  return null;
}

/// Whether the consent checkbox may be enabled (mirrors website: card verified
/// on Contact before Summary / Book).
bool isBookingPaymentReadyForConsent({
  required bool squareEnabled,
  required PaymentMethodType paymentMethod,
  required SquarePaymentPayload? squarePayload,
  required double? squareTokenizedAtTotal,
  required double? currentBookingTotal,
  required CardDetails? legacyCardDetails,
}) {
  if (!squareEnabled) {
    if (paymentMethod == PaymentMethodType.newCard) {
      return legacyCardDetails != null;
    }
    return true;
  }
  switch (paymentMethod) {
    case PaymentMethodType.squareNewCard:
      if (!hasVerifiedSquarePayment(squarePayload)) return false;
      if (currentBookingTotal != null &&
          squareTokenizedAtTotal != null &&
          squareFeeChangedSinceTokenize(
            squareTokenizedAtTotal,
            currentBookingTotal,
          )) {
        return false;
      }
      return true;
    case PaymentMethodType.newCard:
      return legacyCardDetails != null;
    default:
      return true;
  }
}

String? bookingPaymentConsentHint({
  required bool squareEnabled,
  required PaymentMethodType paymentMethod,
  required SquarePaymentPayload? squarePayload,
  required double? squareTokenizedAtTotal,
  required double? currentBookingTotal,
  required CardDetails? legacyCardDetails,
}) {
  if (isBookingPaymentReadyForConsent(
    squareEnabled: squareEnabled,
    paymentMethod: paymentMethod,
    squarePayload: squarePayload,
    squareTokenizedAtTotal: squareTokenizedAtTotal,
    currentBookingTotal: currentBookingTotal,
    legacyCardDetails: legacyCardDetails,
  )) {
    return null;
  }
  if (squareEnabled && paymentMethod == PaymentMethodType.squareNewCard) {
    if (!hasVerifiedSquarePayment(squarePayload)) {
      return 'Enter billing details and tap Verify card with Square before confirming.';
    }
    if (currentBookingTotal != null &&
        squareTokenizedAtTotal != null &&
        squareFeeChangedSinceTokenize(
          squareTokenizedAtTotal,
          currentBookingTotal,
        )) {
      return 'Estimated total changed — verify your card again.';
    }
  }
  if (!squareEnabled && paymentMethod == PaymentMethodType.newCard) {
    return 'Validate your card in the payment section before confirming.';
  }
  return null;
}

/// Tokenize with Square SDK (checkout new card).
Future<SquarePaymentPayload> tokenizeSquareCheckoutCard(
  BuildContext context,
) async {
  final squareRuntime = context.read<SquareRuntimeConfig>();
  SquarePaymentService.instance.attachRuntimeConfig(squareRuntime);
  return SquarePaymentService.instance.tokenizeCard();
}

/// Pick the best Square payment method when the form still has a legacy default.
void initSquarePaymentDefaults({
  required PaymentProvider paymentProvider,
  required void Function(PaymentMethodType) setPaymentMethod,
  required void Function(int?) setPaymentDetailId,
  required void Function(String?) setSquareCardId,
  required void Function(CardDetails?) setCardDetails,
  required void Function(SquarePaymentPayload?) setSquarePayload,
  required void Function(double?) setSquareTokenizedAtTotal,
  required PaymentMethodType currentMethod,
}) {
  if (currentMethod == PaymentMethodType.squareNewCard ||
      currentMethod == PaymentMethodType.squareSavedCard) {
    return;
  }

  final primary = paymentProvider.primarySquareCard;
  if (primary != null) {
    applySquareSavedCardSelection(
      setPaymentMethod: setPaymentMethod,
      setPaymentDetailId: setPaymentDetailId,
      setSquareCardId: setSquareCardId,
      setCardDetails: setCardDetails,
      setSquarePayload: setSquarePayload,
      setSquareTokenizedAtTotal: setSquareTokenizedAtTotal,
      card: primary,
    );
    return;
  }

  final cards = paymentProvider.squareCards;
  if (cards.isNotEmpty) {
    applySquareSavedCardSelection(
      setPaymentMethod: setPaymentMethod,
      setPaymentDetailId: setPaymentDetailId,
      setSquareCardId: setSquareCardId,
      setCardDetails: setCardDetails,
      setSquarePayload: setSquarePayload,
      setSquareTokenizedAtTotal: setSquareTokenizedAtTotal,
      card: cards.first,
    );
    return;
  }

  setPaymentMethod(PaymentMethodType.squareNewCard);
  setPaymentDetailId(null);
  setSquareCardId(null);
  setCardDetails(null);
  setSquarePayload(null);
  setSquareTokenizedAtTotal(null);
}

/// Apply a wallet card for [PaymentMethodType.squareSavedCard] checkout.
void applySquareSavedCardSelection({
  required void Function(PaymentMethodType) setPaymentMethod,
  required void Function(int?) setPaymentDetailId,
  required void Function(String?) setSquareCardId,
  required void Function(CardDetails?) setCardDetails,
  required void Function(SquarePaymentPayload?) setSquarePayload,
  required void Function(double?) setSquareTokenizedAtTotal,
  required PaymentDetailModel card,
}) {
  setPaymentMethod(PaymentMethodType.squareSavedCard);
  setPaymentDetailId(
    card.paymentDetailId > 0 ? card.paymentDetailId : null,
  );
  setSquareCardId(card.squareCardId?.trim());
  setCardDetails(null);
  setSquarePayload(null);
  setSquareTokenizedAtTotal(null);
}
