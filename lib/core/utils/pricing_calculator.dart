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
    this.otherAdjustments = 0,
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
  final double otherAdjustments;
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

    // Match website logic: totalFee = vehicleFee + totalMinFee + extras + additionalStop
    final subtotal = _twoDecimals(
      vehicleFeeTotal + totalMinFee + extras + additionalStopPrice,
    );

    // Gratuity is calculated on baseFare (vehicleFee + minimumStartFee)
    final gratuityAmount = _calculateGratuity(baseFare, gratuity);
    final total = _twoDecimals(subtotal + gratuityAmount);

    return TripPriceBreakdown(
      currency: car.currency,
      baseFare: baseFare,
      subtotal: subtotal,
      total: total,
      gratuityAmount: gratuityAmount,
      gratuityPercentage: gratuity?.percentage,
      additionalStops: _twoDecimals(additionalStopPrice),
      extras: extras,
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

    // Match website logic: totalFee = vehicleFee + totalMinFee + extras + additionalStop + pickupPreference
    final subtotal = _twoDecimals(
      vehicleFeeTotal +
          totalMinFee +
          extras +
          additionalStopPrice +
          pickupPreferencePrice,
    );

    // Gratuity is calculated on baseFare (vehicleFee + minimumStartFee)
    final gratuityAmount = _calculateGratuity(baseFare, gratuity);
    final total = _twoDecimals(subtotal + gratuityAmount);

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

    // Gratuity applies to car fare only.
    final gratuityAmount = _calculateGratuity(baseFare, gratuity);
    final total = _twoDecimals(subtotal + gratuityAmount);

    return TripPriceBreakdown(
      currency: car.currency,
      baseFare: baseFare,
      subtotal: subtotal,
      total: total,
      gratuityAmount: gratuityAmount,
      gratuityPercentage: gratuity?.percentage,
      extras: extras,
      otherAdjustments: 0,
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
