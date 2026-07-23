import 'package:flutter/foundation.dart';

import '../core/exceptions/api_exception.dart';
import '../core/utils/payment_card_utils.dart';
import '../data/models/card_details.dart';
import '../data/models/payment_detail_model.dart';
import '../data/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService();

  final PaymentService _paymentService;
  bool _disposed = false;

  List<PaymentDetailModel> _cards = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<PaymentDetailModel> get cards => _cards;

  /// Cards stored with Square (ccof or last4 from wallet API).
  List<PaymentDetailModel> get squareCards =>
      _cards.where(isSquareReadyCard).toList();

  bool get hasSquareCards => squareCards.isNotEmpty;

  PaymentDetailModel? get primarySquareCard {
    for (final card in squareCards) {
      if (card.isPrimary) return card;
    }
    return null;
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  PaymentDetailModel? get primaryCard {
    final squarePrimary = primarySquareCard;
    if (squarePrimary != null) return squarePrimary;
    for (final card in _cards) {
      if (card.isPrimary) return card;
    }
    return null;
  }

  Future<void> loadCards() async {
    _setLoading(true);
    try {
      _cards = await _paymentService.fetchPaymentCards();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSquareCard({
    required String sourceId,
    required String cardOwnerName,
    required String zipCode,
    bool isPrimary = false,
    String? verificationToken,
  }) async {
    _setSaving(true);
    try {
      await _paymentService.saveSquareCard(
        sourceId: sourceId,
        cardOwnerName: cardOwnerName,
        zipCode: zipCode,
        isPrimary: isPrimary,
        verificationToken: verificationToken,
      );
      await loadCards();
      _successMessage = 'Card saved to your wallet.';
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _successMessage = null;
      return false;
    } finally {
      _setSaving(false);
    }
  }

  String _friendlyError(Object error) {
    var text = error is ApiException ? error.message : error.toString();
    const maxLen = 240;
    if (text.length > maxLen) {
      text = '${text.substring(0, maxLen)}…';
    }
    return text;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> addCard(CardDetails details) async {
    _setSaving(true);
    try {
      final card = await _paymentService.addPaymentCard(details);
      _cards = List<PaymentDetailModel>.from(_cards)..add(card);
      if (card.isPrimary) {
        await loadCards();
      } else {
        _notify();
      }
      _successMessage = 'Payment card added successfully.';
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _successMessage = null;
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> updateCard(int paymentDetailId, CardDetails details) async {
    _setSaving(true);
    try {
      final updatedCard = await _paymentService.updatePaymentCard(
        paymentDetailId,
        details,
      );
      _cards = _cards
          .map(
            (card) => card.paymentDetailId == updatedCard.paymentDetailId
                ? updatedCard
                : card,
          )
          .toList();
      if (details.isPrimary) {
        await loadCards();
      } else {
        _notify();
      }
      _successMessage = 'Payment card updated successfully.';
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _successMessage = null;
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> setPrimary(int paymentDetailId) async {
    _setSaving(true);
    try {
      await _paymentService.setPrimaryPaymentCard(paymentDetailId);
      await loadCards();
      _successMessage = 'Primary card updated.';
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _friendlyError(error);
      _successMessage = null;
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    _notify();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    _notify();
  }
}
