import '../../core/network/api_client.dart';
import '../models/card_details.dart';
import '../models/payment_detail_model.dart';

class PaymentService {
  PaymentService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PaymentDetailModel>> fetchPaymentCards() async {
    final response = await _apiClient.get(
      '/users/payment-detail/paymentCards',
      authenticated: true,
    );

    if (response is! List<dynamic>) return [];
    return response
        .whereType<Map<String, dynamic>>()
        .map(PaymentDetailModel.fromJson)
        .toList();
  }

  Future<PaymentDetailModel> fetchPaymentCardById(int paymentDetailId) async {
    final response = await _apiClient.get(
      '/users/payment-detail/$paymentDetailId',
      authenticated: true,
    ) as Map<String, dynamic>;

    return PaymentDetailModel.fromJson(response);
  }

  Future<PaymentDetailModel> addPaymentCard(CardDetails details) async {
    final response = await _apiClient.post(
      '/users/payment-detail/validate-card',
      authenticated: true,
      body: details.toJson(),
    ) as Map<String, dynamic>;

    final card = response['paymentDetail'] as Map<String, dynamic>?;
    if (card == null) {
      throw const FormatException('Payment detail information missing from response');
    }
    final paymentDetail = PaymentDetailModel.fromJson(card);

    if (details.isPrimary && paymentDetail.paymentDetailId != 0) {
      await setPrimaryPaymentCard(paymentDetail.paymentDetailId);
      return fetchPaymentCardById(paymentDetail.paymentDetailId);
    }

    return paymentDetail;
  }

  Future<PaymentDetailModel> updatePaymentCard(
    int paymentDetailId,
    CardDetails details,
  ) async {
    final response = await _apiClient.put(
      '/users/payment-detail/$paymentDetailId',
      authenticated: true,
      body: details.toJson(),
    ) as Map<String, dynamic>;

    final updatedCard = PaymentDetailModel.fromJson(response);

    if (details.isPrimary) {
      await setPrimaryPaymentCard(paymentDetailId);
      return fetchPaymentCardById(paymentDetailId);
    }

    return updatedCard;
  }

  Future<void> setPrimaryPaymentCard(int paymentDetailId) async {
    await _apiClient.patch(
      '/users/payment-detail/$paymentDetailId/set-primary',
      authenticated: true,
      body: const {},
    );
  }
}

