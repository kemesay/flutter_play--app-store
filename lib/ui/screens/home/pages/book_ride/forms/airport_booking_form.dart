part of 'package:oda_black_car_service/ui/screens/home/pages/book_ride/book_ride_page.dart';

class AirportBookingForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;

  const AirportBookingForm({super.key, required this.formKey});

  @override
  State<AirportBookingForm> createState() => _AirportBookingFormState();
}

class _AirportBookingFormState extends State<AirportBookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _placeService = PlaceService();
  final _directionsService = DirectionsService();
  final _sessionToken = const Uuid().v4();

  static const String _allVehiclesLabel = 'All Vehicles';

  final _accommodationController = TextEditingController();
  final _airportController = TextEditingController();
  final _instructionController = TextEditingController();
  final _airlineController = TextEditingController();
  final _arrivalFlightNumberController = TextEditingController();
  final _returnAirlineController = TextEditingController();
  final _returnFlightNumberController = TextEditingController();
  final _additionalStopDescriptionController = TextEditingController();
  late final TextEditingController _passengerNameController;
  late final TextEditingController _passengerEmailController;
  late final TextEditingController _passengerPhoneController;

  // Focus nodes for date/time pickers to control focus behavior
  final _pickupDateFocusNode = FocusNode();
  final _pickupTimeFocusNode = FocusNode();
  final _returnDateFocusNode = FocusNode();
  final _returnTimeFocusNode = FocusNode();

  PlaceDetail? _accommodationDetail;
  PlaceDetail? _airportLocationDetail;
  AirportPickupPreferenceModel? _selectedPreference;

  String _tripType = 'Ride to the airport(one way)';
  int _passengers = 1;
  int _suitcases = 0;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  bool _hasAdditionalStop = false;
  int? _selectedCarId;
  int? _selectedGratuityId;
  int? _selectedAdditionalStopId;
  final List<SelectedExtraOption> _selectedExtras = [];
  String _bookingFor = 'Myself';
  bool _agreedToTerms = false;
  String _vehicleClassFilter = _allVehiclesLabel;

  PaymentMethodType _paymentMethod = PaymentMethodType.newCard;
  int? _selectedPaymentDetailId;
  String? _selectedSquareCardId;
  CardDetails? _cardDetails;
  SquarePaymentPayload? _squarePayload;
  double? _squareTokenizedAtTotal;
  double? _routeDistanceInMiles;
  String? _routeDurationText;
  List<LatLng>? _routePolyline;

  final List<PlaceDetail?> _sidePickDetails = [];
  final List<TextEditingController> _sidePickControllers = [];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider?>();
    final user = auth?.currentUser;
    _passengerNameController =
        TextEditingController(text: user?.fullName ?? '');
    _passengerEmailController = TextEditingController(text: user?.email ?? '');
    _passengerPhoneController =
        TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _accommodationController.dispose();
    _airportController.dispose();
    _instructionController.dispose();
    _airlineController.dispose();
    _arrivalFlightNumberController.dispose();
    _returnAirlineController.dispose();
    _returnFlightNumberController.dispose();
    _additionalStopDescriptionController.dispose();
    _passengerNameController.dispose();
    _passengerEmailController.dispose();
    _passengerPhoneController.dispose();
    _pickupDateFocusNode.dispose();
    _pickupTimeFocusNode.dispose();
    _returnDateFocusNode.dispose();
    _returnTimeFocusNode.dispose();
    for (final c in _sidePickControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _requiresReturnData =>
      _tripType == 'Ride to the airport(round trip)' ||
      _tripType == 'Ride from the airport(round trip)';

  bool get _isRoundTrip => _tripType.toLowerCase().contains('round trip');

  DateTime? get _pickupDateTime {
    if (_pickupDate == null || _pickupTime == null) return null;
    return DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );
  }

  DateTime? get _returnDateTime {
    if (_returnDate == null || _returnTime == null) return null;
    return DateTime(
      _returnDate!.year,
      _returnDate!.month,
      _returnDate!.day,
      _returnTime!.hour,
      _returnTime!.minute,
    );
  }

  List<CarModel> _filterCars(List<CarModel> cars) {
    if (_vehicleClassFilter == _allVehiclesLabel) {
      return cars;
    }
    final targetClass = _vehicleClassFilter.toLowerCase();
    return cars.where((car) {
      final matchesClass = car.carType.toLowerCase() == targetClass;
      if (!matchesClass) return false;
      final matchesPassengers = car.maxPassengers >= _passengers;
      final matchesSuitcases = car.maxSuitcases >= _suitcases;
      return matchesPassengers && matchesSuitcases;
    }).toList();
  }

  List<String> _buildVehicleClassOptions(List<CarModel> cars) {
    final options = <String>[_allVehiclesLabel, 'Sedan', 'SUV', 'Van'];
    for (final car in cars) {
      final type = car.carType.trim();
      if (type.isEmpty) continue;
      if (!options.contains(type)) {
        options.add(type);
      }
    }
    return options;
  }

  List<AdditionalStopModel> _availableAdditionalStops(
      List<AdditionalStopModel> stops) {
    if (stops.isEmpty) return const [];
    final keyword = _isRoundTrip ? 'greater' : 'small';
    final filtered = stops
        .where(
          (stop) => stop.stopType.toLowerCase().contains(keyword),
        )
        .toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    return stops;
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  Widget _buildRouteOverviewCard(double? straightDistance) {
    final theme = Theme.of(context);
    final routeDistance = _routeDistanceInMiles ?? straightDistance;
    // Match website: always use 2 decimal places for distance
    final distanceLabel = routeDistance != null
        ? '${routeDistance.toStringAsFixed(2)} miles'
        : 'Awaiting route';
    final durationLabel = _routeDurationText ?? 'Pending';
    final tripLabel = _readableTripType();
    final hasRoute =
        _accommodationDetail != null && _airportLocationDetail != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Airport route preview',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasRoute
                ? 'Preview the full Google Maps path and ensure we are heading to the right terminal.'
                : 'Select both airport & accommodation to visualize the route.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _RouteStopsTimeline(
            stops: [
              _RouteStop(
                label: 'Hotel / Residence',
                value: _accommodationController.text.isEmpty
                    ? 'Awaiting selection'
                    : _accommodationController.text,
                icon: Icons.home_work_outlined,
              ),
              _RouteStop(
                label: 'Airport',
                value: _airportController.text.isEmpty
                    ? 'Awaiting selection'
                    : _airportController.text,
                icon: Icons.flight_takeoff,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 260,
              child: _HourlyCharterMap(
                pickup: _accommodationDetail,
                dropoff: _airportPlaceDetail(),
                routePolyline: _routePolyline,
                routeDistance: routeDistance,
                routeDuration: _routeDurationText,
                waypoints: _sidePickDetails.whereType<PlaceDetail>().toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HourlyMetricPill(
                icon: Icons.route_outlined,
                label: 'Distance',
                value: distanceLabel,
              ),
              _HourlyMetricPill(
                icon: Icons.schedule_outlined,
                label: 'Duration',
                value: durationLabel,
              ),
              _HourlyMetricPill(
                icon: Icons.airport_shuttle_outlined,
                label: 'Trip type',
                value: tripLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PlaceDetail? _airportPlaceDetail() => _airportLocationDetail;

  bool _isValidCaliforniaAirportSelection(PlaceDetail detail) {
    if (!_isAllowedPickupState(detail)) {
      _showSnackbar(
          'Airport/terminal pickup must be in California or Washington.');
      return false;
    }
    return true;
  }

  void _handleBookingForChanged(String value, AuthProvider auth) {
    setState(() {
      _bookingFor = value;
      if (_bookingFor == 'Myself' && auth.currentUser != null) {
        _passengerNameController.text = auth.currentUser?.fullName ?? '';
        _passengerEmailController.text = auth.currentUser?.email ?? '';
        _passengerPhoneController.text = auth.currentUser?.phoneNumber ?? '';
      }
      if (_bookingFor == 'SomeoneElse') {
        _passengerNameController.clear();
        _passengerEmailController.clear();
        _passengerPhoneController.clear();
      }
    });
  }

  void _handleAdditionalStopToggle(
    bool isEnabled,
    List<AdditionalStopModel> availableStops,
  ) {
    setState(() {
      _hasAdditionalStop = isEnabled;
      if (_hasAdditionalStop && availableStops.isNotEmpty) {
        _selectedAdditionalStopId = availableStops.first.additionalStopId;
      } else {
        _selectedAdditionalStopId = null;
      }
    });
  }

  Future<void> _fetchRouteDistance() async {
    if (_airportLocationDetail == null || _accommodationDetail == null) return;
    try {
      final waypoints = _sidePickDetails
          .whereType<PlaceDetail>()
          .map((d) => LatLng(d.lat, d.lng))
          .toList();
      final route = await _directionsService.fetchRoute(
        origin: LatLng(_accommodationDetail!.lat, _accommodationDetail!.lng),
        destination: LatLng(
          _airportLocationDetail!.lat,
          _airportLocationDetail!.lng,
        ),
        waypoints: waypoints,
      );
      if (mounted && route != null) {
        setState(() {
          _routeDistanceInMiles = route.distanceMiles;
          _routeDurationText = route.durationText;
          _routePolyline = route.polyline;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _routeDistanceInMiles = null;
          _routeDurationText = null;
          _routePolyline = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Default to "Will tip in cash" (gratuity with percentage 0)
    if (_selectedGratuityId == null && catalog.gratuities.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final cashTipGratuity = catalog.gratuities.firstWhere(
            (g) => g.percentage == 0,
            orElse: () => catalog.gratuities.first,
          );
          setState(() {
            _selectedGratuityId = cashTipGratuity.gratuityId;
          });
        }
      });
    }

    // Default airport pickup preference to "Curb-Side Pickup ($0.00)" when available
    if (_selectedPreference == null && catalog.pickupPreferences.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final curbSide = catalog.pickupPreferences.firstWhere(
          (pref) => pref.preferenceName.toLowerCase().contains('curb-side'),
          orElse: () => catalog.pickupPreferences.first,
        );
        setState(() {
          _selectedPreference = curbSide;
        });
      });
    }

    final straightDistance =
        _accommodationDetail != null && _airportLocationDetail != null
            ? haversineDistanceInMiles(
                startLat: _accommodationDetail!.lat,
                startLng: _accommodationDetail!.lng,
                endLat: _airportLocationDetail!.lat,
                endLng: _airportLocationDetail!.lng,
              )
            : null;
    final effectiveDistance = _routeDistanceInMiles ?? straightDistance;

    final selectedCar =
        _selectedCarId != null ? catalog.findCarById(_selectedCarId!) : null;
    final selectedGratuity = _findGratuity(catalog, _selectedGratuityId);
    final selectedAdditionalStop =
        _findAdditionalStop(catalog, _selectedAdditionalStopId);
    // Use selected preference or default to first for pricing calculation only
    final effectivePreference = _selectedPreference ??
        (catalog.pickupPreferences.isNotEmpty
            ? catalog.pickupPreferences.first
            : null);
    final priceBreakdown = PricingCalculator.airport(
      car: selectedCar,
      distanceInMiles: effectiveDistance,
      gratuity: selectedGratuity,
      isRoundTrip: _tripType.toLowerCase().contains('round trip'),
      extraCatalog: catalog.extraOptions,
      selectedExtras: List<SelectedExtraOption>.from(_selectedExtras),
      additionalStop: selectedAdditionalStop,
      pickupPreference: effectivePreference,
    );
    final pricingSubtitle =
        _buildAirportPricingSubtitle(effectiveDistance, effectivePreference);
    final squareEnabled = context.watch<SquareRuntimeConfig>().squareEnabled;
    final consentReady = isBookingPaymentReadyForConsent(
      squareEnabled: squareEnabled,
      paymentMethod: _paymentMethod,
      squarePayload: _squarePayload,
      squareTokenizedAtTotal: _squareTokenizedAtTotal,
      currentBookingTotal: priceBreakdown?.total,
      legacyCardDetails: _cardDetails,
    );
    final consentHint = bookingPaymentConsentHint(
      squareEnabled: squareEnabled,
      paymentMethod: _paymentMethod,
      squarePayload: _squarePayload,
      squareTokenizedAtTotal: _squareTokenizedAtTotal,
      currentBookingTotal: priceBreakdown?.total,
      legacyCardDetails: _cardDetails,
    );

    final vehicleClassOptions = _buildVehicleClassOptions(catalog.cars);
    final filteredCars = _filterCars(catalog.cars);
    final availableAdditionalStops =
        _availableAdditionalStops(catalog.additionalStops);

    if (_selectedCarId != null &&
        filteredCars.every((car) => car.carId != _selectedCarId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCarId = null;
          });
        }
      });
    }

    if (_hasAdditionalStop &&
        availableAdditionalStops.isNotEmpty &&
        (_selectedAdditionalStopId == null ||
            availableAdditionalStops.every((stop) =>
                stop.additionalStopId != _selectedAdditionalStopId))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedAdditionalStopId =
                availableAdditionalStops.first.additionalStopId;
          });
        }
      });
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfessionalSectionHeader(
            title: '1. Pickup & Drop-off Locations',
            subtitle:
                'Airport pickup in California or Washington, drop-off across USA',
          ),
          const SizedBox(height: 12),
          _LocationPickerField(
            label: 'Airport / terminal pickup',
            controller: _airportController,
            placeService: _placeService,
            sessionToken: _sessionToken,
            country: 'US',
            onCleared: () {
              setState(() {
                _airportLocationDetail = null;
                _routeDistanceInMiles = null;
                _routeDurationText = null;
                _routePolyline = null;
              });
            },
            onPlaceSelected: (detail) {
              if (!_isValidCaliforniaAirportSelection(detail)) return;
              setState(() {
                _airportLocationDetail = detail;
                _routeDistanceInMiles = null;
                _routeDurationText = null;
                _routePolyline = null;
              });
              if (_accommodationDetail != null) {
                _fetchRouteDistance();
              }
            },
          ),
          const SizedBox(height: 16),
          _LocationPickerField(
            label: 'Accommodation / destination address',
            controller: _accommodationController,
            placeService: _placeService,
            sessionToken: _sessionToken,
            onCleared: () {
              setState(() {
                _accommodationDetail = null;
                _routeDistanceInMiles = null;
                _routeDurationText = null;
                _routePolyline = null;
              });
            },
            onPlaceSelected: (detail) {
              if (!_isUnitedStatesLocation(detail)) {
                _showSnackbar(
                    'Accommodation address must be located within the United States.');
                return;
              }
              setState(() {
                _accommodationDetail = detail;
                _routeDistanceInMiles = null;
                _routeDurationText = null;
                _routePolyline = null;
              });
              if (_airportLocationDetail != null) {
                _fetchRouteDistance();
              }
            },
          ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '2. Side Pick / Detour Stops',
            subtitle: 'Add off-route detours — fare adjusts by distance',
          ),
          const SizedBox(height: 8),
          ..._sidePickDetails.asMap().entries.map((entry) {
            final idx = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LocationPickerField(
                      label: 'Detour stop ${idx + 1}',
                      controller: _sidePickControllers[idx],
                      placeService: _placeService,
                      sessionToken: _sessionToken,
                      onPlaceSelected: (detail) {
                        setState(() {
                          _sidePickDetails[idx] = detail;
                        });
                        _fetchRouteDistance();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sidePickDetails.removeAt(idx);
                        _sidePickControllers[idx].dispose();
                        _sidePickControllers.removeAt(idx);
                      });
                      _fetchRouteDistance();
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red.shade400,
                    tooltip: 'Remove stop',
                  ),
                ],
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _sidePickDetails.add(null);
                _sidePickControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Add Detour Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF59E0B),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
          if (_sidePickDetails.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Detour stops add extra driving distance — fare updates automatically.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '3. Trip Type',
            subtitle: 'Select your preferred journey',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tripType,
            decoration: const InputDecoration(
              labelText: 'Trip type',
            ),
            items: const [
              DropdownMenuItem(
                value: 'Ride to the airport(one way)',
                child: Text('To the airport (one way)'),
              ),
              DropdownMenuItem(
                value: 'Ride from the airport(one way)',
                child: Text('From the airport (one way)'),
              ),
              DropdownMenuItem(
                value: 'Ride to the airport(round trip)',
                child: Text('To the airport (round trip)'),
              ),
              DropdownMenuItem(
                value: 'Ride from the airport(round trip)',
                child: Text('From the airport (round trip)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _tripType = value;
                  if (_hasAdditionalStop) {
                    final resolvedStops =
                        _availableAdditionalStops(catalog.additionalStops);
                    _selectedAdditionalStopId = resolvedStops.isNotEmpty
                        ? resolvedStops.first.additionalStopId
                        : null;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildRouteOverviewCard(straightDistance),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '4. Vehicle Selection',
            subtitle: 'Choose your preferred vehicle',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _vehicleClassFilter,
            decoration: const InputDecoration(
              labelText: 'Type / Class',
            ),
            items: vehicleClassOptions
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _vehicleClassFilter = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          _StyledCounter(
            label: 'Suitcases',
            value: _suitcases,
            min: 0,
            max: 14,
            onChanged: (value) => setState(() => _suitcases = value),
            icon: Icons.luggage_outlined,
          ),
          const SizedBox(height: 12),
          _StyledCounter(
            label: 'Passengers',
            value: _passengers,
            min: 0,
            max: 14,
            onChanged: (value) => setState(() => _passengers = value),
            icon: Icons.group_outlined,
          ),
          const SizedBox(height: 16),
          FormField<int>(
            validator: (_) {
              if (_selectedCarId == null) {
                return 'Please select a vehicle class';
              }
              return null;
            },
            builder: (state) {
              final serviceFeeValue = priceBreakdown != null
                  ? _formatCurrency(
                      priceBreakdown.total, priceBreakdown.currency)
                  : '\$0.00';

              final summaryItems = [
                _SummaryItem(label: 'Trip type', value: _readableTripType()),
                if (_airportController.text.isNotEmpty)
                  _SummaryItem(
                    label: 'Airport',
                    value: _airportController.text,
                  ),
                if (_accommodationController.text.isNotEmpty)
                  _SummaryItem(
                    label: 'Hotel / residence',
                    value: _accommodationController.text,
                  ),
                if (effectiveDistance != null)
                  _SummaryItem(
                    label: 'Distance',
                    // Match website: always use 2 decimal places
                    value: '${effectiveDistance.toStringAsFixed(2)} miles',
                  ),
                _SummaryItem(label: 'Service fee', value: serviceFeeValue),
              ];
              return _VehicleShowcase(
                cars: filteredCars.isEmpty &&
                        _vehicleClassFilter == _allVehiclesLabel
                    ? catalog.cars
                    : filteredCars,
                selectedCarId: _selectedCarId,
                distanceInMiles: effectiveDistance,
                passengers: _passengers,
                suitcases: _suitcases,
                summaryItems: summaryItems,
                isRoundTrip: _isRoundTrip,
                onSelect: (carId) {
                  setState(() {
                    _selectedCarId = carId;
                  });
                  state.didChange(carId);
                },
              );
            },
          ),
          if (catalog.extraOptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ExtraOptionsSelector(
              extraOptions: catalog.extraOptions,
              selectedOptions: _selectedExtras,
              onChanged: (value) => setState(() {
                _selectedExtras
                  ..clear()
                  ..addAll(value);
              }),
            ),
          ],
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '5. Pick & return time',
            subtitle: 'Select your preferred timing',
          ),
          const SizedBox(height: 12),
          // Wrap date/time section in FocusScope to contain focus naturally
          FocusScope(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StyledDatePicker(
                        label: 'Pickup Date',
                        date: _pickupDate,
                        onTap: () => _pickDate(isReturn: false),
                        icon: Icons.calendar_today,
                        focusNode: _pickupDateFocusNode,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StyledTimePicker(
                        label: 'Pickup time',
                        time: _pickupTime,
                        onTap: () => _pickTime(isReturn: false),
                        icon: Icons.access_time,
                        focusNode: _pickupTimeFocusNode,
                      ),
                    ),
                  ],
                ),
                if (_requiresReturnData) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StyledDatePicker(
                          label: 'Return Pickup Date',
                          date: _returnDate,
                          onTap: () => _pickDate(isReturn: true),
                          icon: Icons.calendar_today,
                          focusNode: _returnDateFocusNode,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StyledTimePicker(
                          label: 'Return Pickup Time',
                          time: _returnTime,
                          onTap: () => _pickTime(isReturn: true),
                          icon: Icons.access_time,
                          focusNode: _returnTimeFocusNode,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '6. Airline info',
            subtitle: 'Flight details for seamless coordination',
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Airline (arrival)',
            controller: _airlineController,
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Flight Number (arrival)',
            controller: _arrivalFlightNumberController,
          ),
          if (_requiresReturnData) ...[
            const SizedBox(height: 12),
            _StyledTextField(
              label: 'Airline (return)',
              controller: _returnAirlineController,
            ),
            const SizedBox(height: 12),
            _StyledTextField(
              label: 'Flight Number (return)',
              controller: _returnFlightNumberController,
            ),
          ],
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '7. Airport pickup preference',
            subtitle: 'Curated options for your arrival experience',
          ),
          const SizedBox(height: 8),
          if (catalog.pickupPreferences.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedPreference?.pickupPreferenceId,
              decoration: const InputDecoration(
                labelText: 'Airport pickup preference',
              ),
              isExpanded: true,
              items: catalog.pickupPreferences.map(
                (preference) {
                  final text =
                      '${preference.preferenceName} (\$${preference.preferencePrice.toStringAsFixed(2)})';
                  return DropdownMenuItem<int>(
                    value: preference.pickupPreferenceId,
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: true,
                    ),
                  );
                },
              ).toList(),
              selectedItemBuilder: (context) {
                return catalog.pickupPreferences.map((preference) {
                  final text =
                      '${preference.preferenceName} (\$${preference.preferencePrice.toStringAsFixed(2)})';
                  return Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                }).toList();
              },
              onChanged: (value) {
                if (value == null) return;
                final selected = catalog.pickupPreferences.firstWhere(
                  (pref) => pref.pickupPreferenceId == value,
                  orElse: () => catalog.pickupPreferences.first,
                );
                setState(() {
                  _selectedPreference = selected;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Select a pickup preference';
                }
                return null;
              },
            )
          else
            Text(
              'No pickup preferences available.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '8. Additional stop on the way',
            subtitle: 'Need an extra stop along the way?',
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Additional stop on the way'),
            value: _hasAdditionalStop,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => _handleAdditionalStopToggle(
                value ?? false, availableAdditionalStops),
          ),
          if (_hasAdditionalStop && availableAdditionalStops.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No additional stop options are available at this time.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          if (_hasAdditionalStop && availableAdditionalStops.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...availableAdditionalStops.map(
              (stop) => RadioListTile<int>(
                title: Text(
                    '${stop.stopType} (\$${stop.additionalStopPrice.toStringAsFixed(2)})'),
                value: stop.additionalStopId,
                groupValue: _selectedAdditionalStopId,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAdditionalStopId = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            _StyledTextField(
              label: "Let us know where you'd like to stop",
              controller: _additionalStopDescriptionController,
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '9. Passenger info',
            subtitle: 'Who is taking this trip?',
          ),
          const SizedBox(height: 12),
          _BookingForSection(
            bookingFor: _bookingFor,
            onChanged: (value) => _handleBookingForChanged(value, authProvider),
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Passenger full name',
            controller: _passengerNameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Passenger name is required';
              }
              return null;
            },
            enabled:
                _bookingFor != 'Myself' || authProvider.currentUser == null,
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Passenger email',
            controller: _passengerEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Passenger email is required';
              }
              final emailRegex = RegExp(
                  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$");
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
            enabled:
                _bookingFor != 'Myself' || authProvider.currentUser == null,
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Passenger phone number',
            controller: _passengerPhoneController,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Passenger phone number is required';
              }
              if (value.replaceAll(RegExp(r'\D'), '').length < 10) {
                return 'Enter a valid phone number';
              }
              return null;
            },
            enabled:
                _bookingFor != 'Myself' || authProvider.currentUser == null,
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Special Instructions',
            controller: _instructionController,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '10. Gratuity / Tip',
            subtitle: 'Show appreciation for excellent service',
          ),
          const SizedBox(height: 8),
          if (priceBreakdown != null)
            _GratuitySelector(
              gratuities: catalog.gratuities,
              selectedId: _selectedGratuityId,
              onChanged: (value) => setState(() => _selectedGratuityId = value),
              subtotal: priceBreakdown.subtotal,
              currency: priceBreakdown.currency,
            )
          else
            _GratuitySelector(
              gratuities: catalog.gratuities,
              selectedId: _selectedGratuityId,
              onChanged: (value) => setState(() => _selectedGratuityId = value),
              subtotal: 0,
              currency: 'USD',
            ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '11. Payment method',
            subtitle: 'Secure payment options',
          ),
          const SizedBox(height: 8),
          _BookingPaymentMethodPicker(
            paymentProvider: paymentProvider,
            paymentMethod: _paymentMethod,
            selectedPaymentDetailId: _selectedPaymentDetailId,
            selectedSquareCardId: _selectedSquareCardId,
            verifiedSquarePayload: _squarePayload,
            squareTokenizedAtTotal: _squareTokenizedAtTotal,
            bookingTotal: priceBreakdown?.total,
            cardholderNameHint: _passengerNameController.text.trim(),
            onSquareVerified: (payload, total) {
              setState(() {
                _squarePayload = payload;
                _squareTokenizedAtTotal = total;
              });
            },
            onSquareVerificationCleared: () {
              setState(() {
                _squarePayload = null;
                _squareTokenizedAtTotal = null;
                if (!consentReady) _agreedToTerms = false;
              });
            },
            onMethodChanged: (method) {
              setState(() {
                _paymentMethod = method;
                if (method != PaymentMethodType.existingCard) {
                  _selectedPaymentDetailId = null;
                  _selectedSquareCardId = null;
                }
                if (method != PaymentMethodType.newCard) {
                  _cardDetails = null;
                }
              });
            },
            onExistingCardSelected: (id) {
              setState(() {
                _selectedPaymentDetailId = id;
              });
            },
            onNewCardSaved: (card) {
              setState(() {
                _cardDetails = card;
              });
            },
            onSquareMethodChanged: (method) {
              setState(() {
                _paymentMethod = method;
                if (method != PaymentMethodType.squareSavedCard) {
                  _selectedPaymentDetailId = null;
                  _selectedSquareCardId = null;
                }
                if (method != PaymentMethodType.squareNewCard) {
                  _squarePayload = null;
                  _squareTokenizedAtTotal = null;
                }
                _cardDetails = null;
              });
            },
            onSquareSavedCardSelected: (card) {
              setState(() {
                applySquareSavedCardSelection(
                  setPaymentMethod: (m) => _paymentMethod = m,
                  setPaymentDetailId: (id) => _selectedPaymentDetailId = id,
                  setSquareCardId: (id) => _selectedSquareCardId = id,
                  setCardDetails: (c) => _cardDetails = c,
                  setSquarePayload: (p) => _squarePayload = p,
                  setSquareTokenizedAtTotal: (t) => _squareTokenizedAtTotal = t,
                  card: card,
                );
              });
            },
          ),
          if (priceBreakdown != null) ...[
            const SizedBox(height: 24),
            _TripPriceSummaryCard(
              breakdown: priceBreakdown,
              subtitle: pricingSubtitle,
            ),
          ],
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '12. Consent',
            subtitle: 'Review and confirm your booking',
          ),
          if (consentHint != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      consentHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          CheckboxListTile(
            value: _agreedToTerms,
            contentPadding: EdgeInsets.zero,
            onChanged: consentReady
                ? (value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  }
                : null,
            title: const Text(
              'I confirm the trip details above and authorize ODA Black Car Service to process payment for this booking.',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: bookingProvider.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.flight_takeoff),
              label: const Text('Submit airport booking'),
              onPressed:
                  bookingProvider.isSubmitting ? null : () => _submit(context),
            ),
          ),
        ],
      ),
    );
  }

  // Get minimum time for pickup based on selected date (like React's minTimeForPickup)
  TimeOfDay? _getMinTimeForPickupAirport(DateTime? selectedDate) {
    if (selectedDate == null) return null;
    final minBookingTime = _getMinBookingTimeAirport();
    final isSameDay = _isPickupDateSameAsMinimumAirport(selectedDate);

    if (isSameDay) {
      return TimeOfDay(
          hour: minBookingTime.hour, minute: minBookingTime.minute);
    }
    // For future dates, allow any time from start of day
    return const TimeOfDay(hour: 0, minute: 0);
  }

  // Get minimum time for return based on selected date (like React's minTimeForReturn)
  TimeOfDay? _getMinTimeForReturnAirport(DateTime? selectedDate) {
    if (_pickupDate == null || _pickupTime == null || selectedDate == null) {
      return null;
    }
    final minReturnTime = _getMinReturnTimeAirport(_pickupDate, _pickupTime);
    if (minReturnTime == null) return null;

    final minReturnDate = DateTime(
      minReturnTime.year,
      minReturnTime.month,
      minReturnTime.day,
    );
    final isSameDay = selectedDate.year == minReturnDate.year &&
        selectedDate.month == minReturnDate.month &&
        selectedDate.day == minReturnDate.day;

    if (isSameDay) {
      return TimeOfDay(hour: minReturnTime.hour, minute: minReturnTime.minute);
    }
    // For future dates, allow any time from start of day
    return const TimeOfDay(hour: 0, minute: 0);
  }

  Future<void> _pickDate({required bool isReturn}) async {
    // Save scroll position before opening picker
    _BookRidePageState.saveScrollPositionStatic();
    // Unfocus any current focus to prevent auto-jump after picker closes
    FocusScope.of(context).unfocus();

    if (isReturn) {
      // For return trips, minimum is 1 hour after pickup
      if (_pickupDate == null || _pickupTime == null) {
        CustomSnackbar.show(
            context, 'Please select pickup date and time first.');
        return;
      }

      final minReturnTime = _getMinReturnTimeAirport(_pickupDate, _pickupTime);
      if (minReturnTime == null) return;

      final minReturnDate =
          DateTime(minReturnTime.year, minReturnTime.month, minReturnTime.day);
      final initialDate = _returnDate ?? minReturnTime;
      final effectiveInitialDate =
          initialDate.isBefore(minReturnDate) ? minReturnDate : initialDate;

      final date = await showDatePicker(
        context: context,
        initialDate: effectiveInitialDate,
        firstDate: minReturnDate,
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null || !mounted) {
        // Keep focus removed if user cancels
        FocusScope.of(context).unfocus();
        return;
      }

      setState(() {
        _returnDate = date;

        // If time exists and is invalid for the new date, clear it (user must re-select)
        if (_returnTime != null) {
          final returnDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            _returnTime!.hour,
            _returnTime!.minute,
          );
          if (returnDateTime.isBefore(minReturnTime)) {
            _returnTime =
                null; // Clear invalid time - user must select valid time
          }
        }
      });

      // Unfocus after selection to keep focus within date/time section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).unfocus();
          // Restore scroll position to prevent unwanted scrolling
          _BookRidePageState.restoreScrollPositionStatic();
        }
      });
      return;
    }

    // For pickup date - same validation rules for both one-way and round-trip
    final minBookingTime = _getMinBookingTimeAirport();
    final minBookingDate = _getMinBookingDateAirport();
    final initialDate = _pickupDate ?? minBookingTime;
    final effectiveInitialDate =
        initialDate.isBefore(minBookingDate) ? minBookingDate : initialDate;

    final date = await showDatePicker(
      context: context,
      initialDate: effectiveInitialDate,
      firstDate: minBookingDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      // Keep focus removed if user cancels
      FocusScope.of(context).unfocus();
      return;
    }

    setState(() {
      _pickupDate = date;

      // If time exists and is invalid for the new date, clear it (user must re-select)
      if (_pickupTime != null) {
        final isSameDay = _isPickupDateSameAsMinimumAirport(date);
        if (isSameDay) {
          final selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            _pickupTime!.hour,
            _pickupTime!.minute,
          );
          if (selectedDateTime.isBefore(minBookingTime)) {
            _pickupTime =
                null; // Clear invalid time - user must select valid time
          }
        }
      }
    });

    // Unfocus after selection to keep focus within date/time section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        // Restore scroll position to prevent unwanted scrolling
        _BookRidePageState.restoreScrollPositionStatic();
      }
    });
  }

  Future<void> _pickTime({required bool isReturn}) async {
    // Save scroll position before opening picker
    _BookRidePageState.saveScrollPositionStatic();
    // Unfocus any current focus to prevent auto-jump after picker closes
    FocusScope.of(context).unfocus();

    if (isReturn) {
      // For return trips, minimum is 1 hour after pickup
      if (_pickupDate == null || _pickupTime == null) {
        CustomSnackbar.show(
            context, 'Please select pickup date and time first.');
        return;
      }

      if (_returnDate == null) {
        CustomSnackbar.show(context, 'Please select a return date first.');
        return;
      }

      final minReturnTime = _getMinReturnTimeAirport(_pickupDate, _pickupTime);
      if (minReturnTime == null) return;

      // Get minimum time for the selected return date (like React's minTimeForReturn)
      final minTimeForReturn = _getMinTimeForReturnAirport(_returnDate);
      final initialTime = _returnTime ??
          minTimeForReturn ??
          TimeOfDay(
            hour: minReturnTime.hour,
            minute: minReturnTime.minute,
          );

      TimeOfDay? selectedTime;
      TimeOfDay currentInitialTime = initialTime;

      // Keep prompting until user selects a valid time (like React prevents invalid selection)
      while (mounted) {
        final timeOfDay = await showTimePicker(
          context: context,
          initialTime: currentInitialTime,
        );

        if (timeOfDay == null) {
          // Keep focus removed if user cancels
          FocusScope.of(context).unfocus();
          return;
        }

        final selectedDateTime = DateTime(
          _returnDate!.year,
          _returnDate!.month,
          _returnDate!.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        // Validate: time must be at least 1 hour after pickup (like React)
        if (selectedDateTime.isBefore(minReturnTime)) {
          // Invalid selection - show error and re-prompt with minimum time
          CustomSnackbar.show(
            context,
            'Return pickup must be at least 1 hour after pickup time. Please select a later time.',
          );
          // Update initial time to minimum for next prompt
          currentInitialTime =
              TimeOfDay(hour: minReturnTime.hour, minute: minReturnTime.minute);
          // Continue loop to re-prompt
          continue;
        } else {
          // Valid selection
          selectedTime = timeOfDay;
          break;
        }
      }

      if (selectedTime != null && mounted) {
        setState(() {
          _returnTime = selectedTime;
        });
      }

      // Unfocus after selection to keep focus within date/time section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).unfocus();
          // Restore scroll position to prevent unwanted scrolling
          _BookRidePageState.restoreScrollPositionStatic();
        }
      });
      return;
    }

    // For pickup time - same validation rules for both one-way and round-trip
    final minBookingTime = _getMinBookingTimeAirport();
    final currentDate = _pickupDate;

    if (currentDate == null) {
      CustomSnackbar.show(context, 'Please select a date first.');
      return;
    }

    // Get minimum time for the selected date (like React's minTimeForPickup)
    final minTimeForPickup = _getMinTimeForPickupAirport(currentDate);
    final initialTime =
        _pickupTime ?? minTimeForPickup ?? const TimeOfDay(hour: 9, minute: 0);

    TimeOfDay? selectedTime;
    TimeOfDay currentInitialTime = initialTime;

    // Keep prompting until user selects a valid time (like React prevents invalid selection)
    while (mounted) {
      final timeOfDay = await showTimePicker(
        context: context,
        initialTime: currentInitialTime,
      );

      if (timeOfDay == null) {
        // Keep focus removed if user cancels
        FocusScope.of(context).unfocus();
        return;
      }

      final selectedDateTime = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      // Validate: time must be at least 1 hour in advance (like React)
      if (selectedDateTime.isBefore(minBookingTime)) {
        // Invalid selection - show error and re-prompt with minimum time
        CustomSnackbar.show(
          context,
          'Bookings must be at least 1 hour in advance. Please select a later time.',
        );
        // Update initial time to minimum for next prompt
        currentInitialTime =
            TimeOfDay(hour: minBookingTime.hour, minute: minBookingTime.minute);
        // Continue loop to re-prompt
        continue;
      } else {
        // Valid selection
        selectedTime = timeOfDay;
        break;
      }
    }

    if (selectedTime != null && mounted) {
      setState(() {
        _pickupTime = selectedTime;
      });
    }

    // Unfocus after selection to keep focus within date/time section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        // Restore scroll position to prevent unwanted scrolling
        _BookRidePageState.restoreScrollPositionStatic();
      }
    });
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDate == null || _pickupTime == null) {
      _showSnackbar('Select pickup date and time.');
      return;
    }

    // Validate 1-hour advance booking requirement (like React website)
    final pickupDateTime = DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      _pickupTime!.hour,
      _pickupTime!.minute,
    );
    final minBookingTime = _getMinBookingTimeAirport();
    if (pickupDateTime.isBefore(minBookingTime)) {
      // Invalid time - prompt user to select valid time (no auto-correction)
      _showSnackbar(
          'Pickup time must be at least 1 hour in advance. Please select a valid time.');
      // Re-open time picker
      _pickTime(isReturn: false);
      return;
    }

    if (_requiresReturnData && (_returnDate == null || _returnTime == null)) {
      _showSnackbar('Select return pickup date and time.');
      return;
    }

    // Validate return time is at least 1 hour after pickup (like React website)
    if (_requiresReturnData && _returnDate != null && _returnTime != null) {
      final returnDateTime = DateTime(
        _returnDate!.year,
        _returnDate!.month,
        _returnDate!.day,
        _returnTime!.hour,
        _returnTime!.minute,
      );
      final minReturnTime = pickupDateTime.add(const Duration(hours: 1));
      if (returnDateTime.isBefore(minReturnTime)) {
        // Invalid time - prompt user to select valid time (no auto-correction)
        _showSnackbar(
            'Return pickup time must be at least 1 hour after pickup. Please select a valid time.');
        // Re-open time picker
        _pickTime(isReturn: true);
        return;
      }
    }
    if (_airportLocationDetail == null || _accommodationDetail == null) {
      _showSnackbar('Select airport and accommodation.');
      return;
    }
    if (_airportLocationDetail!.lat == 0 ||
        _airportLocationDetail!.lng == 0 ||
        _accommodationDetail!.lat == 0 ||
        _accommodationDetail!.lng == 0) {
      _showSnackbar(
          'Please select both airport and accommodation from Google suggestions.');
      return;
    }
    if (_airportController.text.trim().isEmpty) {
      _showSnackbar('Select airport pickup from suggestions.');
      return;
    }
    if (!_isValidCaliforniaAirportSelection(_airportLocationDetail!)) {
      return;
    }
    if (_selectedCarId == null) {
      _showSnackbar('Select vehicle.');
      return;
    }
    if (_selectedGratuityId == null) {
      _showSnackbar('Select gratuity preference.');
      return;
    }
    final catalog = context.read<CatalogProvider>();
    final squareEnabled = context.read<SquareRuntimeConfig>().squareEnabled;
    final effectiveDistance = _routeDistanceInMiles ??
        (_accommodationDetail != null && _airportLocationDetail != null
            ? haversineDistanceInMiles(
                startLat: _accommodationDetail!.lat,
                startLng: _accommodationDetail!.lng,
                endLat: _airportLocationDetail!.lat,
                endLng: _airportLocationDetail!.lng,
              )
            : null);
    final effectivePreference = _selectedPreference ??
        (catalog.pickupPreferences.isNotEmpty
            ? catalog.pickupPreferences.first
            : null);
    final bookingTotal = PricingCalculator.airport(
      car: _selectedCarId != null ? catalog.findCarById(_selectedCarId!) : null,
      distanceInMiles: effectiveDistance,
      gratuity: _findGratuity(catalog, _selectedGratuityId),
      isRoundTrip: _tripType.toLowerCase().contains('round trip'),
      extraCatalog: catalog.extraOptions,
      selectedExtras: List<SelectedExtraOption>.from(_selectedExtras),
      additionalStop: _findAdditionalStop(catalog, _selectedAdditionalStopId),
      pickupPreference: effectivePreference,
    )?.total;

    if (squareEnabled) {
      final paymentError = validateBookingPaymentSelection(
        paymentMethod: _paymentMethod,
        paymentDetailId: _selectedPaymentDetailId,
        squareCardId: _selectedSquareCardId,
        cardDetails: _cardDetails,
        primaryCard: context.read<PaymentProvider>().primaryCard,
        squarePayload: _squarePayload,
        squareTokenizedAtTotal: _squareTokenizedAtTotal,
        currentBookingTotal: bookingTotal,
        squareEnabled: true,
      );
      if (paymentError != null) {
        _showSnackbar(paymentError);
        return;
      }
    } else {
      if (_paymentMethod == PaymentMethodType.primaryCard) {
        final primaryCard = context.read<PaymentProvider>().primaryCard;
        if (primaryCard == null) {
          _showSnackbar('You do not have a primary card on file.');
          return;
        }
        _selectedPaymentDetailId = null;
      } else if (_paymentMethod == PaymentMethodType.existingCard) {
        if (_selectedPaymentDetailId == null) {
          _showSnackbar('Select a saved card to proceed.');
          return;
        }
      } else if (_paymentMethod == PaymentMethodType.newCard &&
          _cardDetails == null) {
        _showSnackbar('Provide payment card details.');
        return;
      }
    }
    if (!_agreedToTerms) {
      _showSnackbar('Please confirm the booking details.');
      return;
    }

    final passengerFullName = _passengerNameController.text.trim();
    final passengerEmail = _passengerEmailController.text.trim();
    final passengerPhone = _passengerPhoneController.text.trim();

    if (passengerFullName.isEmpty ||
        passengerEmail.isEmpty ||
        passengerPhone.isEmpty) {
      _showSnackbar('Passenger information is required.');
      return;
    }

    final bookingProvider = context.read<BookingProvider>();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final distance = _routeDistanceInMiles ??
        haversineDistanceInMiles(
          startLat: _accommodationDetail!.lat,
          startLng: _accommodationDetail!.lng,
          endLat: _airportLocationDetail!.lat,
          endLng: _airportLocationDetail!.lng,
        );

    final request = AirportBookingRequest(
      tripType: _tripType,
      airportLocationAddress: _airportController.text.trim(),
      airportLocationLatitude: _airportLocationDetail!.lat,
      airportLocationLongitude: _airportLocationDetail!.lng,
      numberOfPassengers: _passengers,
      numberOfSuitcases: _suitcases,
      accommodationAddress: _accommodationDetail!.formattedAddress,
      accommodationLongitude: _accommodationDetail!.lng,
      accommodationLatitude: _accommodationDetail!.lat,
      pickupDateTime: dateFormatter.format(_pickupDateTime!),
      returnPickupDateTime: _returnDateTime != null
          ? dateFormatter.format(_returnDateTime!)
          : null,
      airline: _airlineController.text.isEmpty ? null : _airlineController.text,
      arrivalFlightNumber: _arrivalFlightNumberController.text.isEmpty
          ? null
          : _arrivalFlightNumberController.text,
      returnAirline: _returnAirlineController.text.isEmpty
          ? null
          : _returnAirlineController.text,
      returnFlightNumber: _returnFlightNumberController.text.isEmpty
          ? null
          : _returnFlightNumberController.text,
      distanceInMiles: distance,
      carId: _selectedCarId!,
      additionalStopId: _hasAdditionalStop ? _selectedAdditionalStopId : null,
      additionalStopOnTheWayDescription: _hasAdditionalStop &&
              _additionalStopDescriptionController.text.isNotEmpty
          ? _additionalStopDescriptionController.text
          : null,
      pickupPreferenceId: _selectedPreference?.pickupPreferenceId,
      extraOptions: _selectedExtras,
      bookingFor: _bookingFor,
      passengerFullName: passengerFullName,
      passengerCellPhone: passengerPhone,
      passengerEmail: passengerEmail,
      gratuityId: _selectedGratuityId!,
      isGuestBooking: false,
      paymentMethod: _paymentMethod,
      paymentDetailId: _selectedPaymentDetailId,
      cardDetails:
          _paymentMethod == PaymentMethodType.newCard ? _cardDetails : null,
      square: _paymentMethod == PaymentMethodType.squareNewCard
          ? _squarePayload
          : null,
      squareCardId: _paymentMethod == PaymentMethodType.squareSavedCard
          ? _selectedSquareCardId
          : null,
      specialInstructions: _instructionController.text.trim().isEmpty
          ? null
          : _instructionController.text.trim(),
      sidePicks: _sidePickDetails
          .whereType<PlaceDetail>()
          .toList()
          .asMap()
          .entries
          .map((e) => <String, dynamic>{
                'address': e.value.formattedAddress,
                'latitude': e.value.lat,
                'longitude': e.value.lng,
                'sortOrder': e.key,
              })
          .toList(),
    );

    final success = await bookingProvider.submitAirportBooking(
      request,
      authenticated: true,
    );
    if (success && mounted) {
      CustomSnackbar.showSuccess(
        context,
        bookingProvider.successMessage ??
            'Airport booking submitted. We will confirm shortly.',
      );
      bookingProvider.clearMessages();
      _BookRidePageState.scrollToTopStatic();
    } else if (!success && mounted) {
      _showSnackbar(
          bookingProvider.errorMessage ?? 'Unable to submit booking.');
    }
  }

  GratuityModel? _findGratuity(CatalogProvider catalog, int? gratuityId) {
    if (gratuityId == null) return null;
    for (final gratuity in catalog.gratuities) {
      if (gratuity.gratuityId == gratuityId) return gratuity;
    }
    return null;
  }

  AdditionalStopModel? _findAdditionalStop(
    CatalogProvider catalog,
    int? additionalStopId,
  ) {
    if (additionalStopId == null) return null;
    for (final stop in catalog.additionalStops) {
      if (stop.additionalStopId == additionalStopId) return stop;
    }
    return null;
  }

  String? _buildAirportPricingSubtitle(
    double? distance,
    AirportPickupPreferenceModel? preference,
  ) {
    final segments = <String>[];
    if (distance != null) {
      // Match website: always use 2 decimal places
      final rounded = distance.toStringAsFixed(2);
      segments.add('$rounded miles');
    }

    segments.add(_readableTripType());

    if (preference != null) {
      segments.add(preference.preferenceName);
    }

    return segments.join(' • ');
  }

  String _readableTripType() {
    return switch (_tripType) {
      'Ride to the airport(one way)' => 'To airport · One-way',
      'Ride from the airport(one way)' => 'From airport · One-way',
      'Ride to the airport(round trip)' => 'To airport · Round trip',
      'Ride from the airport(round trip)' => 'From airport · Round trip',
      _ => _tripType,
    };
  }

  void _showSnackbar(String message) {
    // Use the CustomSnackbar from the main library
    CustomSnackbar.show(context, message);
  }
}

// Utility function to get minimum allowed booking time (1 hour from now)
// Matches React website implementation: minimumPickupLeadTime = currentDateTime.add(1, "hour")
DateTime _getMinBookingTimeAirport() {
  final now = DateTime.now();
  // Add 1 hour and reset seconds/milliseconds to 0 (like React: .second(0).millisecond(0))
  return DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    0, // seconds
    0, // milliseconds
  ).add(const Duration(hours: 1));
}

// Get minimum date (start of day for minimum pickup lead time)
DateTime _getMinBookingDateAirport() {
  final minTime = _getMinBookingTimeAirport();
  return DateTime(minTime.year, minTime.month, minTime.day);
}

// Check if selected date is the same as minimum date (today)
bool _isPickupDateSameAsMinimumAirport(DateTime? selectedDate) {
  if (selectedDate == null) return false;
  final minDate = _getMinBookingDateAirport();
  return selectedDate.year == minDate.year &&
      selectedDate.month == minDate.month &&
      selectedDate.day == minDate.day;
}

// Ensure valid pickup time - auto-corrects if time is too early (like React's ensureValidPickupTime)
DateTime _ensureValidPickupTimeAirport(
    DateTime? selectedDate, TimeOfDay? selectedTime) {
  final minBookingTime = _getMinBookingTimeAirport();

  if (selectedTime == null) return minBookingTime;
  if (selectedDate == null) {
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
  }

  final combined = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
    selectedTime.hour,
    selectedTime.minute,
  );

  // If combined time is before minimum, return minimum time (auto-correction)
  if (combined.isBefore(minBookingTime)) {
    return minBookingTime;
  }

  return combined;
}

// Get minimum return time (1 hour after pickup, like React: pickupDateTime.add(1, "hour"))
DateTime? _getMinReturnTimeAirport(
    DateTime? pickupDate, TimeOfDay? pickupTime) {
  if (pickupDate == null || pickupTime == null) return null;
  final pickupDateTime = DateTime(
    pickupDate.year,
    pickupDate.month,
    pickupDate.day,
    pickupTime.hour,
    pickupTime.minute,
  );
  return pickupDateTime.add(const Duration(hours: 1));
}
