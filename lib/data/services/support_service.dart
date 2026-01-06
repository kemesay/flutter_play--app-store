import '../../core/network/api_client.dart';

class SupportService {
  SupportService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<void> sendContactEmail({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String service,
    required String message,
    String subject = 'Mobile Contact Form Submission',
    String recipientEmail = 'info@odatransportation.com',
  }) async {
    await _apiClient.post(
      '/email/contact',
      body: {
        'from_name': fullName,
        'from_email': email,
        'from_phone': phoneNumber,
        'service': service,
        'message': message,
        'subject': subject,
        'to_email': recipientEmail,
      },
    );
  }
}

