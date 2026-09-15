import 'dart:io';

import 'package:android_play_install_referrer/android_play_install_referrer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carries a referral code through an app-store install so a friend who
/// downloads via someone's referral link doesn't have to remember and
/// retype it once the app is open.
///
/// The website's smart download page (`/app-download`) hands the code off
/// two different ways depending on platform, since there's no single
/// mechanism that works on both:
///   - Android: appended to the Play Store URL as `referrer=promoCode=CODE`,
///     which Google's Play Install Referrer API hands back to the app after
///     install — official, reliable, first-party.
///   - iOS: there's no equivalent API, so the code is copied to the
///     clipboard right before handing off to the App Store. This class
///     checks the clipboard exactly once, on the very first launch, and
///     never again — both because it's only useful once, and because
///     re-checking on every launch would keep re-triggering iOS's "Bemused
///     App pasted from Chrome" banner.
class PendingReferralStore {
  PendingReferralStore._();

  static const _pendingCodeKey = 'pending_referral_code';
  static const _captureAttemptedKey = 'referral_capture_attempted';
  static final _codePattern = RegExp(r'^[A-Z0-9]{4,20}$');

  /// Call once, early at app startup (fire-and-forget is fine — nothing
  /// needs this before the user reaches a booking form).
  static Future<void> captureOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_captureAttemptedKey) == true) return;
    await prefs.setBool(_captureAttemptedKey, true);

    String? code;
    try {
      if (Platform.isAndroid) {
        code = await _captureFromPlayReferrer();
      } else if (Platform.isIOS) {
        code = await _captureFromClipboard();
      }
    } catch (error) {
      debugPrint('PendingReferralStore: capture failed: $error');
    }

    if (code != null) {
      await prefs.setString(_pendingCodeKey, code);
    }
  }

  static Future<String?> _captureFromPlayReferrer() async {
    final details = await AndroidPlayInstallReferrer.installReferrer;
    final referrer = details.installReferrer;
    if (referrer == null || referrer.isEmpty) return null;
    // e.g. "promoCode=OdaCar" — parsed as a query string since that's the
    // exact shape the website appends to the Play Store URL.
    final params = Uri.splitQueryString(referrer);
    return _sanitize(params['promoCode']);
  }

  static Future<String?> _captureFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return _sanitize(data?.text);
  }

  static String? _sanitize(String? raw) {
    if (raw == null) return null;
    final candidate = raw.trim().toUpperCase();
    return _codePattern.hasMatch(candidate) ? candidate : null;
  }

  /// Reads the pending code without clearing it — safe to call from every
  /// booking form; only the first one that actually applies it should
  /// [consume] it.
  static Future<String?> peek() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingCodeKey);
  }

  /// Call once a code has actually been applied to a booking, so it isn't
  /// suggested again on a later, unrelated booking.
  static Future<void> consume() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCodeKey);
  }
}
