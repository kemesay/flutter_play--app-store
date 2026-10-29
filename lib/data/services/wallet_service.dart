import '../../core/network/api_client.dart';

/// One earned/credited "lot" in the signed-in user's wallet — mirrors a row
/// returned inside `GET /api/v1/users/wallet`'s `lots` array. A lot is
/// created either by a completed referral reward or a manual admin credit,
/// and is drawn down (FIFO, oldest first) as the customer spends it on
/// bookings — see `remainingAmount` vs. the original `amount`.
class WalletCreditLot {
  const WalletCreditLot({
    required this.walletCreditId,
    required this.amount,
    required this.remainingAmount,
    required this.sourceType,
    required this.status,
    this.note,
    this.createdAt,
  });

  factory WalletCreditLot.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.parse(v.toString());

    return WalletCreditLot(
      walletCreditId: (json['walletCreditId'] as num).toInt(),
      // DECIMAL columns may already come back as numbers (walletService
      // serializes with Number() on the backend), but parsed defensively
      // anyway — same idiom as discountValue/minFareAmount above, for
      // safety against a future change back to string serialization.
      amount: asDouble(json['amount']),
      remainingAmount: asDouble(json['remainingAmount']),
      sourceType: json['sourceType'] as String,
      status: json['status'] as String,
      note: json['note']?.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  final int walletCreditId;
  final double amount;
  final double remainingAmount;
  final String sourceType; // "referral_reward" | "manual_admin_credit"
  final String status; // "active" | "fully_redeemed" | "reversed"
  final String? note;
  final DateTime? createdAt;
}

/// The signed-in user's full wallet-credit picture — mirrors
/// `GET /api/v1/users/wallet`.
class WalletSummary {
  const WalletSummary({
    required this.balance,
    required this.lifetimeEarned,
    required this.lots,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.parse(v.toString());

    final rawLots = json['lots'];
    final lots = rawLots is List
        ? rawLots
            .whereType<Map>()
            .map((e) => WalletCreditLot.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <WalletCreditLot>[];

    return WalletSummary(
      balance: asDouble(json['balance']),
      lifetimeEarned: asDouble(json['lifetimeEarned']),
      lots: lots,
    );
  }

  final double balance;
  final double lifetimeEarned;
  final List<WalletCreditLot> lots;
}

/// A logged ask to cash out some of the signed-in user's wallet balance —
/// mirrors a row from `GET /api/v1/users/wallet/cash-out-requests`. Creating
/// one never moves money by itself: an admin still has to review and settle
/// it (outside the app — Zelle, check, ACH) before the wallet is debited.
class CashOutRequest {
  const CashOutRequest({
    required this.walletCashOutRequestId,
    required this.amountRequested,
    required this.status,
    this.note,
    this.resolutionNote,
    this.createdAt,
  });

  factory CashOutRequest.fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.parse(v.toString());

    return CashOutRequest(
      walletCashOutRequestId: (json['walletCashOutRequestId'] as num).toInt(),
      amountRequested: asDouble(json['amountRequested']),
      status: json['status'] as String,
      note: json['note']?.toString(),
      resolutionNote: json['resolutionNote']?.toString(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }

  final int walletCashOutRequestId;
  final double amountRequested;
  final String status; // "pending" | "fulfilled" | "cancelled"
  final String? note;
  final String? resolutionNote;
  final DateTime? createdAt;
}

/// The signed-in user's running dollar wallet-credit balance, accumulated
/// from completed referral rewards (and any manual admin credits) — auto-
/// applies toward future bookings. See `GET /api/v1/users/wallet`.
class WalletService {
  WalletService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<WalletSummary> getMyWallet() async {
    final response = await _apiClient.get(
      '/users/wallet',
      authenticated: true,
    );
    return WalletSummary.fromJson(response as Map<String, dynamic>);
  }

  /// Requests a cash-out of part or all of the signed-in user's balance.
  /// Creates a pending request only — an admin still has to approve and pay
  /// it out before anything is actually debited.
  Future<CashOutRequest> requestCashOut({
    required double amountRequested,
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/users/wallet/cash-out-requests',
      authenticated: true,
      body: {
        'amountRequested': amountRequested,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return CashOutRequest.fromJson(response as Map<String, dynamic>);
  }

  /// The signed-in user's own cash-out request history (pending + resolved).
  Future<List<CashOutRequest>> getMyCashOutRequests() async {
    final response = await _apiClient.get(
      '/users/wallet/cash-out-requests',
      authenticated: true,
    );
    final list = response as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => CashOutRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
