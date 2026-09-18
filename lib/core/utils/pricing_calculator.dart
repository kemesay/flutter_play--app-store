import 'dart:math';

import '../../data/models/additional_stop_model.dart';
import '../../data/models/airport_pickup_preference_model.dart';
import '../../data/models/car_model.dart';
import '../../data/models/extra_option_model.dart';
import '../../data/models/gratuity_model.dart';
import '../../data/models/selected_extra_option.dart';

class TripPriceBreakdown {
  const TripPriceBreakdown({
    required this.currency,
    required this.baseFare,
    required this.subtotal,
    required this.total,
    required this.gratuityAmount,
    this.gratuityPercentage,
    this.additionalStops = 0,
    this.extras = 0,
    this.pickupPreference = 0,
    this.sideDetourFee = 0,
    this.otherAdjustments = 0,
    this.promoDiscount = 0,
    this.distanceInMiles,
    this.isRoundTrip = false,
  });

  final String currency;
  final double baseFare;
  final double subtotal;
  final double total;
  final double gratuityAmount;
  final double? gratuityPercentage;
  final double additionalStops;
  final double extras;
  final double pickupPreference;
  final double sideDetourFee;
  final double otherAdjustments;
  final double promoDiscount;
  final double? distanceInMiles;
  final bool isRoundTrip;

  bool get hasEstimate => total > 0;
}

class PricingCalculator {
  const PricingCalculator._();

  static TripPriceBreakdown? pointToPoint({
    required CarModel? car,
    required double? distanceInMiles,
    required GratuityModel? gratuity,
    required bool isRoundTrip,
    required List<ExtraOptionModel> extraCatalog,
    required List<SelectedExtraOption> selectedExtras,
    AdditionalStopModel? additionalStop,
    double promoDiscount = 0,
    double sideDetourFee = 0,
  }) {
    if (car == null || distanceInMiles == null || distanceInMiles <= 0) {
      return null;
    }

    final sanitizedDistance = distanceInMiles < 0 ? 0.0 : distanceInMiles;

    // Match website logic: vehicleFee * distance * (2 if round trip)
    // vehicleFee = pricePerMile
    double vehicleFeeTotal = car.pricePerMile * sanitizedDistance;
    if (isRoundTrip) {
      vehicleFeeTotal *= 2;
    }

    // Match website logic: minimumStartFee * (2 if round trip)
    final totalMinFee = isRoundTrip
        ? car.minimumStartFee * 2
        : car.minimumStartFee;

    // Base fare for gratuity calculation (includes both vehicle fee and minimum fee)
    final baseFare = _twoDecimals(vehicleFeeTotal + totalMinFee);

    final extras = _calculateExtras(
      isRoundTrip: isRoundTrip,
      extraCatalog: extraCatalog,
      selectedExtras: selectedExtras,
    );

    final additionalStopPrice = additionalStop?.additionalStopPrice ?? 0;

    // Match website/backend logic: added once, never doubled for round trip
    // (same treatment as additionalStopPrice) — caller passes 0 when there's
    // no side-pick detour on this booking, or the setting is off.
    final sanitizedSideDetourFee = sideDetourFee < 0 ? 0.0 : sideDetourFee;

    // Match website logic: totalFee = vehicleFee + totalMinFee + extras + additionalStop
    final subtotal = _twoDecimals(
      vehicleFeeTotal +
          totalMinFee +
          extras +
          additionalStopPrice +
          sanitizedSideDetourFee,
    );

    // A promo discount reduces the ride's own cost — gratuity should be a
    // tip on what the ride actually costs after that discount, not the
    // pre-discount sticker price. Discount is subtracted from the subtotal
    // BEFORE gratuity is added (mirrors the backend's chargeAmount rule,
    // now applied before gratuity instead of after it), and gratuity itself
    // is computed on baseFare scaled down by its proportional share of the
    // discount — reduces to exactly baseFare when there's no discount, so
    // an undiscounted booking's gratuity is unchanged.
    final discountedSubtotal = _twoDecimals(max(subtotal - promoDiscount, 0));
    final discountedBaseFare = _discountedCarFare(baseFare, subtotal, promoDiscount);
    final gratuityAmount = _calculateGratuity(discountedBaseFare, gratuity);
    final total = _twoDecimals(discountedSubtotal + gratuityAmount);

    return TripPriceBreakdown(
      currency: car.currency,
      baseFare: baseFare,
      subtotal: subtotal,
      total: total,
      gratuityAmount: gratuityAmount,
      gratuityPercentage: gratuity?.percentage,
      additionalStops: _twoDecimals(additionalStopPrice),
      extras: extras,
      sideDetourFee: _twoDecimals(sanitizedSideDetourFee),
      promoDiscount: _twoDecimals(promoDiscount),
      distanceInMiles: sanitizedDistance,
      isRoundTrip: isRoundTrip,
    );
  }

  static TripPriceBreakdown? airport({
    required CarModel? car,
    required double? distanceInMiles,
    required GratuityModel? gratuity,
    required bool isRoundTrip,
    required List<ExtraOptionModel> extraCatalog,
    required List<SelectedExtraOption> selectedExtras,
    AdditionalStopModel? additionalStop,
    AirportPickupPreferenceModel? pickupPreference,
    double promoDiscount = 0,
    double sideDetourFee = 0,
  }) {
    if (car == null || distanceInMiles == null || distanceInMiles <= 0) {
      return null;
    }

    final sanitizedDistance = distanceInMiles < 0 ? 0.0 : distanceInMiles;

    // Match website logic: vehicleFee * distance * (2 if round trip)
    // vehicleFee = pricePerMile
    double vehicleFeeTotal = car.pricePerMile * sanitizedDistance;
    if (isRoundTrip) {
      vehicleFeeTotal *= 2;
    }

    // Match website logic: minimumStartFee * (2 if round trip)
    final totalMinFee = isRoundTrip
        ? car.minimumStartFee * 2
        : car.minimumStartFee;

    // Base fare for gratuity calculation (includes both vehicle fee and minimum fee)
    final baseFare = _twoDecimals(vehicleFeeTotal + totalMinFee);

    final extras = _calculateExtras(
      isRoundTrip: isRoundTrip,
      extraCatalog: extraCatalog,
      selectedExtras: selectedExtras,
    );

    final additionalStopPrice = additionalStop?.additionalStopPrice ?? 0;
    final pickupPreferencePrice = pickupPreference?.preferencePrice ?? 0;

    // Match website/backend logic: added once, never doubled for round trip
    // (same treatment as additionalStopPrice/pickupPreferencePrice) — caller
    // passes 0 when there's no side-pick detour on this booking, or the
    // setting is off.
    final sanitizedSideDetourFee = sideDetourFee < 0 ? 0.0 : sideDetourFee;

    // Match website logic: totalFee = vehicleFee + totalMinFee + extras + additionalStop + pickupPreference
    final subtotal = _twoDecimals(
      vehicleFeeTotal +
          totalMinFee +
          extras +
          additionalStopPrice +
          pickupPreferencePrice +
          sanitizedSideDetourFee,
    );

    // See pointToPoint() above for why discount is subtracted before
    // gratuity is added, and why gratuity itself is computed on a
    // discount-scaled baseFare rather than the pre-discount figure.
    final discountedSubtotal = _twoDecimals(max(subtotal - promoDiscount, 0));
    final discountedBaseFare = _discountedCarFare(baseFare, subtotal, promoDiscount);
    final gratuityAmount = _calculateGratuity(discountedBaseFare, gratuity);
    final total = _twoDecimals(discountedSubtotal + gratuityAmount);

    return TripPriceBreakdown(
      currency: car.currency,
      baseFare: baseFare,
      subtotal: subtotal,
      total: total,
      gratuityAmount: gratuityAmount,
      gratuityPercentage: gratuity?.percentage,
      additionalStops: _twoDecimals(additionalStopPrice),
      extras: extras,
      pickupPreference: _twoDecimals(pickupPreferencePrice),
      sideDetourFee: _twoDecimals(sanitizedSideDetourFee),
      promoDiscount: _twoDecimals(promoDiscount),
      distanceInMiles: sanitizedDistance,
      isRoundTrip: isRoundTrip,
    );
  }

  static TripPriceBreakdown? hourlyCharter({
    required CarModel? car,
    required int? selectedHours,
    required GratuityModel? gratuity,
    required List<ExtraOptionModel> extraCatalog,
    required List<SelectedExtraOption> selectedExtras,
    double promoDiscount = 0,
  }) {
    if (car == null || selectedHours == null || selectedHours <= 0) {
      return null;
    }

    final hours = max(selectedHours, 1);

    // Hourly: fare is hours × pricePerHour only (no minimum start fee).
    final vehicleFeeTotal = car.pricePerHour * hours;
    final baseFare = _twoDecimals(vehicleFeeTotal);

    final extras = _calculateExtras(
      isRoundTrip: false,
      extraCatalog: extraCatalog,
      selectedExtras: selectedExtras,
    );

    final subtotal = _twoDecimals(vehicleFeeTotal + extras);

    // See pointToPoint() above for why discount is subtracted before
    // gratuity is added, and why gratuity itself is computed on a
    // discount-scaled baseFare rather than the pre-discount figure.
    // Gratuity applies to car fare only.
    final discountedSubtotal = _twoDecimals(max(subtotal - promoDiscount, 0));
    final discountedBaseFare = _discountedCarFare(baseFare, subtotal, promoDiscount);
    final gratuityAmount = _calculateGratuity(discountedBaseFare, gratuity);
    final total = _twoDecimals(discountedSubtotal + gratuityAmount);

    return TripPriceBreakdown(
      currency: car.currency,
      baseFare: baseFare,
      subtotal: subtotal,
      total: total,
      gratuityAmount: gratuityAmount,
      gratuityPercentage: gratuity?.percentage,
      extras: extras,
      otherAdjustments: 0,
      promoDiscount: _twoDecimals(promoDiscount),
      isRoundTrip: false,
    );
  }

  static double _calculateExtras({
    required bool isRoundTrip,
    required List<ExtraOptionModel> extraCatalog,
    required List<SelectedExtraOption> selectedExtras,
  }) {
    if (selectedExtras.isEmpty || extraCatalog.isEmpty) {
      return 0;
    }

    var total = 0.0;
    for (final selection in selectedExtras) {
      final option = extraCatalog.firstWhere(
        (element) => element.extraOptionId == selection.extraOptionId,
        orElse: () => _emptyExtra,
      );
      if (option.extraOptionId == 0) continue;

      final quantity = max(selection.quantity, 0);
      final optionTotal = option.pricePerItem * quantity;
      total += isRoundTrip ? optionTotal * 2 : optionTotal;
    }

    return _twoDecimals(total);
  }

  /// Scales [carFare] down by whatever fraction of [discount] falls on it,
  /// proportional to its share of [subtotal] — extras/stops/side-detour
  /// fees are never part of the gratuity base, discounted or not, same as
  /// before. Reduces to exactly [carFare] when there's no discount.
  static double _discountedCarFare(double carFare, double subtotal, double discount) {
    if (discount <= 0 || subtotal <= 0) return carFare;
    final carFareShareOfDiscount = (discount * carFare) / subtotal;
    return max(carFare - carFareShareOfDiscount, 0);
  }

  static double _calculateGratuity(double baseFare, GratuityModel? gratuity) {
    if (gratuity == null || gratuity.percentage <= 0) {
      return 0;
    }
    final gratuityAmount = baseFare * (gratuity.percentage / 100);
    return _twoDecimals(gratuityAmount);
  }

  static double _twoDecimals(double value) =>
      double.parse(value.toStringAsFixed(2));

  static const _emptyExtra = ExtraOptionModel(
    extraOptionId: 0,
    name: '',
    description: '',
    pricePerItem: 0,
    hasMaxAllowedLimit: false,
  );
}
