library book_ride_page;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeahead;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:oda_black_car_service/core/utils/booking_square_payment.dart';
import 'package:oda_black_car_service/core/utils/distance_utils.dart';
import 'package:oda_black_car_service/core/utils/pricing_calculator.dart';
import 'package:oda_black_car_service/core/config/square_runtime_config.dart';
import 'package:oda_black_car_service/data/models/additional_stop_model.dart';
import 'package:oda_black_car_service/data/models/airport_booking_request.dart';
import 'package:oda_black_car_service/data/models/airport_pickup_preference_model.dart';
import 'package:oda_black_car_service/data/models/card_details.dart';
import 'package:oda_black_car_service/core/exceptions/api_exception.dart';
import 'package:oda_black_car_service/core/utils/card_validation_utils.dart';
import 'package:oda_black_car_service/core/utils/name_validator.dart';
import 'package:oda_black_car_service/data/models/car_model.dart';
import 'package:oda_black_car_service/data/models/extra_option_model.dart';
import 'package:oda_black_car_service/data/models/gratuity_model.dart';
import 'package:oda_black_car_service/data/models/hourly_charter_booking_request.dart';
import 'package:oda_black_car_service/data/models/payment_detail_model.dart';
import 'package:oda_black_car_service/data/models/payment_method_type.dart';
import 'package:oda_black_car_service/data/models/point_to_point_booking_request.dart';
import 'package:oda_black_car_service/data/models/selected_extra_option.dart';
import 'package:oda_black_car_service/data/models/square_payment_payload.dart';
import 'package:oda_black_car_service/data/models/travel_type.dart';
import 'package:oda_black_car_service/data/services/directions_service.dart';
import 'package:oda_black_car_service/data/services/place_service.dart';
import 'package:oda_black_car_service/data/services/promo_code_service.dart';
import 'package:oda_black_car_service/core/referral/pending_referral_store.dart';
import 'package:oda_black_car_service/model/place_model.dart';
import 'package:oda_black_car_service/providers/auth_provider.dart';
import 'package:oda_black_car_service/providers/booking_provider.dart';
import 'package:oda_black_car_service/providers/catalog_provider.dart';
import 'package:oda_black_car_service/providers/payment_provider.dart';
import 'package:oda_black_car_service/ui/theme/app_tokens.dart';
import 'package:oda_black_car_service/ui/widgets/app_error_banner.dart';
import 'package:oda_black_car_service/ui/widgets/custom_snackbar.dart';
import 'widgets/square_payment_method_section.dart';

part 'forms/point_to_point_form.dart';
part 'forms/airport_booking_form.dart';
part 'forms/hourly_charter_form.dart';

// Constants
const _kMapInitDelay = Duration(milliseconds: 500);
const _kMapTileCheckDelay = Duration(seconds: 2);
const _kMapTimeout = Duration(seconds: 8);
const _kDefaultBorderRadius = BorderRadius.all(Radius.circular(20));
const _kDefaultZoom = 13.0;
const _kDefaultUSZoom = 5.0;
const LatLng _kDefaultUSTarget = LatLng(39.8283, -98.5795);

bool _isUnitedStatesLocation(PlaceDetail detail) {
  final code = detail.countryCode?.toUpperCase();
  if (code != null) return code == 'US';
  final address = detail.formattedAddress.toLowerCase();
  return address.contains('united states') || address.endsWith(' usa');
}

class BookRidePage extends StatefulWidget {
  const BookRidePage({super.key});

  @override
  State<BookRidePage> createState() => _BookRidePageState();
}

class _BookRidePageState extends State<BookRidePage> {
  final _scrollController = ScrollController();
  final _airportFormKey = GlobalKey<FormState>();
  double _savedScrollPosition = 0.0;
  static _BookRidePageState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
  }

  @override
  void dispose() {
    _instance = null;
    _scrollController.dispose();
    super.dispose();
  }

  // Method to save current scroll position (called before opening pickers)
  void saveScrollPosition() {
    if (_scrollController.hasClients) {
      _savedScrollPosition = _scrollController.offset;
    }
  }

  // Method to restore scroll position (called after closing pickers)
  void restoreScrollPosition() {
    if (_scrollController.hasClients && _savedScrollPosition > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollController.jumpTo(_savedScrollPosition);
        }
      });
    }
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // Static method to access scroll control from forms
  static void saveScrollPositionStatic() {
    _instance?.saveScrollPosition();
  }

  static void restoreScrollPositionStatic() {
    _instance?.restoreScrollPosition();
  }

  static void scrollToTopStatic() {
    _instance?.scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final travelType = bookingProvider.selectedTravelType;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(travelType: travelType),
            const SizedBox(height: AppSpacing.md),
            _TravelTypeSelector(current: travelType),
            const SizedBox(height: AppSpacing.lg),
            AnimatedSwitcher(
              duration: Duration.zero,
              switchInCurve: Curves.linear,
              switchOutCurve: Curves.linear,
              layoutBuilder: (currentChild, previousChildren) => currentChild!,
              child: switch (travelType) {
                TravelType.pointToPoint =>
                  const _PointToPointForm(key: ValueKey('p2p')),
                TravelType.airport => AirportBookingForm(
                    key: const ValueKey('airport'),
                    formKey: _airportFormKey,
                  ),
                TravelType.hourlyCharter =>
                  const _HourlyCharterForm(key: ValueKey('hourly')),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.travelType});

  final TravelType travelType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (travelType) {
      TravelType.pointToPoint => Icons.route_rounded,
      TravelType.airport => Icons.flight_takeoff_rounded,
      TravelType.hourlyCharter => Icons.schedule_rounded,
    };

    final headline = switch (travelType) {
      TravelType.pointToPoint => 'Point to point luxury rides',
      TravelType.airport => 'Airport pickups & drop-offs',
      TravelType.hourlyCharter => 'Hourly chauffeur service',
    };

    final subtitle = switch (travelType) {
      TravelType.pointToPoint =>
        'Select your origin and destination to see real-time pricing.',
      TravelType.airport =>
        'Arrive refreshed with curated airport pickup preferences.',
      TravelType.hourlyCharter =>
        'Reserve premium vehicles by the hour for events and more.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelTypeSelector extends StatelessWidget {
  const _TravelTypeSelector({required this.current});

  final TravelType current;

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.read<BookingProvider>();
    return SegmentedButton<TravelType>(
      segments: const [
        ButtonSegment(
          value: TravelType.airport,
          icon: Icon(Icons.flight_rounded),
          label: Text('Airport'),
        ),
        ButtonSegment(
          value: TravelType.pointToPoint,
          icon: Icon(Icons.alt_route_rounded),
          label: Text('Point to Point'),
        ),
        ButtonSegment(
          value: TravelType.hourlyCharter,
          icon: Icon(Icons.schedule_rounded),
          label: Text('Hourly'),
        ),
      ],
      selected: {current},
      onSelectionChanged: (value) {
        if (value.isNotEmpty) {
          bookingProvider.setTravelType(value.first);
        }
      },
    );
  }
}

class _JourneyPlannerPreview extends StatelessWidget {
  const _JourneyPlannerPreview({
    required this.currentStep,
    required this.serviceLabel,
    required this.originLabel,
    required this.destinationLabel,
    required this.passengers,
    required this.suitcases,
    this.origin,
    this.destination,
    this.originAddress,
    this.destinationAddress,
    this.distanceInMiles,
    this.durationOverride,
    this.onPickOnMap,
  });

  final int currentStep;
  final String serviceLabel;
  final String originLabel;
  final String destinationLabel;
  final LatLng? origin;
  final LatLng? destination;
  final String? originAddress;
  final String? destinationAddress;
  final double? distanceInMiles;
  final int passengers;
  final int suitcases;
  final String? durationOverride;
  final VoidCallback? onPickOnMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRoute = origin != null && destination != null;
    final distanceValue = distanceInMiles;
    final distanceText = distanceValue != null
        // Match website: always use 2 decimal places
        ? '${distanceValue.toStringAsFixed(2)} miles'
        : 'Pending';
    final durationText = durationOverride ?? _formatDuration();
    final durationLabel = durationText ?? 'Pending';
    final distanceLabel = hasRoute ? distanceText : 'Pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookingProgressStepper(currentStep: currentStep),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: _kDefaultBorderRadius,
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _RoutePreviewMap(
                          origin: origin,
                          destination: destination,
                          distanceInMiles: distanceInMiles,
                        ),
                      ),
                      if (onPickOnMap != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.edit_location_alt_outlined),
                            label: const Text('Pick on map'),
                            onPressed: onPickOnMap,
                          ),
                        ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasRoute
                                    ? 'Distance: $distanceText'
                                    : 'Set pickup & drop-off',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                hasRoute
                                    ? 'Duration: ${durationText ?? '—'}'
                                    : 'We\'ll calculate distance & ETA here.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _MetricChip(
                    icon: Icons.location_on_outlined,
                    label: originLabel,
                    value: originAddress ?? 'Awaiting selection',
                  ),
                  _MetricChip(
                    icon: Icons.flag_outlined,
                    label: destinationLabel,
                    value: destinationAddress ?? 'Awaiting selection',
                  ),
                  _MetricChip(
                    icon: Icons.groups_2_outlined,
                    label: 'Passengers',
                    value: '$passengers',
                  ),
                  _MetricChip(
                    icon: Icons.luggage_outlined,
                    label: 'Suitcases',
                    value: '$suitcases',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Distance: $distanceLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Duration: $durationLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _formatDuration() {
    if (distanceInMiles == null) return null;
    final minutes = (distanceInMiles! / 40 * 60).clamp(15, 600).round();
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return '$remaining mins';
    if (remaining == 0) return '$hours h';
    return '$hours h $remaining mins';
  }
}

class _RoutePreviewMap extends StatelessWidget {
  const _RoutePreviewMap({
    this.origin,
    this.destination,
    this.distanceInMiles,
  });

  final LatLng? origin;
  final LatLng? destination;
  final double? distanceInMiles;

  @override
  Widget build(BuildContext context) {
    return _NativeRoutePreview(
      origin: origin,
      destination: destination,
      distanceInMiles: distanceInMiles,
    );
  }
}

class _NativeRoutePreview extends StatefulWidget {
  const _NativeRoutePreview({
    required this.origin,
    required this.destination,
    required this.distanceInMiles,
  });

  final LatLng? origin;
  final LatLng? destination;
  final double? distanceInMiles;

  @override
  State<_NativeRoutePreview> createState() => _NativeRoutePreviewState();
}

class _NativeRoutePreviewState extends State<_NativeRoutePreview> {
  MapType _mapType = MapType.normal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markers = _buildMarkers();
    final polylines = _buildPolylines(theme);
    final useLiteMode = defaultTargetPlatform == TargetPlatform.android;

    return Stack(
      children: [
        GoogleMap(
          mapType: _mapType,
          liteModeEnabled: useLiteMode,
          initialCameraPosition: CameraPosition(
            target: _resolveCameraTarget(),
            zoom: _initialZoom(),
          ),
          markers: markers,
          polylines: polylines,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          myLocationButtonEnabled: false,
          myLocationEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: true,
          buildingsEnabled: true,
          trafficEnabled: false,
        ),
        Positioned(
          top: 12,
          left: 12,
          child: _MapTypeToggle(
            value: _mapType,
            onChanged: (type) => setState(() => _mapType = type),
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (widget.origin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (widget.destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(ThemeData theme) {
    if (widget.origin == null || widget.destination == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('journey-preview'),
        color: theme.colorScheme.primary,
        width: 4,
        points: [widget.origin!, widget.destination!],
        patterns: [PatternItem.dash(30), PatternItem.gap(10)],
      ),
    };
  }

  LatLng _resolveCameraTarget() {
    if (widget.origin != null && widget.destination != null) {
      return LatLng(
        (widget.origin!.latitude + widget.destination!.latitude) / 2,
        (widget.origin!.longitude + widget.destination!.longitude) / 2,
      );
    }
    if (widget.origin != null) return widget.origin!;
    if (widget.destination != null) return widget.destination!;
    return _kDefaultUSTarget;
  }

  double _initialZoom() {
    if (widget.origin != null && widget.destination != null) {
      return _zoomForDistance(widget.distanceInMiles);
    }
    if (widget.origin != null || widget.destination != null) {
      return _kDefaultZoom;
    }
    return _kDefaultUSZoom;
  }

  double _zoomForDistance(double? distance) {
    if (distance == null) return _kDefaultUSZoom;
    if (distance < 5) return 12.5;
    if (distance < 15) return 11.5;
    if (distance < 35) return 10.5;
    if (distance < 80) return 9;
    if (distance < 150) return 8;
    return 6.5;
  }
}

enum _RoutePointMode { pickup, dropoff }

class _RouteSelectionResult {
  const _RouteSelectionResult({
    required this.pickup,
    required this.dropoff,
    this.distanceInMiles,
    this.durationText,
  });

  final PlaceDetail pickup;
  final PlaceDetail dropoff;
  final double? distanceInMiles;
  final String? durationText;
}

class _RouteMapPickerSheet extends StatefulWidget {
  const _RouteMapPickerSheet({
    this.initialPickup,
    this.initialDropoff,
  });

  final PlaceDetail? initialPickup;
  final PlaceDetail? initialDropoff;

  @override
  State<_RouteMapPickerSheet> createState() => _RouteMapPickerSheetState();
}

class _RouteMapPickerSheetState extends State<_RouteMapPickerSheet> {
  final PlaceService _placeService = PlaceService();
  final DirectionsService _directionsService = DirectionsService();
  _RoutePointMode _mode = _RoutePointMode.pickup;

  PlaceDetail? _pickupDetail;
  PlaceDetail? _dropoffDetail;
  DirectionsRoute? _route;
  bool _isResolving = false;
  bool _isCalculatingRoute = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _pickupDetail = widget.initialPickup;
    _dropoffDetail = widget.initialDropoff;
    if (_pickupDetail != null && _dropoffDetail != null) {
      _fetchRoute();
    }
  }

  @override
  void dispose() {
    // GoogleMap disposes its controller when removed from the tree.
    // Manual dispose causes "_dependents.isEmpty" while the map fades out.
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: media.size.height * 0.92,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 16,
          right: 16,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.explore_outlined),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Plan with Google Maps',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<_RoutePointMode>(
              segments: const [
                ButtonSegment(
                  value: _RoutePointMode.pickup,
                  icon: Icon(Icons.location_on_outlined),
                  label: Text('Set pickup'),
                ),
                ButtonSegment(
                  value: _RoutePointMode.dropoff,
                  icon: Icon(Icons.flag_outlined),
                  label: Text('Set drop-off'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _mode = value.first;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Tap anywhere on the map to select a ${_mode == _RoutePointMode.pickup ? 'pickup' : 'drop-off'} point. We\'ll reverse geocode the exact address and calculate the driving distance via Google Directions.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _initialCameraTarget,
                        zoom: _initialZoom,
                      ),
                      onTap: _handleTap,
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _buildMarkers(),
                      polylines: _buildPolylines(theme),
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: false,
                    ),
                    if (_isResolving || _isCalculatingRoute)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.25),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  _isResolving
                                      ? 'Looking up address…'
                                      : 'Calculating route…',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.location_on,
                  label: 'Pickup',
                  value: _pickupDetail?.formattedAddress ?? 'Tap map to select',
                ),
                _MetricChip(
                  icon: Icons.flag,
                  label: 'Drop-off',
                  value:
                      _dropoffDetail?.formattedAddress ?? 'Tap map to select',
                ),
                if (_route != null)
                  _MetricChip(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value:
                        // Match website: always use 2 decimal places
                        '${_route!.distanceMiles.toStringAsFixed(2)} miles',
                  ),
                if (_route?.durationText != null)
                  _MetricChip(
                    icon: Icons.timer_outlined,
                    label: 'ETA',
                    value: _route!.durationText!,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Use these points'),
                    onPressed: _pickupDetail != null && _dropoffDetail != null
                        ? _confirmSelection
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_pickupDetail != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _toLatLng(_pickupDetail!),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (_dropoffDetail != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _toLatLng(_dropoffDetail!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines(ThemeData theme) {
    if (_route == null || _route!.polyline.isEmpty) return const {};
    return {
      Polyline(
        polylineId: const PolylineId('preview-route'),
        points: _route!.polyline,
        color: theme.colorScheme.primary,
        width: 5,
      ),
    };
  }

  LatLng get _initialCameraTarget {
    if (_pickupDetail != null && _dropoffDetail != null) {
      final pickup = _toLatLng(_pickupDetail!);
      final dropoff = _toLatLng(_dropoffDetail!);
      return LatLng(
        (pickup.latitude + dropoff.latitude) / 2,
        (pickup.longitude + dropoff.longitude) / 2,
      );
    }
    if (_pickupDetail != null) return _toLatLng(_pickupDetail!);
    if (_dropoffDetail != null) return _toLatLng(_dropoffDetail!);
    return _kDefaultUSTarget;
  }

  double get _initialZoom {
    if (_pickupDetail != null && _dropoffDetail != null) {
      final distance = haversineDistanceInMiles(
        startLat: _pickupDetail!.lat,
        startLng: _pickupDetail!.lng,
        endLat: _dropoffDetail!.lat,
        endLng: _dropoffDetail!.lng,
      );
      if (distance < 5) return 13;
      if (distance < 15) return 12;
      if (distance < 35) return 10.5;
      if (distance < 80) return 9;
      if (distance < 150) return 8;
      return 7;
    }
    return 11;
  }

  Future<void> _handleTap(LatLng position) async {
    setState(() {
      _isResolving = true;
    });
    try {
      final detail = await _placeService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (detail == null) return;
      setState(() {
        if (_mode == _RoutePointMode.pickup) {
          _pickupDetail = detail;
        } else {
          _dropoffDetail = detail;
        }
        _route = null;
      });
      if (_pickupDetail != null && _dropoffDetail != null) {
        await _fetchRoute();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_pickupDetail == null || _dropoffDetail == null) return;
    setState(() {
      _isCalculatingRoute = true;
    });
    try {
      final route = await _directionsService.fetchRoute(
        origin: _toLatLng(_pickupDetail!),
        destination: _toLatLng(_dropoffDetail!),
      );
      setState(() {
        _route = route;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _confirmSelection() {
    if (_pickupDetail == null || _dropoffDetail == null) return;
    Navigator.pop(
      context,
      _RouteSelectionResult(
        pickup: _pickupDetail!,
        dropoff: _dropoffDetail!,
        distanceInMiles: _route?.distanceMiles,
        durationText: _route?.durationText,
      ),
    );
  }

  LatLng _toLatLng(PlaceDetail detail) =>
      LatLng(detail.lat.toDouble(), detail.lng.toDouble());
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall,
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingProgressStepper extends StatelessWidget {
  const _BookingProgressStepper({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const steps = [
      _StepperStepData(label: 'Ride Info', icon: Icons.assignment_turned_in),
      _StepperStepData(label: 'Vehicle', icon: Icons.directions_car_filled),
      _StepperStepData(label: 'Trip Detail', icon: Icons.list_alt),
      _StepperStepData(label: 'Contact', icon: Icons.call),
      _StepperStepData(label: 'Summary', icon: Icons.receipt_long),
    ];
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: i < currentStep
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Icon(
                        steps[i].icon,
                        size: 18,
                        color: i < currentStep
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i].label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight:
                            i < currentStep ? FontWeight.w600 : FontWeight.w400,
                        color: i < currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != steps.length - 1)
                SizedBox(
                  width: constraints.maxWidth * 0.02,
                  child: Divider(
                    thickness: 2,
                    color: i < currentStep - 1
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StepperStepData {
  const _StepperStepData({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _VehicleShowcase extends StatelessWidget {
  const _VehicleShowcase({
    required this.cars,
    required this.selectedCarId,
    required this.onSelect,
    required this.passengers,
    required this.suitcases,
    required this.summaryItems,
    this.distanceInMiles,
    this.isRoundTrip = false,
    this.selectedHours,
  });

  final List<CarModel> cars;
  final int? selectedCarId;
  final ValueChanged<int> onSelect;
  final int passengers;
  final int suitcases;
  final List<_SummaryItem> summaryItems;
  final double? distanceInMiles;
  final bool isRoundTrip;
  final int? selectedHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (cars.isEmpty) {
      return Card(
        elevation: 0,
        shape:
            const RoundedRectangleBorder(borderRadius: _kDefaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No vehicles available for the current parameters. Please adjust your search.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your vehicle',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _TripSummaryBoard(
          items: summaryItems,
          passengers: passengers,
          suitcases: suitcases,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cars.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final car = cars[index];
            final isSelected = selectedCarId == car.carId;
            return _VehicleCard(
              car: car,
              distanceInMiles: distanceInMiles,
              isSelected: isSelected,
              isRoundTrip: isRoundTrip,
              selectedHours: selectedHours,
              onTap: () => onSelect(car.carId),
            );
          },
        ),
      ],
    );
  }
}

class _TripSummaryBoard extends StatelessWidget {
  const _TripSummaryBoard({
    required this.items,
    required this.passengers,
    required this.suitcases,
  });

  final List<_SummaryItem> items;
  final int passengers;
  final int suitcases;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: theme.colorScheme.outline.withOpacity(0.4)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: Icons.groups_2_outlined,
                  label: 'Passengers',
                  value: '$passengers',
                ),
                _MetricChip(
                  icon: Icons.luggage_outlined,
                  label: 'Suitcases',
                  value: '$suitcases',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.car,
    required this.isSelected,
    required this.onTap,
    this.distanceInMiles,
    this.isRoundTrip = false,
    this.selectedHours,
  });

  final CarModel car;
  final bool isSelected;
  final VoidCallback onTap;
  final double? distanceInMiles;
  final bool isRoundTrip;
  final int? selectedHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estimatedPrice = _estimatedPrice();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  car.carName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'from $estimatedPrice',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            car.carDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: car.carImageUrl != null && car.carImageUrl!.isNotEmpty
                  ? Image.network(
                      car.carImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _VehicleImagePlaceholder(
                        label: car.carType,
                      ),
                    )
                  : _VehicleImagePlaceholder(label: car.carType),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.people_alt_outlined,
                label: 'Capacity',
                value: '${car.maxPassengers} pax',
              ),
              _MetricChip(
                icon: Icons.cases_outlined,
                label: 'Luggage',
                value: '${car.maxSuitcases} bags',
              ),
              _MetricChip(
                icon: Icons.directions_car_filled,
                label: 'Class',
                value: car.carType,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTap,
                  child: Text(isSelected ? 'Selected' : 'Select'),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                selectedHours != null && selectedHours! > 0
                    ? '${_formatCurrency(car.pricePerHour, car.currency)}/hr'
                    : 'Min fare ${_formatCurrency(
                        isRoundTrip
                            ? car.minimumStartFee * 2
                            : car.minimumStartFee,
                        car.currency,
                      )}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _estimatedPrice() {
    // Match website logic for hourly charter: pricePerHour * hour (no minimumStartFee in display)
    if (selectedHours != null && selectedHours! > 0) {
      final calculatedFee = car.pricePerHour * selectedHours!;
      return _formatCurrency(calculatedFee, car.currency);
    }

    // Match website logic: double values for round trip
    final base = isRoundTrip ? car.minimumStartFee * 2 : car.minimumStartFee;
    if (distanceInMiles == null || distanceInMiles! <= 0) {
      return _formatCurrency(base, car.currency);
    }
    // Match website logic: vehicleFee * distance * (2 if round trip)
    final vehicleFee = car.pricePerMile * distanceInMiles!;
    final vehicleFeeTotal = isRoundTrip ? vehicleFee * 2 : vehicleFee;
    final total = base + vehicleFeeTotal;
    return _formatCurrency(total, car.currency);
  }
}

class _VehicleImagePlaceholder extends StatelessWidget {
  const _VehicleImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_filled,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            Text(
              label,
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;
}

/// Full interactive Google Map for Hourly Charter that loads immediately
class _HourlyCharterMap extends StatefulWidget {
  const _HourlyCharterMap({
    this.pickup,
    this.dropoff,
    this.routePolyline,
    this.routeDistance,
    this.routeDuration,
    this.waypoints,
  });

  final PlaceDetail? pickup;
  final PlaceDetail? dropoff;
  final List<LatLng>? routePolyline;
  final double? routeDistance;
  final String? routeDuration;
  // Side pick / detour stops, in visit order — rendered as numbered markers
  // and folded into the camera bounds so the map stays in sync as they're
  // added, edited, or removed.
  final List<PlaceDetail>? waypoints;

  @override
  State<_HourlyCharterMap> createState() => _HourlyCharterMapState();
}

class _HourlyCharterMapState extends State<_HourlyCharterMap> {
  GoogleMapController? _mapController;
  final PlaceService _placeService = PlaceService();
  LatLng? _clickedLocation;
  bool _isMapReady = false;
  String? _mapError;
  bool _mapTilesLoaded = false;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    // Set a timeout to detect if map fails to load
    Future.delayed(_kMapTimeout, () {
      if (mounted && !_mapTilesLoaded && _isMapReady) {
        setState(() {
          _mapError =
              'Map tiles failed to load. Please check:\n1. Internet connection\n2. Google Maps API key is valid\n3. API key has Maps SDK for Android enabled';
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  List<LatLng> _waypointLatLngs(List<PlaceDetail>? details) =>
      (details ?? const [])
          .map((d) => LatLng(d.lat, d.lng))
          .toList(growable: false);

  @override
  void didUpdateWidget(_HourlyCharterMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update camera position when locations, route, or side-pick stops
    // change (like DirectionsRenderer).
    final locationsChanged =
        (widget.pickup != null || widget.dropoff != null) &&
            (oldWidget.pickup != widget.pickup ||
                oldWidget.dropoff != widget.dropoff);
    final routeChanged = widget.routePolyline != oldWidget.routePolyline;
    final waypointsChanged = !listEquals(
      _waypointLatLngs(oldWidget.waypoints),
      _waypointLatLngs(widget.waypoints),
    );

    if ((locationsChanged || routeChanged || waypointsChanged) && _isMapReady) {
      // If we have a route polyline, fit bounds to it (like DirectionsRenderer)
      if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
        _fitBoundsToRoute();
      } else {
        _updateCameraPosition();
      }
    }
  }

  /// Fit bounds to route polyline (like DirectionsRenderer does automatically)
  void _fitBoundsToRoute() {
    if (_mapController == null ||
        widget.routePolyline == null ||
        widget.routePolyline!.isEmpty) {
      return;
    }

    // Calculate bounds from route polyline points
    double minLat = widget.routePolyline!.first.latitude;
    double maxLat = widget.routePolyline!.first.latitude;
    double minLng = widget.routePolyline!.first.longitude;
    double maxLng = widget.routePolyline!.first.longitude;

    for (final point in widget.routePolyline!) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Also include pickup and dropoff markers in bounds
    if (widget.pickup != null) {
      if (widget.pickup!.lat < minLat) minLat = widget.pickup!.lat;
      if (widget.pickup!.lat > maxLat) maxLat = widget.pickup!.lat;
      if (widget.pickup!.lng < minLng) minLng = widget.pickup!.lng;
      if (widget.pickup!.lng > maxLng) maxLng = widget.pickup!.lng;
    }
    if (widget.dropoff != null) {
      if (widget.dropoff!.lat < minLat) minLat = widget.dropoff!.lat;
      if (widget.dropoff!.lat > maxLat) maxLat = widget.dropoff!.lat;
      if (widget.dropoff!.lng < minLng) minLng = widget.dropoff!.lng;
      if (widget.dropoff!.lng > maxLng) maxLng = widget.dropoff!.lng;
    }
    // Also include side-pick/detour stops, so a newly added stop is always
    // visible even before the polyline finishes re-fetching.
    for (final stop in widget.waypoints ?? const <PlaceDetail>[]) {
      if (stop.lat < minLat) minLat = stop.lat;
      if (stop.lat > maxLat) maxLat = stop.lat;
      if (stop.lng < minLng) minLng = stop.lng;
      if (stop.lng > maxLng) maxLng = stop.lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Fit bounds with padding (like DirectionsRenderer)
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80.0),
    );
  }

  void _updateCameraPosition() {
    if (_mapController == null) return;
    if (widget.pickup != null && widget.dropoff != null) {
      final pickup = LatLng(widget.pickup!.lat, widget.pickup!.lng);
      final dropoff = LatLng(widget.dropoff!.lat, widget.dropoff!.lng);
      final center = LatLng(
        (pickup.latitude + dropoff.latitude) / 2,
        (pickup.longitude + dropoff.longitude) / 2,
      );
      final distance = haversineDistanceInMiles(
        startLat: pickup.latitude,
        startLng: pickup.longitude,
        endLat: dropoff.latitude,
        endLng: dropoff.longitude,
      );
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            zoom: _zoomForDistance(distance),
          ),
        ),
      );
    } else if (widget.pickup != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.pickup!.lat, widget.pickup!.lng),
            zoom: _kDefaultZoom,
          ),
        ),
      );
    } else if (widget.dropoff != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(widget.dropoff!.lat, widget.dropoff!.lng),
            zoom: 13,
          ),
        ),
      );
    }
  }

  double _zoomForDistance(double? distance) {
    if (distance == null) return 6; // Default US view
    if (distance < 5) return 13;
    if (distance < 15) return 12;
    if (distance < 35) return 10.5;
    if (distance < 80) return 9;
    if (distance < 150) return 8;
    if (distance < 500) return 6;
    return 5; // Cross-country view
  }

  LatLng _getInitialCameraTarget() {
    // Only change center if both pickup and dropoff are set
    if (widget.pickup != null && widget.dropoff != null) {
      final pickup = LatLng(widget.pickup!.lat, widget.pickup!.lng);
      final dropoff = LatLng(widget.dropoff!.lat, widget.dropoff!.lng);
      return LatLng(
        (pickup.latitude + dropoff.latitude) / 2,
        (pickup.longitude + dropoff.longitude) / 2,
      );
    }
    if (widget.pickup != null) {
      return LatLng(widget.pickup!.lat, widget.pickup!.lng);
    }
    if (widget.dropoff != null) {
      return LatLng(widget.dropoff!.lat, widget.dropoff!.lng);
    }
    // Default: Center of US, since pickup/drop-off can be anywhere nationwide
    return _kDefaultUSTarget;
  }

  double _getInitialZoom() {
    // Only change zoom if both pickup and dropoff are set
    if (widget.pickup != null && widget.dropoff != null) {
      final distance = haversineDistanceInMiles(
        startLat: widget.pickup!.lat,
        startLng: widget.pickup!.lng,
        endLat: widget.dropoff!.lat,
        endLng: widget.dropoff!.lng,
      );
      return _zoomForDistance(distance);
    }
    if (widget.pickup != null || widget.dropoff != null) {
      return 13;
    }
    // Default: US-wide view
    return 5;
  }

  Future<void> _handleMapTap(LatLng position) async {
    // Match React website: handleMapClick - reverse geocode the clicked location
    try {
      final detail = await _placeService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (detail != null && mounted) {
        setState(() {
          _clickedLocation = position;
        });
        // Location clicked and reverse geocoded
      }
    } catch (e) {
      // Silently handle geocoding errors
      if (kDebugMode) {
        debugPrint('Geocoder failed: $e');
      }
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    // Show clicked location marker (like React website)
    if (_clickedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('clicked'),
          position: _clickedLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }
    if (widget.pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickup!.lat, widget.pickup!.lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'A',
            snippet: widget.pickup!.formattedAddress,
          ),
        ),
      );
    }
    if (widget.dropoff != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.dropoff!.lat, widget.dropoff!.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'B',
            snippet: widget.dropoff!.formattedAddress,
          ),
        ),
      );
    }
    // Side-pick / detour stops — numbered amber markers between A and B so
    // the map visibly confirms each stop the moment it's added.
    final waypoints = widget.waypoints ?? const <PlaceDetail>[];
    for (var i = 0; i < waypoints.length; i++) {
      final stop = waypoints[i];
      markers.add(
        Marker(
          markerId: MarkerId('waypoint-$i'),
          position: LatLng(stop.lat, stop.lng),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Stop ${i + 1}',
            snippet: stop.formattedAddress,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (widget.routePolyline != null && widget.routePolyline!.isNotEmpty) {
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: widget.routePolyline!,
          color: Theme.of(context).colorScheme.primary,
          width: 5,
          geodesic: true,
        ),
      };
    }
    // Fallback: straight line if no route polyline
    if (widget.pickup != null && widget.dropoff != null) {
      return {
        Polyline(
          polylineId: const PolylineId('straight-line'),
          points: [
            LatLng(widget.pickup!.lat, widget.pickup!.lng),
            LatLng(widget.dropoff!.lat, widget.dropoff!.lng),
          ],
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _getInitialCameraTarget(),
                zoom: _getInitialZoom(),
              ),
              mapType: _mapType,
              onMapCreated: (controller) {
                _mapController = controller;
                setState(() {
                  _isMapReady = true;
                  _mapError = null;
                });
                // Check if tiles load after a delay
                Future.delayed(_kMapTileCheckDelay, () {
                  if (mounted) {
                    setState(() {
                      _mapTilesLoaded = true;
                    });
                  }
                });
                // Update camera position if locations or route are already set
                // Match DirectionsRenderer behavior: fit bounds to route if available
                if (widget.pickup != null || widget.dropoff != null) {
                  // Use a small delay to ensure map is fully initialized
                  Future.delayed(_kMapInitDelay, () {
                    if (mounted && _mapController != null) {
                      // If route polyline exists, fit bounds (like DirectionsRenderer)
                      if (widget.routePolyline != null &&
                          widget.routePolyline!.isNotEmpty) {
                        _fitBoundsToRoute();
                      } else {
                        _updateCameraPosition();
                      }
                    }
                  });
                }
              },
              onTap: _handleMapTap,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              zoomControlsEnabled: true,
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
              myLocationButtonEnabled: false,
              myLocationEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              buildingsEnabled: true,
              trafficEnabled: false,
              liteModeEnabled: false, // Ensure full map mode
            ),
            Positioned(
              top: 12,
              left: 12,
              child: _MapTypeToggle(
                value: _mapType,
                onChanged: (type) => setState(() => _mapType = type),
              ),
            ),
            // Loading indicator while map initializes
            if (!_isMapReady && _mapError == null)
              Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: AppSpacing.md),
                      Text('Loading map...'),
                    ],
                  ),
                ),
              ),
            // Error message if map fails to load
            if (_mapError != null)
              Container(
                color: Colors.grey[300],
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Map failed to load',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _mapError!,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isMapReady = false;
                              _mapTilesLoaded = false;
                              _mapError = null;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapTypeToggle extends StatelessWidget {
  const _MapTypeToggle({
    required this.value,
    required this.onChanged,
  });

  final MapType value;
  final ValueChanged<MapType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSatellite = value == MapType.hybrid || value == MapType.satellite;

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(24),
      color: theme.colorScheme.surface.withOpacity(0.9),
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(24),
        constraints: const BoxConstraints(minHeight: 34, minWidth: 72),
        isSelected: [!isSatellite, isSatellite],
        selectedColor: theme.colorScheme.onPrimary,
        fillColor: theme.colorScheme.primary,
        color: theme.colorScheme.onSurface,
        onPressed: (index) {
          final target = index == 0 ? MapType.normal : MapType.hybrid;
          if (target != value) {
            onChanged(target);
          }
        },
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Map'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('Satellite'),
          ),
        ],
      ),
    );
  }
}

class _TripTypeSelector extends StatelessWidget {
  const _TripTypeSelector({
    required this.tripType,
    required this.onChanged,
  });

  final String tripType;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('One-way'),
            value: 'One-Way',
            groupValue: tripType,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('Round trip'),
            value: 'Round-Trip',
            groupValue: tripType,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _LocationPickerField extends StatefulWidget {
  const _LocationPickerField({
    required this.controller,
    required this.placeService,
    required this.sessionToken,
    required this.onPlaceSelected,
    required this.label,
    this.country,
    this.hintText,
    this.helperText,
    this.prefixIcon = Icons.location_on_outlined,
    this.suggestionIcon = Icons.place_outlined,
    this.onCleared,
  });

  final TextEditingController controller;
  final PlaceService placeService;
  final String sessionToken;
  final ValueChanged<PlaceDetail> onPlaceSelected;
  final String label;
  final String? country;
  final String? hintText;
  final String? helperText;
  final IconData prefixIcon;
  final IconData suggestionIcon;
  final VoidCallback? onCleared;

  @override
  State<_LocationPickerField> createState() => _LocationPickerFieldState();
}

class _LocationPickerFieldState extends State<_LocationPickerField> {
  String? _lastSelectedSuggestion;
  FocusNode? _attachedFocusNode;
  VoidCallback? _focusListener;

  @override
  void dispose() {
    _detachFocusListener();
    super.dispose();
  }

  void _detachFocusListener() {
    if (_attachedFocusNode != null && _focusListener != null) {
      _attachedFocusNode!.removeListener(_focusListener!);
    }
    _attachedFocusNode = null;
    _focusListener = null;
  }

  void _attachFocusListener(FocusNode focusNode) {
    if (_attachedFocusNode == focusNode) return;
    _detachFocusListener();
    _attachedFocusNode = focusNode;
    _focusListener = () {
      if (!focusNode.hasFocus) return;
      _BookRidePageState.saveScrollPositionStatic();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _BookRidePageState.restoreScrollPositionStatic();
      });
    };
    focusNode.addListener(_focusListener!);
  }

  @override
  Widget build(BuildContext context) {
    return typeahead.TypeAheadField<Place>(
      controller: widget.controller,
      suggestionsCallback: (pattern) async {
        // Allow search with just 1 character for better responsiveness
        // This enables searching for ANY location via Google Places Autocomplete, not limited to presets
        if (pattern.trim().isEmpty) return const [];
        final normalizedPattern = pattern.trim().toLowerCase();
        if (_lastSelectedSuggestion == normalizedPattern) {
          return const [];
        }
        try {
          // Search any location worldwide (restricted by country parameter if needed)
          return await widget.placeService.fetchSuggestions(
            pattern,
            sessionToken: widget.sessionToken,
            country: widget.country,
          );
        } catch (e) {
          // Silently handle errors - return empty list
          if (kDebugMode) {
            debugPrint('Autocomplete error: $e');
          }
          return const [];
        }
      },
      itemBuilder: (context, suggestion) => ListTile(
        leading: Icon(
          widget.suggestionIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          suggestion.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        dense: true,
      ),
      onSelected: (suggestion) async {
        widget.controller.text = suggestion.description;
        _lastSelectedSuggestion = suggestion.description.trim().toLowerCase();
        try {
          final detail = await widget.placeService.fetchPlaceDetail(
            suggestion.placeId,
            sessionToken: widget.sessionToken,
          );
          widget.onPlaceSelected(detail);
        } catch (e) {
          // Handle error - show snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load place details: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      hideOnEmpty: false,
      hideOnError: true,
      hideOnLoading: false,
      hideOnSelect: true,
      debounceDuration: const Duration(milliseconds: 300),
      builder: (context, textEditingController, focusNode) {
        _attachFocusListener(focusNode);
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText ?? 'Search any location...',
            helperText: widget.helperText,
            prefixIcon: Icon(widget.prefixIcon),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textEditingController.clear();
                      _lastSelectedSuggestion = null;
                      widget.onCleared?.call();
                      focusNode.unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
          ),
        );
      },
    );
  }
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.title,
    required this.onTap,
    required this.dateTime,
    this.enabled = true,
  });

  final String title;
  final VoidCallback onTap;
  final DateTime? dateTime;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).disabledColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.labelMedium?.copyWith(
                color: enabled
                    ? textTheme.labelMedium?.color
                    : textTheme.labelMedium?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dateTime != null
                  ? DateFormat('EEE, MMM d • hh:mm a').format(dateTime!)
                  : 'Select date & time',
              style: textTheme.titleMedium?.copyWith(
                color: enabled
                    ? textTheme.titleMedium?.color
                    : textTheme.titleMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxStyleTextField extends StatelessWidget {
  const _BoxStyleTextField({
    required this.label,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.hintText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? prefixIcon;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
    );
  }
}

class _DatePickerBox extends StatelessWidget {
  const _DatePickerBox({
    required this.label,
    required this.date,
    required this.onTap,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? theme.colorScheme.outline
                : theme.disabledColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    date != null
                        ? DateFormat('MM/dd/yyyy').format(date!)
                        : 'Select date',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerBox extends StatelessWidget {
  const _TimePickerBox({
    required this.label,
    required this.time,
    required this.onTap,
    this.enabled = true,
    this.icon,
  });

  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final bool enabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? theme.colorScheme.outline
                : theme.disabledColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    time != null ? time!.format(context) : 'Select time',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? theme.colorScheme.onSurface
                          : theme.disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _GratuitySelector extends StatelessWidget {
  const _GratuitySelector({
    required this.gratuities,
    required this.selectedId,
    required this.onChanged,
    required this.subtotal,
    required this.currency,
  });

  final List<GratuityModel> gratuities;
  final int? selectedId;
  final ValueChanged<int> onChanged;
  final double subtotal;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Handle empty gratuities list
    if (gratuities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Separate gratuities: cash tip (percentage 0) and percentage-based tips
    final cashTipGratuity = gratuities.firstWhere(
      (g) => g.percentage == 0,
      orElse: () => gratuities.first,
    );
    final percentageGratuities =
        gratuities.where((g) => g.percentage > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gratuity',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        // "Will tip in cash" option (gratuity with percentage 0 from API)
        RadioListTile<int>(
          title: Text(cashTipGratuity.description),
          value: cashTipGratuity.gratuityId,
          groupValue: selectedId,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
        // Percentage options from API
        ...percentageGratuities.map(
          (gratuity) {
            final tipAmount = subtotal * (gratuity.percentage / 100);
            // Format as "$(103.00)" to match the image
            final symbol =
                NumberFormat.simpleCurrency(name: currency).currencySymbol;
            final amountStr = tipAmount.toStringAsFixed(2);
            final displayAmount = '$symbol($amountStr)';
            return RadioListTile<int>(
              title: Text(
                '${gratuity.percentage.toStringAsFixed(0)}% $displayAmount',
              ),
              value: gratuity.gratuityId,
              groupValue: selectedId,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            );
          },
        ),
      ],
    );
  }
}

class _GratuityDropdown extends StatelessWidget {
  const _GratuityDropdown({
    required this.gratuities,
    required this.selectedId,
    required this.onChanged,
  });

  final List<GratuityModel> gratuities;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: selectedId ??
          (gratuities.isNotEmpty ? gratuities.first.gratuityId : null),
      decoration: const InputDecoration(
        labelText: 'Gratuity preference',
      ),
      items: gratuities
          .map(
            (gratuity) => DropdownMenuItem(
              value: gratuity.gratuityId,
              child: Text(
                  '${gratuity.percentage.toStringAsFixed(0)}% • ${gratuity.description}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Select a gratuity option';
        }
        return null;
      },
    );
  }
}

class _AdditionalStopDropdown extends StatelessWidget {
  const _AdditionalStopDropdown({
    required this.additionalStops,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AdditionalStopModel> additionalStops;
  final int? selectedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      value: selectedId,
      decoration: const InputDecoration(
        labelText: 'Additional stop (optional)',
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('No additional stops'),
        ),
        ...additionalStops.map(
          (stop) => DropdownMenuItem<int?>(
            value: stop.additionalStopId,
            child: Text(
                '${stop.stopType} • \$${stop.additionalStopPrice.toStringAsFixed(2)}'),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _ExtraOptionsSelector extends StatefulWidget {
  const _ExtraOptionsSelector({
    required this.extraOptions,
    required this.selectedOptions,
    required this.onChanged,
  });

  final List<ExtraOptionModel> extraOptions;
  final List<SelectedExtraOption> selectedOptions;
  final ValueChanged<List<SelectedExtraOption>> onChanged;

  @override
  State<_ExtraOptionsSelector> createState() => _ExtraOptionsSelectorState();
}

class _ExtraOptionsSelectorState extends State<_ExtraOptionsSelector> {
  void _toggleOption(ExtraOptionModel option) {
    final options = List<SelectedExtraOption>.from(widget.selectedOptions);
    final index = options
        .indexWhere((element) => element.extraOptionId == option.extraOptionId);
    if (index >= 0) {
      options.removeAt(index);
    } else {
      options.add(
        SelectedExtraOption(extraOptionId: option.extraOptionId, quantity: 1),
      );
    }
    widget.onChanged(options);
  }

  void _editQuantity(ExtraOptionModel option) {
    final current = widget.selectedOptions
        .firstWhere((element) => element.extraOptionId == option.extraOptionId,
            orElse: () => SelectedExtraOption(
                  extraOptionId: option.extraOptionId,
                  quantity: 1,
                ));
    final maxQuantity = option.hasMaxAllowedLimit
        ? ((option.maxAllowedItems != null && option.maxAllowedItems! > 0)
            ? option.maxAllowedItems
            : 1)
        : null;
    int quantity = current.quantity < 1 ? 1 : current.quantity;
    if (maxQuantity != null && quantity > maxQuantity) {
      quantity = maxQuantity;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    option.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unit price: ${_formatCurrency(option.pricePerItem, option.currency)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (maxQuantity != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Limit: up to $maxQuantity ${maxQuantity == 1 ? 'unit' : 'units'} per booking',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => modalSetState(() {
                                  quantity--;
                                })
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$quantity',
                        style: theme.textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed: maxQuantity == null || quantity < maxQuantity
                            ? () => modalSetState(() {
                                  quantity++;
                                })
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add-on subtotal: ${_formatCurrency(option.pricePerItem * quantity, option.currency)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final options = List<SelectedExtraOption>.from(
                            widget.selectedOptions);
                        final index = options.indexWhere((element) =>
                            element.extraOptionId == option.extraOptionId);
                        final newSelection = SelectedExtraOption(
                            extraOptionId: option.extraOptionId,
                            quantity: quantity);
                        if (index >= 0) {
                          options[index] = newSelection;
                        } else {
                          options.add(newSelection);
                        }
                        widget.onChanged(options);
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final options = List<SelectedExtraOption>.from(
                            widget.selectedOptions)
                          ..removeWhere((element) =>
                              element.extraOptionId == option.extraOptionId);
                        widget.onChanged(options);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove add-on'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.extraOptions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enhance your ride',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => widget.onChanged(const []),
              child: const Text('Clear'),
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.extraOptions.map<Widget>((option) {
            final isSelected = widget.selectedOptions.any(
                (element) => element.extraOptionId == option.extraOptionId);
            final selectedOption = isSelected
                ? widget.selectedOptions.firstWhere(
                    (element) => element.extraOptionId == option.extraOptionId,
                  )
                : null;
            final unitPrice =
                _formatCurrency(option.pricePerItem, option.currency);
            final label = StringBuffer(option.name)..write(' • $unitPrice');
            if (selectedOption != null) {
              label.write(' ×${selectedOption.quantity}');
            }
            return Tooltip(
              message: option.description,
              child: FilterChip(
                label: Text(label.toString()),
                selected: isSelected,
                onSelected: (_) {
                  if (isSelected) {
                    _editQuantity(option);
                  } else {
                    _toggleOption(option);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BookingForSection extends StatelessWidget {
  const _BookingForSection({
    required this.bookingFor,
    required this.onChanged,
  });

  final String bookingFor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('For myself'),
            value: 'Myself',
            groupValue: bookingFor,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('For someone'),
            value: 'SomeoneElse',
            groupValue: bookingFor,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodSection extends StatefulWidget {
  const _PaymentMethodSection({
    super.key,
    required this.paymentProvider,
    required this.paymentMethod,
    required this.onMethodChanged,
    required this.onExistingCardSelected,
    required this.onNewCardSaved,
    this.selectedPaymentDetailId,
  });

  final PaymentProvider paymentProvider;
  final PaymentMethodType paymentMethod;
  final ValueChanged<PaymentMethodType> onMethodChanged;
  final ValueChanged<int?> onExistingCardSelected;
  final ValueChanged<CardDetails> onNewCardSaved;
  final int? selectedPaymentDetailId;

  @override
  State<_PaymentMethodSection> createState() => _PaymentMethodSectionState();
}

class _PaymentMethodSectionState extends State<_PaymentMethodSection> {
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isPrimaryCard = true;
  bool _userOverrodeSelection = false;
  bool _defaultsApplied = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyDefaultSelectionIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = widget.paymentProvider;
    final primaryCard = paymentProvider.primaryCard;
    final hasSavedCards = paymentProvider.cards.isNotEmpty;
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF03930A),
              ),
        ),
        const SizedBox(height: 12),
        if (isAuthenticated && primaryCard != null)
          Card(
            elevation: 0,
            color: widget.paymentMethod == PaymentMethodType.primaryCard
                ? const Color(0xFF03930A).withOpacity(0.1)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: widget.paymentMethod == PaymentMethodType.primaryCard
                    ? const Color(0xFF03930A)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: RadioListTile<PaymentMethodType>(
              title: Row(
                children: [
                  const Icon(Icons.credit_card, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Use Primary Card',
                      style: TextStyle(
                        fontWeight: widget.paymentMethod ==
                                PaymentMethodType.primaryCard
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  primaryCard.maskedCardNumber,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              value: PaymentMethodType.primaryCard,
              groupValue: widget.paymentMethod,
              onChanged: (value) {
                if (value != null) _handleUserMethodChange(value);
              },
              activeColor: const Color(0xFF03930A),
            ),
          ),
        if (isAuthenticated && hasSavedCards) ...[
          if (primaryCard != null) const SizedBox(height: AppSpacing.sm),
          Card(
            elevation: 0,
            color: widget.paymentMethod == PaymentMethodType.existingCard
                ? const Color(0xFF03930A).withOpacity(0.1)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: widget.paymentMethod == PaymentMethodType.existingCard
                    ? const Color(0xFF03930A)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: RadioListTile<PaymentMethodType>(
              title: Row(
                children: [
                  const Icon(Icons.payment, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Select Saved Card',
                      style: TextStyle(
                        fontWeight: widget.paymentMethod ==
                                PaymentMethodType.existingCard
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              value: PaymentMethodType.existingCard,
              groupValue: widget.paymentMethod,
              onChanged: (value) {
                if (value != null) _handleUserMethodChange(value);
              },
              activeColor: const Color(0xFF03930A),
            ),
          ),
        ],
        if (primaryCard != null || hasSavedCards)
          const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          color: widget.paymentMethod == PaymentMethodType.newCard
              ? const Color(0xFF03930A).withOpacity(0.1)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.paymentMethod == PaymentMethodType.newCard
                  ? const Color(0xFF03930A)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: RadioListTile<PaymentMethodType>(
            title: Row(
              children: [
                const Icon(Icons.add_card, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isAuthenticated ? 'Add New Card' : 'Enter Payment Details',
                    style: TextStyle(
                      fontWeight:
                          widget.paymentMethod == PaymentMethodType.newCard
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            value: PaymentMethodType.newCard,
            groupValue: widget.paymentMethod,
            onChanged: (value) {
              if (value != null) _handleUserMethodChange(value);
            },
            activeColor: const Color(0xFF03930A),
          ),
        ),
        if (!isAuthenticated) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Please sign in to save payment methods for future use',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.paymentMethod == PaymentMethodType.primaryCard &&
            primaryCard != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your primary card will be used for this payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.paymentMethod == PaymentMethodType.existingCard &&
            paymentProvider.cards.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF03930A).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Payment Card',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: widget.selectedPaymentDetailId,
                    decoration: InputDecoration(
                      labelText: 'Choose a payment card',
                      hintText: 'Select a saved card',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      errorText: widget.paymentMethod ==
                                  PaymentMethodType.existingCard &&
                              widget.selectedPaymentDetailId == null
                          ? 'Please select a card'
                          : null,
                    ),
                    items: paymentProvider.cards
                        .map(
                          (card) => DropdownMenuItem<int>(
                            value: card.paymentDetailId,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  size: 18,
                                  color: card.isPrimary
                                      ? const Color(0xFF03930A)
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        card.maskedCardNumber,
                                        style: TextStyle(
                                          fontWeight: card.isPrimary
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (card.isPrimary)
                                        Text(
                                          'Primary Card',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF03930A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _userOverrodeSelection = true;
                        widget.onExistingCardSelected(value);
                      }
                    },
                    validator: (value) {
                      if (widget.paymentMethod ==
                              PaymentMethodType.existingCard &&
                          value == null) {
                        return 'Please select a saved card';
                      }
                      return null;
                    },
                    isExpanded: true,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (widget.paymentMethod == PaymentMethodType.newCard) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF03930A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _CardForm(
              cardNumberController: _cardNumberController,
              cardNameController: _cardNameController,
              expiryController: _expiryController,
              cvvController: _cvvController,
              zipController: _zipController,
              isPrimary: _isPrimaryCard,
              onPrimaryChanged: (value) {
                setState(() {
                  _isPrimaryCard = value;
                });
              },
              onSaved: (card) => widget.onNewCardSaved(card),
            ),
          ),
        ],
      ],
    );
  }

  void _handleUserMethodChange(PaymentMethodType method) {
    _userOverrodeSelection = true;

    // Clear selections when switching payment methods for flexibility
    if (method != PaymentMethodType.existingCard) {
      widget.onExistingCardSelected(null);
    }
    if (method != PaymentMethodType.newCard) {
      // Clear card form when switching away from new card
      _cardNumberController.clear();
      _cardNameController.clear();
      _expiryController.clear();
      _cvvController.clear();
      _zipController.clear();
      _isPrimaryCard = false;
    }

    widget.onMethodChanged(method);

    // Auto-select first card when switching to existing card
    if (method == PaymentMethodType.existingCard &&
        widget.paymentProvider.cards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onExistingCardSelected(
          widget.paymentProvider.cards.first.paymentDetailId,
        );
      });
    }
  }

  void _applyDefaultSelectionIfNeeded() {
    if (_userOverrodeSelection || _defaultsApplied) return;
    final preferredMethod = _resolvePreferredMethod();
    final shouldSelectSavedCard =
        preferredMethod == PaymentMethodType.existingCard &&
            widget.paymentProvider.cards.isNotEmpty;

    if (widget.paymentMethod == preferredMethod) {
      if (shouldSelectSavedCard && widget.selectedPaymentDetailId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _userOverrodeSelection) return;
          widget.onExistingCardSelected(
            widget.paymentProvider.cards.first.paymentDetailId,
          );
        });
      }
      _defaultsApplied = true;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userOverrodeSelection) return;
      widget.onMethodChanged(preferredMethod);
      if (shouldSelectSavedCard) {
        widget.onExistingCardSelected(
            widget.paymentProvider.cards.first.paymentDetailId);
      }
    });
    _defaultsApplied = true;
  }

  PaymentMethodType _resolvePreferredMethod() {
    if (widget.paymentProvider.primaryCard != null) {
      return PaymentMethodType.primaryCard;
    }
    if (widget.paymentProvider.cards.isNotEmpty) {
      return PaymentMethodType.existingCard;
    }
    return PaymentMethodType.newCard;
  }
}

class _CardForm extends StatefulWidget {
  const _CardForm({
    required this.cardNumberController,
    required this.cardNameController,
    required this.expiryController,
    required this.cvvController,
    required this.zipController,
    required this.isPrimary,
    required this.onPrimaryChanged,
    required this.onSaved,
  });

  final TextEditingController cardNumberController;
  final TextEditingController cardNameController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final TextEditingController zipController;
  final bool isPrimary;
  final ValueChanged<bool> onPrimaryChanged;
  final ValueChanged<CardDetails> onSaved;

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  late CardBrand _cardBrand;
  bool _isValidating = false;
  bool _isValidated = false;
  String? _validationError;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cardBrand = detectCardBrand(widget.cardNumberController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.cardNameController,
            decoration: const InputDecoration(
              labelText: 'Name on card',
            ),
            textCapitalization: TextCapitalization.words,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: NameValidator.validateCardholderName,
            onChanged: (_) => _clearValidationState(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.cardNumberController,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Card number',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(23),
            ],
            onChanged: (value) {
              _handleCardNumberChanged(value);
              _clearValidationState();
            },
            validator: validateCardNumber,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.credit_card, size: 18),
                label: Text(_cardBrand.label),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'CVV: ${cvvExpectedLength(_cardBrand)} digits',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.expiryController,
                  keyboardType: TextInputType.datetime,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                  ),
                  inputFormatters: [
                    expiryInputFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  onChanged: (value) {
                    final formatted = formatExpiryInput(value);
                    if (formatted != value) {
                      widget.expiryController.value = TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                    _clearValidationState();
                  },
                  validator: validateExpiry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.cvvController,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (_) => _clearValidationState(),
                  validator: (value) => validateCvv(value, _cardBrand),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.zipController,
            keyboardType: TextInputType.number,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'ZIP code',
            ),
            inputFormatters: [
              zipInputFormatter(),
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => _clearValidationState(),
            validator: validateZip,
          ),
          if (isAuthenticated) ...[
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: widget.isPrimary,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                if (value != null) widget.onPrimaryChanged(value);
              },
              title: const Text('Set as primary card'),
            ),
          ],
          if (_validationError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isValidated) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isAuthenticated
                          ? 'Card validated and ready to use!'
                          : 'Card validated successfully!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: _isValidating ? null : _handleValidateAndSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: _isValidating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isAuthenticated ? 'Validate & Use Card' : 'Validate Card',
                  ),
          ),
        ],
      ),
    );
  }

  void _clearValidationState() {
    if (_isValidated || _validationError != null) {
      setState(() {
        _isValidated = false;
        _validationError = null;
      });
    }
  }

  Future<void> _handleValidateAndSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final card = CardDetails(
      creditCardNumber: widget.cardNumberController.text
          .replaceAll(RegExp(r'\s+'), '')
          .trim(),
      cardOwnerName: NameValidator.format(widget.cardNameController.text),
      expirationDate: widget.expiryController.text.trim(),
      securityCode: widget.cvvController.text.trim(),
      zipCode: widget.zipController.text.trim(),
      isPrimary: widget.isPrimary,
    );

    // Client-side validation
    if (card.creditCardNumber.isEmpty ||
        card.cardOwnerName.isEmpty ||
        card.expirationDate.isEmpty ||
        card.securityCode.isEmpty ||
        card.zipCode.isEmpty) {
      setState(() {
        _validationError = 'All card fields are required';
        _isValidated = false;
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    // For authenticated users, validate with backend
    if (isAuthenticated) {
      setState(() {
        _isValidating = true;
        _validationError = null;
        _isValidated = false;
      });

      try {
        final paymentProvider = context.read<PaymentProvider>();
        final success = await paymentProvider.addCard(card);

        if (success && mounted) {
          setState(() {
            _isValidating = false;
            _isValidated = true;
            _validationError = null;
          });
          widget.onSaved(card);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card validated and saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          setState(() {
            _isValidating = false;
            _isValidated = false;
            _validationError = paymentProvider.errorMessage ??
                'Card validation failed. Please check your card details.';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isValidating = false;
            _isValidated = false;
            _validationError = 'Card validation failed: ${e.toString()}';
          });
        }
      }
    } else {
      // For guest users, just do client-side validation
      setState(() {
        _isValidated = true;
        _validationError = null;
      });
      widget.onSaved(card);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card info captured for this booking.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleCardNumberChanged(String value) {
    final formatted = formatCardNumber(value);
    if (formatted != value) {
      widget.cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    final detected = detectCardBrand(value);
    if (detected != _cardBrand) {
      setState(() {
        _cardBrand = detected;
      });
    }
  }
}

String _formatCurrency(double amount, String currency) {
  try {
    final symbol = NumberFormat.simpleCurrency(name: currency).currencySymbol;
    final formatter = NumberFormat.currency(name: currency, symbol: symbol);
    return formatter.format(amount);
  } catch (_) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }
}

/// Shared promo-code apply/remove state across all three booking forms.
enum _PromoStatus { idle, loading, applied, error }

/// Shared promo-code entry widget used by all three booking forms — a text
/// field plus an Apply/Remove button, with inline success/error feedback.
class _PromoCodeField extends StatelessWidget {
  const _PromoCodeField({
    required this.controller,
    required this.status,
    required this.message,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final _PromoStatus status;
  final String? message;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  static const _brandGreen = Color(0xFF03930A);

  @override
  Widget build(BuildContext context) {
    final applied = status == _PromoStatus.applied;
    final loading = status == _PromoStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !applied,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Enter promo code',
                  hintText: 'e.g. WELCOME10',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  final upper = value.toUpperCase();
                  if (upper != value) {
                    controller.value = controller.value.copyWith(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: applied
                  ? OutlinedButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: loading ? null : onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandGreen,
                        foregroundColor: Colors.white,
                        // Overrides the app-wide ElevatedButton theme's
                        // minimumSize: Size(double.infinity, 48) — that's
                        // meant for full-width CTA buttons in a Column, but
                        // this button sits in a Row next to the text field,
                        // where an infinite-width demand has nothing finite
                        // to resolve against and crashes layout.
                        minimumSize: const Size(0, 56),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Apply'),
                    ),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                applied ? Icons.check_circle : Icons.error_outline,
                size: 18,
                color: applied ? _brandGreen : Colors.red,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  message!,
                  style: TextStyle(
                    color: applied ? _brandGreen : Colors.red,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TripPriceSummaryCard extends StatelessWidget {
  const _TripPriceSummaryCard({
    required this.breakdown,
    this.subtitle,
  });

  final TripPriceBreakdown breakdown;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = <_PricingLine>[
      _PricingLine(label: 'Base fare', amount: breakdown.baseFare),
      if (breakdown.additionalStops > 0)
        _PricingLine(
            label: 'Additional stop', amount: breakdown.additionalStops),
      if (breakdown.pickupPreference > 0)
        _PricingLine(
            label: 'Pickup preference', amount: breakdown.pickupPreference),
      if (breakdown.extras > 0)
        _PricingLine(label: 'Enhancements', amount: breakdown.extras),
      if (breakdown.otherAdjustments > 0)
        _PricingLine(label: 'Adjustments', amount: breakdown.otherAdjustments),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pricing preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (breakdown.distanceInMiles != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                // Match website: always use 2 decimal places
                'Distance: ${breakdown.distanceInMiles!.toStringAsFixed(2)} miles',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            for (final line in lines) ...[
              _PricingRow(
                label: line.label,
                amount: _formatCurrency(line.amount, breakdown.currency),
                emphasize: false,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Divider(color: theme.colorScheme.outline.withOpacity(0.4)),
            _PricingRow(
              label: 'Subtotal',
              amount: _formatCurrency(breakdown.subtotal, breakdown.currency),
            ),
            if (breakdown.gratuityAmount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _PricingRow(
                label:
                    'Gratuity${breakdown.gratuityPercentage != null ? ' (${breakdown.gratuityPercentage!.toStringAsFixed(0)}%)' : ''}',
                amount: _formatCurrency(
                    breakdown.gratuityAmount, breakdown.currency),
              ),
            ],
            if (breakdown.promoDiscount > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _PricingRow(
                label: 'Promo discount',
                amount:
                    '-${_formatCurrency(breakdown.promoDiscount, breakdown.currency)}',
                valueColor: const Color(0xFF03930A),
              ),
            ],
            const SizedBox(height: 12),
            _PricingRow(
              label: 'Estimated total',
              amount: _formatCurrency(breakdown.total, breakdown.currency),
              emphasize: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Final concierge confirmation may adjust the total if trip details change.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PricingLine {
  const _PricingLine({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String amount;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = emphasize
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textStyle,
          ),
        ),
        Text(
          amount,
          style: valueColor != null
              ? textStyle?.copyWith(color: valueColor, fontWeight: FontWeight.w600)
              : textStyle,
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// Avoids mounting legacy card fields before Square config is known (prevents
/// disposing [TextEditingController]s mid-frame when config finishes loading).
class _BookingPaymentMethodPicker extends StatelessWidget {
  const _BookingPaymentMethodPicker({
    required this.paymentProvider,
    required this.paymentMethod,
    required this.selectedPaymentDetailId,
    required this.onMethodChanged,
    required this.onExistingCardSelected,
    required this.onNewCardSaved,
    required this.onSquareMethodChanged,
    required this.onSquareSavedCardSelected,
    this.selectedSquareCardId,
    this.verifiedSquarePayload,
    this.squareTokenizedAtTotal,
    this.bookingTotal,
    this.onSquareVerified,
    this.onSquareVerificationCleared,
    this.cardholderNameHint,
    this.billingZipHint,
  });

  final PaymentProvider paymentProvider;
  final PaymentMethodType paymentMethod;
  final int? selectedPaymentDetailId;
  final ValueChanged<PaymentMethodType> onMethodChanged;
  final ValueChanged<int?> onExistingCardSelected;
  final ValueChanged<CardDetails> onNewCardSaved;
  final ValueChanged<PaymentMethodType> onSquareMethodChanged;
  final ValueChanged<PaymentDetailModel> onSquareSavedCardSelected;
  final String? selectedSquareCardId;
  final SquarePaymentPayload? verifiedSquarePayload;
  final double? squareTokenizedAtTotal;
  final double? bookingTotal;
  final void Function(SquarePaymentPayload payload, double totalAtVerify)?
      onSquareVerified;
  final VoidCallback? onSquareVerificationCleared;
  final String? cardholderNameHint;
  final String? billingZipHint;

  @override
  Widget build(BuildContext context) {
    final configLoading = context.select<SquareRuntimeConfig, bool>(
      (c) => c.isLoading && !c.hasConfig,
    );
    final squareEnabled = context.select<SquareRuntimeConfig, bool>(
      (c) => c.squareEnabled,
    );
    if (configLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (squareEnabled) {
      return SquarePaymentMethodSection(
        key: const ValueKey('square_payment'),
        paymentProvider: paymentProvider,
        paymentMethod: paymentMethod,
        selectedPaymentDetailId: selectedPaymentDetailId,
        selectedSquareCardId: selectedSquareCardId,
        onMethodChanged: onSquareMethodChanged,
        onSavedCardSelected: onSquareSavedCardSelected,
        verifiedSquarePayload: verifiedSquarePayload,
        squareTokenizedAtTotal: squareTokenizedAtTotal,
        bookingTotal: bookingTotal,
        onSquareVerified: onSquareVerified ?? (_, __) {},
        onSquareVerificationCleared: onSquareVerificationCleared ?? () {},
        cardholderNameHint: cardholderNameHint,
        billingZipHint: billingZipHint,
      );
    }

    return _PaymentMethodSection(
      key: const ValueKey('legacy_payment'),
      paymentProvider: paymentProvider,
      paymentMethod: paymentMethod,
      selectedPaymentDetailId: selectedPaymentDetailId,
      onMethodChanged: onMethodChanged,
      onExistingCardSelected: onExistingCardSelected,
      onNewCardSaved: onNewCardSaved,
    );
  }
}
