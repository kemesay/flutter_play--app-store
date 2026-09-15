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

/// One capped bucket in a DiscountSummary — e.g. "2 of 5 public codes used".
class DiscountCapProgress {
  const DiscountCapProgress({
    required this.used,
    required this.remaining,
    required this.limit,
  });

  factory DiscountCapProgress.fromJson(Map<String, dynamic> json) {
    return DiscountCapProgress(
      used: (json['used'] as num).toInt(),
      remaining: (json['remaining'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
    );
  }

  final int used;
  // Null means this bucket is uncapped (e.g. referral rewards earned).
  final int? remaining;
  final int? limit;
}

/// The signed-in user's full savings/rewards picture — mirrors
/// `GET /api/v1/promo-codes/my-discount-summary`.
class DiscountSummary {
  const DiscountSummary({
    required this.totalSaved,
    required this.totalReferralRewardsEarned,
    required this.publicCodes,
    required this.referralCodesSpent,
    required this.referralRewardsEarned,
    required this.pendingReferralRewards,
  });

  factory DiscountSummary.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.parse(v.toString());

    return DiscountSummary(
      totalSaved: asDouble(json['totalSaved']),
      totalReferralRewardsEarned: asDouble(json['totalReferralRewardsEarned']),
      publicCodes: DiscountCapProgress.fromJson(
        json['publicCodes'] as Map<String, dynamic>,
      ),
      referralCodesSpent: DiscountCapProgress.fromJson(
        json['referralCodesSpent'] as Map<String, dynamic>,
      ),
      referralRewardsEarned: DiscountCapProgress.fromJson(
        json['referralRewardsEarned'] as Map<String, dynamic>,
      ),
      pendingReferralRewards: (json['pendingReferralRewards'] as num).toInt(),
    );
  }

  final double totalSaved;
  final double totalReferralRewardsEarned;
  final DiscountCapProgress publicCodes;
  final DiscountCapProgress referralCodesSpent;
  final DiscountCapProgress referralRewardsEarned;
  final int pendingReferralRewards;
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

  Future<DiscountSummary> getMyDiscountSummary() async {
    final response = await _apiClient.get(
      '/promo-codes/my-discount-summary',
      authenticated: true,
    );
    return DiscountSummary.fromJson(response as Map<String, dynamic>);
  }
}
