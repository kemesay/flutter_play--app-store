import 'dart:async';

import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart';

import '../../core/config/square_config.dart';
import '../../core/config/square_runtime_config.dart';
import '../models/square_payment_payload.dart';

/// Tokenizes cards via Square In-App Payments SDK (iOS/Android).
class SquarePaymentService {
  SquarePaymentService._();
  static final SquarePaymentService instance = SquarePaymentService._();

  bool _initialized = false;
  SquareRuntimeConfig? _runtimeConfig;

  /// Optionally provide runtime config from provider tree.
  void attachRuntimeConfig(SquareRuntimeConfig runtimeConfig) {
    _runtimeConfig = runtimeConfig;
  }

  Future<void> ensureInitialized() async {
    if (_initialized || !SquareConfig.useSquarePayments) return;
    final runtimeAppId = _runtimeConfig?.applicationId;
    final appId = (runtimeAppId != null && runtimeAppId.isNotEmpty)
        ? runtimeAppId
        : SquareConfig.applicationId;

    if (appId.isEmpty) {
      throw Exception(
        'Square applicationId is missing. Set values in lib/core/config/square_credentials.dart '
        'or ensure GET /payments/square/config returns applicationId.',
      );
    }

    await InAppPayments.setSquareApplicationId(appId);
    _initialized = true;
  }

  /// Returns a nonce (`cnon:...`) for `square.sourceId` on ODA-TRANSPORTATION APIs.
  Future<SquarePaymentPayload> tokenizeCard() async {
    await ensureInitialized();

    final completer = Completer<SquarePaymentPayload>();

    await InAppPayments.startCardEntryFlow(
      onCardNonceRequestSuccess: (CardDetails cardDetails) async {
        try {
          await InAppPayments.completeCardEntry(
            onCardEntryComplete: () {},
          );
          if (!completer.isCompleted) {
            completer.complete(
              SquarePaymentPayload(sourceId: cardDetails.nonce),
            );
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
      onCardEntryCancel: () {
        if (!completer.isCompleted) {
          completer.completeError(Exception('Card entry cancelled'));
        }
      },
      collectPostalCode: true,
    );

    return completer.future;
  }
}
