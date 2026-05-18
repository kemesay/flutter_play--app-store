import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:oda_black_car_service/core/utils/distance_utils.dart';
import 'package:oda_black_car_service/core/utils/pricing_calculator.dart';
import 'package:oda_black_car_service/data/mappers/booking_update_mapper.dart';
import 'package:oda_black_car_service/data/models/additional_stop_model.dart';
import 'package:oda_black_car_service/data/models/airport_booking_update_request.dart';
import 'package:oda_black_car_service/data/models/airport_pickup_preference_model.dart';
import 'package:oda_black_car_service/data/models/booking_history_item.dart';
import 'package:oda_black_car_service/data/models/car_model.dart';
import 'package:oda_black_car_service/data/models/gratuity_model.dart';
import 'package:oda_black_car_service/data/models/hourly_charter_booking_update_request.dart';
import 'package:oda_black_car_service/data/models/point_to_point_booking_update_request.dart';
import 'package:oda_black_car_service/data/models/selected_extra_option.dart';
import 'package:oda_black_car_service/data/services/directions_service.dart';
import 'package:oda_black_car_service/data/services/place_service.dart';
import 'package:oda_black_car_service/model/place_model.dart';
import 'package:oda_black_car_service/providers/booking_provider.dart';
import 'package:oda_black_car_service/providers/catalog_provider.dart';
import 'package:oda_black_car_service/ui/widgets/booking_route_preview_map.dart';
import 'package:oda_black_car_service/ui/widgets/custom_snackbar.dart';
import 'package:oda_black_car_service/ui/widgets/extra_options_selector.dart';
import 'package:oda_black_car_service/ui/widgets/location_picker_field.dart';
import 'package:oda_black_car_service/ui/widgets/vehicle_image_thumbnail.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const _brandGreen = Color(0xFF03930A);

class UpdateBookingPage extends StatefulWidget {
  const UpdateBookingPage({super.key, required this.booking});

  final BookingHistoryItem booking;

  @override
  State<UpdateBookingPage> createState() => _UpdateBookingPageState();
}

class _UpdateBookingPageState extends State<UpdateBookingPage> {
  late final BookingEditFormData _initial;
  late final int? _originalCarId;

  final _placeService = PlaceService();
  final _directionsService = DirectionsService();
  final _sessionToken = const Uuid().v4();

  // Shared
  late String _tripType;
  late int _passengers;
  late int _suitcases;
  late String _bookingFor;
  late DateTime _pickupDateTime;
  DateTime? _returnDateTime;
  late final TextEditingController _passengerNameController;
  late final TextEditingController _passengerEmailController;
  late final TextEditingController _passengerPhoneController;
  late final TextEditingController _instructionsController;

  int? _selectedCarId;
  int? _selectedGratuityId;
  double? _distanceInMiles;
  List<LatLng>? _routePolyline;
  String? _routeDurationText;
  bool _isRouteLoading = false;

  // Airport
  late final TextEditingController _airportController;
  late final TextEditingController _accommodationController;
  PlaceDetail? _airportDetail;
  PlaceDetail? _accommodationDetail;
  late final TextEditingController _airlineController;
  late final TextEditingController _arrivalFlightController;
  late final TextEditingController _returnAirlineController;
  late final TextEditingController _returnFlightController;
  int? _pickupPreferenceId;
  bool _hasAdditionalStop = false;
  int? _additionalStopId;
  late final TextEditingController _additionalStopDescController;
  final List<SelectedExtraOption> _selectedExtras = [];
  late final Set<int> _initialExtraOptionIds;
  late final double? _bookedTripTotalFee;
  late final double? _initialGratuityPercentage;

  // Point-to-point / hourly locations
  late final TextEditingController _pickupController;
  late final TextEditingController _dropoffController;
  PlaceDetail? _pickupDetail;
  PlaceDetail? _dropoffDetail;

  // Hourly
  late int _selectedHours;
  late String _occasion;

  @override
  void initState() {
    super.initState();
    _initial = BookingUpdateMapper.fromBooking(widget.booking);
    _originalCarId = _initial.carId;

    _tripType = _initial.tripType;
    _passengers = _initial.numberOfPassengers;
    _suitcases = _initial.numberOfSuitcases;
    _bookingFor = _initial.bookingFor;
    _pickupDateTime = _initial.pickupDateTime;
    _returnDateTime = _initial.returnPickupDateTime;

    _passengerNameController =
        TextEditingController(text: _initial.passengerFullName);
    _passengerEmailController =
        TextEditingController(text: _initial.passengerEmail);
    _passengerPhoneController =
        TextEditingController(text: _initial.passengerCellPhone);
    _instructionsController =
        TextEditingController(text: _initial.specialInstructions ?? '');

    _selectedCarId = _initial.carId;
    _selectedGratuityId = _initial.gratuityId;
    _distanceInMiles = _initial.distanceInMiles;

    _airportController =
        TextEditingController(text: _initial.airportLocationAddress ?? '');
    _accommodationController =
        TextEditingController(text: _initial.accommodationAddress ?? '');
    _airportDetail = _initial.airportPlaceDetail;
    _accommodationDetail = _initial.accommodationPlaceDetail;

    _airlineController = TextEditingController(text: _initial.airline ?? '');
    _arrivalFlightController =
        TextEditingController(text: _initial.arrivalFlightNumber ?? '');
    _returnAirlineController =
        TextEditingController(text: _initial.returnAirline ?? '');
    _returnFlightController =
        TextEditingController(text: _initial.returnFlightNumber ?? '');
    _pickupPreferenceId = _initial.pickupPreferenceId;
    _hasAdditionalStop = _initial.additionalStopId != null;
    _additionalStopId = _initial.additionalStopId;
    _additionalStopDescController = TextEditingController(
      text: _initial.additionalStopDescription ?? '',
    );
    _selectedExtras.addAll(_initial.extraOptions);
    _initialExtraOptionIds = _initial.extraOptions
        .map((e) => e.extraOptionId)
        .toSet();
    _bookedTripTotalFee = widget.booking.totalFee;
    _initialGratuityPercentage = _parseGratuityPercentage(
      widget.booking.rawData['Gratuity'],
    );

    _pickupController =
        TextEditingController(text: _initial.pickupPhysicalAddress ?? '');
    _dropoffController =
        TextEditingController(text: _initial.dropoffPhysicalAddress ?? '');
    _pickupDetail = _initial.pickupPlaceDetail;
    _dropoffDetail = _initial.dropoffPlaceDetail;

    _selectedHours = _initial.selectedHours ?? 5;
    _occasion = _initial.occasion ?? 'Wedding';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CatalogProvider>().initialize();
      _refreshRoutePreview();
    });
  }

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerEmailController.dispose();
    _passengerPhoneController.dispose();
    _instructionsController.dispose();
    _airportController.dispose();
    _accommodationController.dispose();
    _airlineController.dispose();
    _arrivalFlightController.dispose();
    _returnAirlineController.dispose();
    _returnFlightController.dispose();
    _additionalStopDescController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  bool get _isRoundTrip => _tripType.toLowerCase().contains('round trip') ||
      _tripType == 'Round-Trip';

  int get _resolvedHours {
    const minHours = 4;
    const maxHours = 15;
    if (_selectedHours < minHours) return minHours;
    if (_selectedHours > maxHours) return maxHours;
    return _selectedHours;
  }

  String get _resolvedOccasion {
    final lower = _occasion.trim().toLowerCase();
    for (final option in BookingUpdateMapper.hourlyOccasionOptions) {
      if (option.toLowerCase() == lower) return option;
    }
    return BookingUpdateMapper.hourlyOccasionOptions.first;
  }

  bool get _requiresReturn => _isRoundTrip;

  String _formatApiDateTime(DateTime value) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(value);

  PlaceDetail? get _routePickupDetail {
    switch (widget.booking.type) {
      case BookingType.airport:
        return _accommodationDetail;
      case BookingType.pointToPoint:
      case BookingType.hourlyCharter:
        return _pickupDetail;
    }
  }

  PlaceDetail? get _routeDropoffDetail {
    switch (widget.booking.type) {
      case BookingType.airport:
        return _airportDetail;
      case BookingType.pointToPoint:
      case BookingType.hourlyCharter:
        return _dropoffDetail;
    }
  }

  String get _routePickupLabel {
    switch (widget.booking.type) {
      case BookingType.airport:
        return 'Stay';
      case BookingType.pointToPoint:
      case BookingType.hourlyCharter:
        return 'Pickup';
    }
  }

  String get _routeDropoffLabel {
    switch (widget.booking.type) {
      case BookingType.airport:
        return 'Airport';
      case BookingType.pointToPoint:
      case BookingType.hourlyCharter:
        return 'Drop-off';
    }
  }

  Future<void> _refreshRoutePreview() async {
    final origin = _routePickupDetail;
    final destination = _routeDropoffDetail;
    if (origin == null || destination == null) {
      if (mounted) {
        setState(() {
          _routePolyline = null;
          _routeDurationText = null;
          _isRouteLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isRouteLoading = true);

    try {
      final route = await _directionsService.fetchRoute(
        origin: LatLng(origin.lat, origin.lng),
        destination: LatLng(destination.lat, destination.lng),
      );
      if (!mounted) return;
      if (route != null) {
        setState(() {
          _distanceInMiles = route.distanceMiles;
          _routePolyline = route.polyline;
          _routeDurationText = route.durationText;
          _isRouteLoading = false;
        });
      } else {
        setState(() {
          _distanceInMiles = haversineDistanceInMiles(
            startLat: origin.lat,
            startLng: origin.lng,
            endLat: destination.lat,
            endLng: destination.lng,
          );
          _routePolyline = null;
          _routeDurationText = null;
          _isRouteLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _distanceInMiles = haversineDistanceInMiles(
          startLat: origin.lat,
          startLng: origin.lng,
          endLat: destination.lat,
          endLng: destination.lng,
        );
        _routePolyline = null;
        _routeDurationText = null;
        _isRouteLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final bookingProvider = context.read<BookingProvider>();

    if (_selectedCarId == null) {
      CustomSnackbar.show(context, 'Select a vehicle.');
      return;
    }
    if (_selectedGratuityId == null) {
      CustomSnackbar.show(context, 'Select a gratuity preference.');
      return;
    }

    final minPickup = DateTime.now().add(const Duration(hours: 1));
    if (_pickupDateTime.isBefore(minPickup)) {
      CustomSnackbar.show(
        context,
        'Pickup must be at least 1 hour from now.',
      );
      return;
    }

    if (_requiresReturn) {
      if (_returnDateTime == null) {
        CustomSnackbar.show(context, 'Select return date and time.');
        return;
      }
      if (_returnDateTime!.isBefore(
        _pickupDateTime.add(const Duration(hours: 1)),
      )) {
        CustomSnackbar.show(
          context,
          'Return must be at least 1 hour after pickup.',
        );
        return;
      }
    }

    final distance = _distanceInMiles ?? _initial.distanceInMiles ?? 0;
    if (widget.booking.type != BookingType.hourlyCharter &&
        distance <= 0) {
      CustomSnackbar.show(context, 'Unable to calculate trip distance.');
      return;
    }

    bool success = false;
    switch (widget.booking.type) {
      case BookingType.airport:
        success = await _saveAirport(bookingProvider);
        break;
      case BookingType.pointToPoint:
        success = await _savePointToPoint(bookingProvider);
        break;
      case BookingType.hourlyCharter:
        success = await _saveHourly(bookingProvider);
        break;
    }

    if (success && mounted) {
      CustomSnackbar.showSuccess(context, 'Booking updated successfully.');
      Navigator.of(context).pop(true);
    } else if (mounted && bookingProvider.errorMessage != null) {
      CustomSnackbar.show(context, bookingProvider.errorMessage!);
    }
  }

  Future<bool> _saveAirport(BookingProvider provider) async {
    if (_airportDetail == null ||
        _accommodationDetail == null ||
        _airportController.text.trim().isEmpty) {
      CustomSnackbar.show(context, 'Select airport from suggestions.');
      return false;
    }
    if (!_isCalifornia(_airportDetail!)) {
      CustomSnackbar.show(context, 'Airport pickup must be in California.');
      return false;
    }
    if (!_isUnitedStates(_accommodationDetail!)) {
      CustomSnackbar.show(
        context,
        'Accommodation must be in the United States.',
      );
      return false;
    }

    final request = AirportBookingUpdateRequest(
      tripType: _tripType,
      airportLocationAddress: _airportController.text.trim(),
      airportLocationLatitude: _airportDetail!.lat,
      airportLocationLongitude: _airportDetail!.lng,
      numberOfPassengers: _passengers,
      numberOfSuitcases: _suitcases,
      accommodationAddress: _accommodationController.text.trim().isNotEmpty
          ? _accommodationController.text.trim()
          : _accommodationDetail!.formattedAddress,
      accommodationLongitude: _accommodationDetail!.lng,
      accommodationLatitude: _accommodationDetail!.lat,
      pickupDateTime: _formatApiDateTime(_pickupDateTime),
      returnPickupDateTime: _returnDateTime != null
          ? _formatApiDateTime(_returnDateTime!)
          : null,
      airline: _airlineController.text.trim(),
      arrivalFlightNumber: _arrivalFlightController.text.trim(),
      returnAirline: _returnAirlineController.text.trim(),
      returnFlightNumber: _returnFlightController.text.trim(),
      distanceInMiles: _distanceInMiles ?? _initial.distanceInMiles ?? 0,
      carId: _selectedCarId!,
      additionalStopId: _hasAdditionalStop ? _additionalStopId : null,
      additionalStopOnTheWayDescription: _hasAdditionalStop
          ? _additionalStopDescController.text.trim()
          : null,
      pickupPreferenceId: _pickupPreferenceId,
      extraOptions: List<SelectedExtraOption>.from(_selectedExtras),
      bookingFor: _bookingFor,
      passengerFullName: _passengerNameController.text.trim(),
      passengerCellPhone: _passengerPhoneController.text.trim(),
      passengerEmail: _passengerEmailController.text.trim(),
      gratuityId: _selectedGratuityId!,
      specialInstructions: _instructionsController.text.trim(),
    );

    return provider.updateAirportBooking(_initial.bookingId, request);
  }

  Future<bool> _savePointToPoint(BookingProvider provider) async {
    if (_pickupDetail == null || _dropoffDetail == null) {
      CustomSnackbar.show(context, 'Select pickup and drop-off from suggestions.');
      return false;
    }
    if (!_isCalifornia(_pickupDetail!)) {
      CustomSnackbar.show(context, 'Pickup must be in California.');
      return false;
    }

    final request = PointToPointBookingUpdateRequest(
      tripType: _tripType,
      pickupPhysicalAddress: _pickupController.text.trim().isNotEmpty
          ? _pickupController.text.trim()
          : _pickupDetail!.formattedAddress,
      pickupLongitude: _pickupDetail!.lng,
      pickupLatitude: _pickupDetail!.lat,
      dropoffPhysicalAddress: _dropoffController.text.trim().isNotEmpty
          ? _dropoffController.text.trim()
          : _dropoffDetail!.formattedAddress,
      dropoffLongitude: _dropoffDetail!.lng,
      dropoffLatitude: _dropoffDetail!.lat,
      distanceInMiles: _distanceInMiles ?? _initial.distanceInMiles ?? 0,
      numberOfPassengers: _passengers,
      numberOfSuitcases: _suitcases,
      pickupDateTime: _formatApiDateTime(_pickupDateTime),
      returnPickupDateTime:
          _returnDateTime != null ? _formatApiDateTime(_returnDateTime!) : null,
      specialInstructions: _instructionsController.text.trim(),
      bookingFor: _bookingFor,
      passengerFullName: _passengerNameController.text.trim(),
      passengerEmail: _passengerEmailController.text.trim(),
      passengerCellPhone: _passengerPhoneController.text.trim(),
      additionalStopId: _hasAdditionalStop ? _additionalStopId : null,
      additionalStopOnTheWayDescription: _hasAdditionalStop
          ? _additionalStopDescController.text.trim()
          : null,
      carId: _selectedCarId!,
      gratuityId: _selectedGratuityId!,
      extraOptions: List<SelectedExtraOption>.from(_selectedExtras),
    );

    return provider.updatePointToPointBooking(_initial.bookingId, request);
  }

  Future<bool> _saveHourly(BookingProvider provider) async {
    if (_pickupDetail == null || _dropoffDetail == null) {
      CustomSnackbar.show(context, 'Select pickup and drop-off from suggestions.');
      return false;
    }
    if (!_isCalifornia(_pickupDetail!)) {
      CustomSnackbar.show(context, 'Pickup must be in California.');
      return false;
    }

    final request = HourlyCharterBookingUpdateRequest(
      pickupPhysicalAddress: _pickupController.text.trim().isNotEmpty
          ? _pickupController.text.trim()
          : _pickupDetail!.formattedAddress,
      pickupLongitude: _pickupDetail!.lng,
      pickupLatitude: _pickupDetail!.lat,
      dropoffPhysicalAddress: _dropoffController.text.trim().isNotEmpty
          ? _dropoffController.text.trim()
          : _dropoffDetail!.formattedAddress,
      dropoffLongitude: _dropoffDetail!.lng,
      dropoffLatitude: _dropoffDetail!.lat,
      selectedHours: _resolvedHours,
      occasion: _resolvedOccasion,
      numberOfPassengers: _passengers,
      numberOfSuitcases: _suitcases,
      pickupDateTime: _formatApiDateTime(_pickupDateTime),
      specialInstructions: _instructionsController.text.trim(),
      bookingFor: _bookingFor,
      passengerFullName: _passengerNameController.text.trim(),
      passengerCellPhone: _passengerPhoneController.text.trim(),
      passengerEmail: _passengerEmailController.text.trim(),
      carId: _selectedCarId!,
      gratuityId: _selectedGratuityId!,
    );

    return provider.updateHourlyCharterBooking(_initial.bookingId, request);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Update ${widget.booking.displayTitle}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: catalog.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildForm(catalog),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _brandGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed:
                            bookingProvider.isSubmitting ? null : _save,
                        icon: bookingProvider.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Update changes'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildForm(CatalogProvider catalog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoBanner(),
        const SizedBox(height: 16),
        if (widget.booking.type == BookingType.airport) ...[
          _buildAirportLocations(),
          const SizedBox(height: 16),
          _buildAirportTripType(),
        ] else if (widget.booking.type == BookingType.pointToPoint) ...[
          _buildP2PLocations(),
          const SizedBox(height: 16),
          _buildP2PTripType(),
        ] else ...[
          _buildHourlyLocations(),
          const SizedBox(height: 16),
          _buildHourlyOptions(),
        ],
        const SizedBox(height: 16),
        _buildRoutePreviewSection(),
        const SizedBox(height: 16),
        _buildPassengerCounters(),
        const SizedBox(height: 16),
        _buildScheduleSection(),
        const SizedBox(height: 16),
        if (widget.booking.type == BookingType.airport) _buildAirlineSection(),
        if (widget.booking.type != BookingType.hourlyCharter) ...[
          _buildAdditionalStopSection(catalog),
          const SizedBox(height: 16),
          if (catalog.extraOptions.isNotEmpty)
            ExtraOptionsSelector(
              extraOptions: catalog.extraOptions,
              selectedOptions: _selectedExtras,
              originallyBookedIds: _initialExtraOptionIds,
              highlightOriginalBooking: true,
              onChanged: (options) => setState(() {
                _selectedExtras
                  ..clear()
                  ..addAll(options);
              }),
            ),
        ],
        const SizedBox(height: 16),
        _UpdateVehiclePicker(
          cars: catalog.cars,
          selectedCarId: _selectedCarId,
          originalCarId: _originalCarId,
          passengers: _passengers,
          suitcases: _suitcases,
          fallbackImageUrl: widget.booking.carImageUrl,
          bookedTripTotalFee: _bookedTripTotalFee,
          estimateCarFare: _estimateCarFareAmount,
          formatMoney: _formatMoney,
          onSelect: (id) => setState(() => _selectedCarId = id),
        ),
        const SizedBox(height: 16),
        _buildGratuitySection(catalog),
        const SizedBox(height: 16),
        _buildPriceSummary(catalog),
        const SizedBox(height: 16),
        _buildPassengerSection(),
        const SizedBox(height: 16),
        _buildInstructionsField(),
      ],
    );
  }

  Widget _buildRoutePreviewSection() {
    final pickup = _routePickupDetail;
    final dropoff = _routeDropoffDetail;
    final pickupAddress = widget.booking.type == BookingType.airport
        ? _accommodationController.text
        : _pickupController.text;
    final dropoffAddress = widget.booking.type == BookingType.airport
        ? _airportController.text
        : _dropoffController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _brandGreen.withOpacity(0.25)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _brandGreen.withOpacity(0.06),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brandGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map_outlined, color: _brandGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live route preview',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _brandGreen,
                      ),
                    ),
                    Text(
                      pickup != null && dropoff != null
                          ? 'Google Maps path updates as you change locations.'
                          : 'Select both endpoints to draw the route.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RouteEndpointRow(
            icon: Icons.trip_origin,
            color: Colors.blue,
            label: _routePickupLabel,
            value: pickupAddress.isNotEmpty
                ? pickupAddress
                : 'Not set',
          ),
          const SizedBox(height: 6),
          _RouteEndpointRow(
            icon: Icons.place,
            color: Colors.red,
            label: _routeDropoffLabel,
            value: dropoffAddress.isNotEmpty ? dropoffAddress : 'Not set',
          ),
          const SizedBox(height: 12),
          BookingRoutePreviewMap(
            pickup: pickup,
            dropoff: dropoff,
            routePolyline: _routePolyline,
            distanceInMiles: _distanceInMiles,
            durationText: _routeDurationText,
            isLoading: _isRouteLoading,
            pickupLabel: _routePickupLabel,
            dropoffLabel: _routeDropoffLabel,
            height: widget.booking.type == BookingType.hourlyCharter ? 260 : 220,
          ),
        ],
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _brandGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_location_alt, color: _brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Confirmation #${widget.booking.confirmationNumber} · '
              'Update trip details below. Payment details are not changed here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirportLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Airport & accommodation'),
        LocationPickerField(
          label: 'Airport / terminal pickup',
          controller: _airportController,
          placeService: _placeService,
          sessionToken: _sessionToken,
          country: 'US',
          onCleared: () {
            setState(() => _airportDetail = null);
            _refreshRoutePreview();
          },
          onPlaceSelected: (detail) {
            if (!_isCalifornia(detail)) {
              CustomSnackbar.show(
                context,
                'Airport/terminal pickup must be in California.',
              );
              return;
            }
            setState(() => _airportDetail = detail);
            _refreshRoutePreview();
          },
        ),
        const SizedBox(height: 12),
        LocationPickerField(
          label: 'Accommodation / destination address',
          controller: _accommodationController,
          placeService: _placeService,
          sessionToken: _sessionToken,
          onCleared: () {
            setState(() => _accommodationDetail = null);
            _refreshRoutePreview();
          },
          onPlaceSelected: (detail) {
            if (!_isUnitedStates(detail)) {
              CustomSnackbar.show(
                context,
                'Accommodation must be in the United States.',
              );
              return;
            }
            setState(() => _accommodationDetail = detail);
            _refreshRoutePreview();
          },
        ),
        if (widget.booking.type == BookingType.airport) ...[
          const SizedBox(height: 12),
          _buildPickupPreferenceDropdown(),
        ],
      ],
    );
  }

  Widget _buildPickupPreferenceDropdown() {
    final catalog = context.watch<CatalogProvider>();
    if (catalog.pickupPreferences.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<int>(
      value: _pickupPreferenceId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Airport pickup preference'),
      items: catalog.pickupPreferences
          .map(
            (p) => DropdownMenuItem(
              value: p.pickupPreferenceId,
              child: Text(
                '${p.preferenceName} (\$${p.preferencePrice.toStringAsFixed(2)})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _pickupPreferenceId = v),
    );
  }

  Widget _buildP2PLocations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Pickup & drop-off'),
        LocationPickerField(
          label: 'Pickup location (California)',
          controller: _pickupController,
          placeService: _placeService,
          sessionToken: _sessionToken,
          country: 'US',
          onCleared: () {
            setState(() => _pickupDetail = null);
            _refreshRoutePreview();
          },
          onPlaceSelected: (detail) {
            if (!_isCalifornia(detail)) {
              CustomSnackbar.show(context, 'Pickup must be in California.');
              return;
            }
            setState(() => _pickupDetail = detail);
            _refreshRoutePreview();
          },
        ),
        const SizedBox(height: 12),
        LocationPickerField(
          label: 'Drop-off location',
          controller: _dropoffController,
          placeService: _placeService,
          sessionToken: _sessionToken,
          onCleared: () {
            setState(() => _dropoffDetail = null);
            _refreshRoutePreview();
          },
          onPlaceSelected: (detail) {
            setState(() => _dropoffDetail = detail);
            _refreshRoutePreview();
          },
        ),
      ],
    );
  }

  Widget _buildHourlyLocations() {
    return _buildP2PLocations();
  }

  Widget _buildAirportTripType() {
    const options = [
      'Ride to the airport(one way)',
      'Ride from the airport(one way)',
      'Ride to the airport(round trip)',
      'Ride from the airport(round trip)',
    ];
    return DropdownButtonFormField<String>(
      value: options.contains(_tripType) ? _tripType : options.first,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Trip type'),
      items: options
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis, maxLines: 2),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _tripType = v;
          if (!_requiresReturn) _returnDateTime = null;
        });
      },
    );
  }

  Widget _buildP2PTripType() {
    final isRoundTrip = _tripType == 'Round-Trip';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('One way'),
          selected: !isRoundTrip,
          selectedColor: _brandGreen.withOpacity(0.2),
          onSelected: (_) => setState(() {
            _tripType = 'One-Way';
            _returnDateTime = null;
          }),
        ),
        ChoiceChip(
          label: const Text('Round trip'),
          selected: isRoundTrip,
          selectedColor: _brandGreen.withOpacity(0.2),
          onSelected: (_) => setState(() => _tripType = 'Round-Trip'),
        ),
      ],
    );
  }

  Widget _buildHourlyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Charter options'),
        DropdownButtonFormField<int>(
          value: _resolvedHours,
          decoration: const InputDecoration(labelText: 'Hours'),
          items: List.generate(
            12,
            (i) => DropdownMenuItem(
              value: i + 4,
              child: Text('${i + 4} hours'),
            ),
          ),
          onChanged: (v) {
            if (v != null) setState(() => _selectedHours = v);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _resolvedOccasion,
          decoration: const InputDecoration(labelText: 'Occasion'),
          items: BookingUpdateMapper.hourlyOccasionOptions
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _occasion = v);
          },
        ),
      ],
    );
  }

  Widget _buildPassengerCounters() {
    return Row(
      children: [
        Expanded(child: _counterTile('Passengers', _passengers, 0, 14, (v) {
          setState(() => _passengers = v);
        })),
        const SizedBox(width: 12),
        Expanded(child: _counterTile('Suitcases', _suitcases, 0, 14, (v) {
          setState(() => _suitcases = v);
        })),
      ],
    );
  }

  Widget _counterTile(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline, color: _brandGreen),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$value',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline, color: _brandGreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Schedule'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Pickup date & time'),
          subtitle: Text(DateFormat('MMM d, yyyy · h:mm a').format(_pickupDateTime)),
          trailing: const Icon(Icons.calendar_today, color: _brandGreen),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _pickupDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date == null || !mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_pickupDateTime),
            );
            if (time == null || !mounted) return;
            setState(() {
              _pickupDateTime = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            });
          },
        ),
        if (_requiresReturn)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Return date & time'),
            subtitle: Text(
              _returnDateTime != null
                  ? DateFormat('MMM d, yyyy · h:mm a').format(_returnDateTime!)
                  : 'Not set',
            ),
            trailing: const Icon(Icons.event_repeat, color: _brandGreen),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _returnDateTime ?? _pickupDateTime,
                firstDate: _pickupDateTime,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date == null || !mounted) return;
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  _returnDateTime ?? _pickupDateTime.add(const Duration(hours: 1)),
                ),
              );
              if (time == null || !mounted) return;
              setState(() {
                _returnDateTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            },
          ),
      ],
    );
  }

  Widget _buildAirlineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Flight information'),
        TextField(
          controller: _airlineController,
          decoration: const InputDecoration(labelText: 'Airline (arrival)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _arrivalFlightController,
          decoration: const InputDecoration(labelText: 'Flight number (arrival)'),
        ),
        if (_requiresReturn) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _returnAirlineController,
            decoration: const InputDecoration(labelText: 'Airline (return)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _returnFlightController,
            decoration: const InputDecoration(labelText: 'Flight number (return)'),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalStopSection(CatalogProvider catalog) {
    if (catalog.additionalStops.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Additional stop'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Additional stop on the way'),
          value: _hasAdditionalStop,
          activeColor: _brandGreen,
          onChanged: (v) {
            setState(() {
              _hasAdditionalStop = v;
              if (v && _additionalStopId == null) {
                _additionalStopId =
                    catalog.additionalStops.first.additionalStopId;
              }
            });
          },
        ),
        if (_hasAdditionalStop) ...[
          ...catalog.additionalStops.map(
            (stop) => RadioListTile<int>(
              title: Text(
                '${stop.stopType} (\$${stop.additionalStopPrice.toStringAsFixed(2)})',
              ),
              value: stop.additionalStopId,
              groupValue: _additionalStopId,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _additionalStopId = v),
            ),
          ),
          TextField(
            controller: _additionalStopDescController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Stop description',
            ),
          ),
        ],
      ],
    );
  }

  static double? _parseGratuityPercentage(dynamic gratuity) {
    if (gratuity is! Map) return null;
    final value = gratuity['percentage'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _formatMoney(double amount, [String currency = 'USD']) {
    final prefix = currency == 'USD' ? '\$' : '$currency ';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

  double _estimateCarFareAmount(CarModel car) {
    if (widget.booking.type == BookingType.hourlyCharter) {
      return car.pricePerHour * _resolvedHours;
    }
    final minimum =
        _isRoundTrip ? car.minimumStartFee * 2 : car.minimumStartFee;
    final distance = _distanceInMiles ?? _initial.distanceInMiles;
    if (distance == null || distance <= 0) return minimum;
    final perMile = car.pricePerMile * distance;
    final mileage = _isRoundTrip ? perMile * 2 : perMile;
    return minimum + mileage;
  }

  double _gratuityAmountFor(GratuityModel gratuity, double baseFare) {
    if (gratuity.percentage <= 0) return 0;
    return double.parse(
      (baseFare * (gratuity.percentage / 100)).toStringAsFixed(2),
    );
  }

  String _gratuityChipLabel(GratuityModel gratuity, double baseFare) {
    if (gratuity.percentage <= 0) {
      return 'Cash tip (${_formatMoney(0)})';
    }
    final amount = _gratuityAmountFor(gratuity, baseFare);
    final pct = gratuity.percentage == gratuity.percentage.roundToDouble()
        ? gratuity.percentage.toStringAsFixed(0)
        : gratuity.percentage.toStringAsFixed(1);
    return '$pct% (${_formatMoney(amount)})';
  }

  TripPriceBreakdown? _tripBreakdown(
    CatalogProvider catalog, {
    CarModel? car,
    GratuityModel? gratuity,
  }) {
    final vehicle = car ??
        (_selectedCarId != null
            ? catalog.findCarById(_selectedCarId!)
            : null);
    final GratuityModel? gratuityModel = gratuity ??
        catalog.gratuities
            .where((g) => g.gratuityId == _selectedGratuityId)
            .firstOrNull;
    final additionalStop = catalog.additionalStops
        .where((s) => s.additionalStopId == _additionalStopId)
        .firstOrNull;
    final pickupPref = catalog.pickupPreferences
        .where((p) => p.pickupPreferenceId == _pickupPreferenceId)
        .firstOrNull;

    switch (widget.booking.type) {
      case BookingType.airport:
        return PricingCalculator.airport(
          car: vehicle,
          distanceInMiles: _distanceInMiles,
          gratuity: gratuityModel,
          isRoundTrip: _isRoundTrip,
          extraCatalog: catalog.extraOptions,
          selectedExtras: _selectedExtras,
          additionalStop: _hasAdditionalStop ? additionalStop : null,
          pickupPreference: pickupPref,
        );
      case BookingType.pointToPoint:
        return PricingCalculator.pointToPoint(
          car: vehicle,
          distanceInMiles: _distanceInMiles,
          gratuity: gratuityModel,
          isRoundTrip: _isRoundTrip,
          extraCatalog: catalog.extraOptions,
          selectedExtras: _selectedExtras,
          additionalStop: _hasAdditionalStop ? additionalStop : null,
        );
      case BookingType.hourlyCharter:
        return PricingCalculator.hourlyCharter(
          car: vehicle,
          selectedHours: _resolvedHours,
          gratuity: gratuityModel,
          extraCatalog: catalog.extraOptions,
          selectedExtras: _selectedExtras,
        );
    }
  }

  Widget _buildGratuitySection(CatalogProvider catalog) {
    final car = _selectedCarId != null
        ? catalog.findCarById(_selectedCarId!)
        : null;
    final breakdown = _tripBreakdown(catalog, car: car, gratuity: null);
    final baseFare = breakdown?.baseFare ?? 0;
    final bookedTotal = _bookedTripTotalFee;
    final initialGratuityPct = _initialGratuityPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Gratuity'),
        if (bookedTotal != null && initialGratuityPct != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'At booking: ${initialGratuityPct <= 0 ? 'Cash tip' : '${initialGratuityPct.toStringAsFixed(0)}%'} · '
              'trip total ${_formatMoney(bookedTotal)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: catalog.gratuities.map((g) {
            final selected = _selectedGratuityId == g.gratuityId;
            final isOriginalRate = initialGratuityPct != null &&
                (g.percentage - initialGratuityPct).abs() < 0.01;
            return FilterChip(
              label: Text(
                _gratuityChipLabel(g, baseFare),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: selected,
              showCheckmark: true,
              checkmarkColor: _brandGreen,
              selectedColor: _brandGreen.withOpacity(0.22),
              backgroundColor: isOriginalRate && !selected
                  ? _brandGreen.withOpacity(0.08)
                  : null,
              side: isOriginalRate
                  ? BorderSide(color: _brandGreen.withOpacity(0.45))
                  : null,
              onSelected: (_) =>
                  setState(() => _selectedGratuityId = g.gratuityId),
            );
          }).toList(),
        ),
        if (breakdown != null && breakdown.gratuityAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selected gratuity: ${_formatMoney(breakdown.gratuityAmount)} '
              '(${breakdown.gratuityPercentage?.toStringAsFixed(0) ?? '0'}% of '
              'vehicle fare ${_formatMoney(breakdown.baseFare)})',
              style: TextStyle(
                fontSize: 12,
                color: _brandGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSummary(CatalogProvider catalog) {
    final breakdown = _tripBreakdown(catalog);
    final bookedTotal = _bookedTripTotalFee;

    if (breakdown == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGreen.withOpacity(0.3)),
        color: _brandGreen.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated service fee',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${breakdown.total.toStringAsFixed(2)} ${breakdown.currency}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _brandGreen,
            ),
          ),
          if (_distanceInMiles != null)
            Text(
              '${_distanceInMiles!.toStringAsFixed(2)} miles · '
              '${_isRoundTrip ? 'Round trip' : 'One way'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (bookedTotal != null) ...[
            const SizedBox(height: 6),
            Text(
              'Originally booked trip total: ${_formatMoney(bookedTotal)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Passenger'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Myself'),
              selected: _bookingFor == 'Myself',
              selectedColor: _brandGreen.withOpacity(0.2),
              onSelected: (_) => setState(() => _bookingFor = 'Myself'),
            ),
            ChoiceChip(
              label: const Text('Someone else'),
              selected: _bookingFor == 'SomeoneElse',
              selectedColor: _brandGreen.withOpacity(0.2),
              onSelected: (_) => setState(() => _bookingFor = 'SomeoneElse'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passengerNameController,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passengerEmailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passengerPhoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildInstructionsField() {
    return TextField(
      controller: _instructionsController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Special instructions',
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: _brandGreen,
        ),
      ),
    );
  }
}

class _UpdateVehiclePicker extends StatelessWidget {
  const _UpdateVehiclePicker({
    required this.cars,
    required this.selectedCarId,
    required this.originalCarId,
    required this.passengers,
    required this.suitcases,
    required this.onSelect,
    required this.estimateCarFare,
    required this.formatMoney,
    this.fallbackImageUrl,
    this.bookedTripTotalFee,
  });

  final List<CarModel> cars;
  final int? selectedCarId;
  final int? originalCarId;
  final int passengers;
  final int suitcases;
  final ValueChanged<int> onSelect;
  final String? fallbackImageUrl;
  final double? bookedTripTotalFee;
  final double Function(CarModel car) estimateCarFare;
  final String Function(double amount, [String currency]) formatMoney;

  String? _imageForCar(CarModel car) {
    if (car.carImageUrl != null && car.carImageUrl!.trim().isNotEmpty) {
      return car.carImageUrl;
    }
    if (fallbackImageUrl != null &&
        fallbackImageUrl!.trim().isNotEmpty &&
        (car.carId == selectedCarId || car.carId == originalCarId)) {
      return fallbackImageUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final eligible = cars.where((car) {
      return car.maxPassengers >= passengers && car.maxSuitcases >= suitcases;
    }).toList();

  final displayCars = eligible.isEmpty ? cars : eligible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _brandGreen,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 258,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayCars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final car = displayCars[index];
              final isSelected = selectedCarId == car.carId ||
                  (selectedCarId == null && originalCarId == car.carId);
              final isOriginalCar = originalCarId == car.carId;
              final estimatedFare = estimateCarFare(car);
              final estimateLabel = formatMoney(estimatedFare, car.currency);
              return GestureDetector(
                onTap: () => onSelect(car.carId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 168,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _brandGreen : Colors.grey.shade300,
                      width: isSelected ? 2.5 : 1,
                    ),
                    color: isSelected
                        ? _brandGreen.withOpacity(0.06)
                        : Colors.white,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _brandGreen.withOpacity(0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VehicleImageThumbnail(
                        imageUrl: _imageForCar(car),
                        height: 100,
                        width: 168,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        fallbackLabel: car.carType,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                car.carName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isSelected ? _brandGreen : null,
                                ),
                              ),
                              Text(
                                car.carType,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _brandGreen.withOpacity(0.14)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Est. from $estimateLabel',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? _brandGreen
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                    if (isOriginalCar &&
                                        bookedTripTotalFee != null)
                                      Text(
                                        'Booked ${formatMoney(bookedTripTotalFee!, car.currency)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${car.maxPassengers} pax · ${car.maxSuitcases} bags',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              if (isSelected)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Selected',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

bool _isUnitedStates(PlaceDetail detail) {
  final code = detail.countryCode?.toUpperCase();
  if (code != null) return code == 'US';
  final address = detail.formattedAddress.toLowerCase();
  return address.contains('united states') || address.endsWith(' usa');
}

class _RouteEndpointRow extends StatelessWidget {
  const _RouteEndpointRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isCalifornia(PlaceDetail detail) {
  final state = detail.administrativeAreaShortName?.toUpperCase();
  if (state == 'CA' && _isUnitedStates(detail)) return true;
  if (!_isUnitedStates(detail)) return false;
  final address = detail.formattedAddress.toLowerCase();
  return address.contains(', ca') || address.contains('california');
}
