import '../../core/network/api_client.dart';

class PromoCodeValidationResult {
  const PromoCodeValidationResult({
    required this.discount,
    required this.finalFare,
  });

  final double discount;
  final double finalFare;
}

/// The signed-in user's own personal referral code — created on first
/// request, mirrors `GET /api/v1/promo-codes/my-referral-code`.
class ReferralCodeInfo {
  const ReferralCodeInfo({
    required this.code,
    required this.discountValue,
    required this.link,
    required this.shareMessage,
  });

  final String code;
  final double discountValue;
  final String link;
  final String shareMessage;
}

/// Public preview of a promo code's discount before booking — mirrors
/// `POST /api/v1/promo-codes/validate` on the backend. The actual booking
/// submission re-validates and redeems the code server-side; this is only
/// used to show the customer the discount ahead of time.
class PromoCodeService {
  PromoCodeService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<PromoCodeValidationResult> validate({
    required String code,
    required String bookingType,
    required double fareAmount,
  }) async {
    final response = await _apiClient.post(
      '/promo-codes/validate',
      authenticated: true,
      body: {
        'code': code,
        'bookingType': bookingType,
        'fareAmount': fareAmount,
      },
    );
    final map = response as Map<String, dynamic>;
    return PromoCodeValidationResult(
      discount: (map['discount'] as num).toDouble(),
      finalFare: (map['finalFare'] as num).toDouble(),
    );
  }

  Future<ReferralCodeInfo> getMyReferralCode() async {
    final response = await _apiClient.get(
      '/promo-codes/my-referral-code',
      authenticated: true,
    );
    final map = response as Map<String, dynamic>;
    return ReferralCodeInfo(
      code: map['code'] as String,
      // discountValue is a Sequelize DECIMAL column, serialized as a JSON
      // string (e.g. "10.00") rather than a number — parse defensively.
      discountValue: double.parse(map['discountValue'].toString()),
      link: map['link'] as String,
      shareMessage: map['shareMessage'] as String,
    );
  }
}
