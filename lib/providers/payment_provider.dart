import 'package:flutter/foundation.dart';

import '../data/models/card_details.dart';
import '../data/models/payment_detail_model.dart';
import '../data/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? paymentService})
      : _paymentService = paymentService ?? PaymentService();

  final PaymentService _paymentService;

  List<PaymentDetailModel> _cards = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<PaymentDetailModel> get cards => _cards;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  PaymentDetailModel? get primaryCard {
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
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCard(CardDetails details) async {
    _setSaving(true);
    try {
      final card = await _paymentService.addPaymentCard(details);
      _cards = List<PaymentDetailModel>.from(_cards)..add(card);
      if (card.isPrimary) {
        await loadCards();
      } else {
        notifyListeners();
      }
      _successMessage = 'Payment card added successfully.';
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _successMessage = null;
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<bool> updateCard(int paymentDetailId, CardDetails details) async {
    _setSaving(true);
    try {
      final updatedCard =
          await _paymentService.updatePaymentCard(paymentDetailId, details);
      _cards = _cards
          .map((card) =>
              card.paymentDetailId == updatedCard.paymentDetailId ? updatedCard : card)
          .toList();
      if (details.isPrimary) {
        await loadCards();
      } else {
        notifyListeners();
      }
      _successMessage = 'Payment card updated successfully.';
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = error.toString();
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
      _errorMessage = error.toString();
      _successMessage = null;
      return false;
    } finally {
      _setSaving(false);
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}

