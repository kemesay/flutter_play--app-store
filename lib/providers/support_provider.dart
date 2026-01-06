import 'package:flutter/foundation.dart';

import '../data/services/support_service.dart';

class SupportProvider extends ChangeNotifier {
  SupportProvider({SupportService? supportService})
      : _supportService = supportService ?? SupportService();

  final SupportService _supportService;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> sendMessage({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String service,
    required String message,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _supportService.sendContactEmail(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        service: service,
        message: message,
      );
      _errorMessage = null;
      _successMessage =
          'Thank you for contacting us. Our team will reach out shortly.';
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      _successMessage = null;
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

