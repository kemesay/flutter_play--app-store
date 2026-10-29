import 'package:flutter/foundation.dart';

import '../data/services/wallet_service.dart';

/// Wraps [WalletService] as a [ChangeNotifier] so the live wallet balance can
/// be shared reactively between the account page and every booking form
/// (all of which auto-apply the same balance toward a trip's total) without
/// each of them independently polling the endpoint.
class WalletProvider extends ChangeNotifier {
  WalletProvider({WalletService? walletService})
      : _walletService = walletService ?? WalletService();

  final WalletService _walletService;
  bool _disposed = false;

  WalletSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  List<CashOutRequest> _cashOutRequests = const [];
  bool _cashOutRequestsLoaded = false;
  bool _isSubmittingCashOut = false;

  double get balance => _summary?.balance ?? 0;
  double get lifetimeEarned => _summary?.lifetimeEarned ?? 0;
  List<WalletCreditLot> get lots => _summary?.lots ?? const <WalletCreditLot>[];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<CashOutRequest> get cashOutRequests => _cashOutRequests;
  bool get isSubmittingCashOut => _isSubmittingCashOut;

  /// True once a wallet summary has been fetched at least once (successfully
  /// or not) — lets callers tell "never asked yet" apart from "asked and got
  /// a zero balance."
  bool get hasLoaded => _summary != null;

  /// Fetches the signed-in user's wallet summary. Safe to call from every
  /// booking form's `initState` — a load already in flight or already
  /// completed is skipped unless [force] is set, so multiple forms mounting
  /// around the same time share one fetch instead of racing duplicate calls.
  Future<void> loadWallet({bool force = false}) async {
    if (_isLoading) return;
    if (hasLoaded && !force) return;
    _setLoading(true);
    try {
      _summary = await _walletService.getMyWallet();
      _errorMessage = null;
    } catch (error) {
      // Non-critical: callers (account card, booking forms) treat a failed
      // load as "no wallet credit available this session" rather than
      // surfacing an error, same philosophy as the other account-page cards.
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches the signed-in user's own cash-out request history. Safe to call
  /// repeatedly (e.g. on account-page mount) — already-loaded results are
  /// skipped unless [force] is set, same guard shape as [loadWallet].
  Future<void> loadCashOutRequests({bool force = false}) async {
    if (_cashOutRequestsLoaded && !force) return;
    try {
      _cashOutRequests = await _walletService.getMyCashOutRequests();
      _cashOutRequestsLoaded = true;
      _notify();
    } catch (_) {
      // Non-critical: the request-history list just stays empty, same
      // fail-silently philosophy as the rest of this provider.
    }
  }

  /// Submits a cash-out request for part or all of the current balance.
  /// Creates a PENDING request only — an admin still has to review and pay
  /// it out before anything is actually debited. Returns null on failure
  /// (the message is in [errorMessage]) so the caller can show it inline.
  Future<CashOutRequest?> requestCashOut({
    required double amountRequested,
    String? note,
  }) async {
    _isSubmittingCashOut = true;
    _errorMessage = null;
    _notify();
    try {
      final request = await _walletService.requestCashOut(
        amountRequested: amountRequested,
        note: note,
      );
      await loadCashOutRequests(force: true);
      return request;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _isSubmittingCashOut = false;
      _notify();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
