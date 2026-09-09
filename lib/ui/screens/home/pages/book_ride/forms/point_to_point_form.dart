part of 'package:oda_black_car_service/ui/screens/home/pages/book_ride/book_ride_page.dart';

class _PointToPointForm extends StatefulWidget {
  const _PointToPointForm({super.key});

  @override
  State<_PointToPointForm> createState() => _PointToPointFormState();
}

// Utility function to get minimum allowed booking time (1 hour from now)
// Matches React website implementation: minimumPickupLeadTime = currentDateTime.add(1, "hour")
DateTime _getMinBookingTimePointToPoint() {
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
DateTime _getMinBookingDatePointToPoint() {
  final minTime = _getMinBookingTimePointToPoint();
  return DateTime(minTime.year, minTime.month, minTime.day);
}

// Check if selected date is the same as minimum date (today)
bool _isPickupDateSameAsMinimum(DateTime? selectedDate) {
  if (selectedDate == null) return false;
  final minDate = _getMinBookingDatePointToPoint();
  return selectedDate.year == minDate.year &&
      selectedDate.month == minDate.month &&
      selectedDate.day == minDate.day;
}

// Ensure valid pickup time - auto-corrects if time is too early (like React's ensureValidPickupTime)
DateTime _ensureValidPickupTime(
    DateTime? selectedDate, TimeOfDay? selectedTime) {
  final minBookingTime = _getMinBookingTimePointToPoint();

  if (selectedTime == null) return minBookingTime;
  if (selectedDate == null) {
    // If no date, return time with today's date
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

class _PointToPointFormState extends State<_PointToPointForm> {
  static const String _allVehiclesLabel = 'All Vehicles';

  final _formKey = GlobalKey<FormState>();
  final _placeService = PlaceService();
  final _directionsService = DirectionsService();
  final _sessionToken = const Uuid().v4();

  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _additionalStopDescriptionController = TextEditingController();
  late final TextEditingController _passengerNameController;
  late final TextEditingController _passengerEmailController;
  late final TextEditingController _passengerPhoneController;

  // Focus nodes for date/time pickers to control focus behavior
  final _pickupDateFocusNode = FocusNode();
  final _pickupTimeFocusNode = FocusNode();
  final _returnDateFocusNode = FocusNode();
  final _returnTimeFocusNode = FocusNode();

  PlaceDetail? _pickupDetail;
  PlaceDetail? _dropoffDetail;

  DateTime? _pickupDateTime;
  DateTime? _returnDateTime;

  String _tripType = 'One-Way';
  int _passengers = 1;
  int _suitcases = 0;
  int? _selectedCarId;
  int? _selectedGratuityId;
  int? _selectedAdditionalStopId;
  String _bookingFor = 'Myself';
  bool _hasAdditionalStop = false;
  bool _agreedToTerms = false;
  String _vehicleClassFilter = _allVehiclesLabel;

  PaymentMethodType _paymentMethod = PaymentMethodType.newCard;
  int? _selectedPaymentDetailId;
  String? _selectedSquareCardId;
  CardDetails? _cardDetails;
  SquarePaymentPayload? _squarePayload;
  double? _squareTokenizedAtTotal;
  final List<SelectedExtraOption> _selectedExtras = [];
  double? _routeDistanceInMiles;
  String? _routeDurationText;
  List<LatLng>? _routePolyline;

  final List<PlaceDetail?> _sidePickDetails = [];
  final List<TextEditingController> _sidePickControllers = [];

  bool get _isRoundTrip => _tripType == 'Round-Trip';
  TimeOfDay? get _pickupTimeOfDay => _pickupDateTime != null
      ? TimeOfDay(hour: _pickupDateTime!.hour, minute: _pickupDateTime!.minute)
      : null;
  TimeOfDay? get _returnTimeOfDay => _returnDateTime != null
      ? TimeOfDay(hour: _returnDateTime!.hour, minute: _returnDateTime!.minute)
      : null;

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
    _pickupController.dispose();
    _dropoffController.dispose();
    _instructionsController.dispose();
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

  // Get minimum return time (1 hour after pickup, like React: pickupDateTime.add(1, "hour"))
  DateTime? _getMinReturnTimePointToPoint() {
    if (_pickupDateTime == null) return null;
    return _pickupDateTime!.add(const Duration(hours: 1));
  }

  Future<void> _pickDateOnly({required bool isReturn}) async {
    // Save scroll position before opening picker
    _BookRidePageState.saveScrollPositionStatic();
    // Unfocus any current focus to prevent auto-jump after picker closes
    FocusScope.of(context).unfocus();

    if (isReturn) {
      // For return trips, minimum is 1 hour after pickup
      final minReturnTime = _getMinReturnTimePointToPoint();
      if (minReturnTime == null) {
        CustomSnackbar.show(
            context, 'Please select pickup date and time first.');
        return;
      }

      final minReturnDate =
          DateTime(minReturnTime.year, minReturnTime.month, minReturnTime.day);
      final initialDate = _returnDateTime ?? minReturnTime;
      final effectiveInitialDate =
          initialDate.isBefore(minReturnTime) ? minReturnTime : initialDate;

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
        final baseDateTime = _returnDateTime ??
            DateTime(date.year, date.month, date.day, minReturnTime.hour,
                minReturnTime.minute);
        _returnDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          baseDateTime.hour,
          baseDateTime.minute,
        );

        // Auto-correct time if needed
        final minReturn = _getMinReturnTimePointToPoint();
        if (minReturn != null && _returnDateTime!.isBefore(minReturn)) {
          _returnDateTime = minReturn;
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
    final minBookingTime = _getMinBookingTimePointToPoint();
    final minBookingDate = _getMinBookingDatePointToPoint();
    final currentDateTime = _pickupDateTime;
    final initialDate = currentDateTime ?? minBookingTime;
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
      final baseDateTime =
          currentDateTime ?? DateTime(date.year, date.month, date.day, 9, 0);

      final updated = DateTime(
        date.year,
        date.month,
        date.day,
        baseDateTime.hour,
        baseDateTime.minute,
      );

      _pickupDateTime = updated;

      // If same day and time is too early, auto-correct to minimum time
      final isSameDay = _isPickupDateSameAsMinimum(date);
      if (isSameDay) {
        final currentTime =
            TimeOfDay(hour: updated.hour, minute: updated.minute);
        final corrected = _ensureValidPickupTime(date, currentTime);
        if (corrected != updated) {
          _pickupDateTime = corrected;
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

  Future<void> _pickTimeOnly({required bool isReturn}) async {
    // Save scroll position before opening picker
    _BookRidePageState.saveScrollPositionStatic();
    // Unfocus any current focus to prevent auto-jump after picker closes
    FocusScope.of(context).unfocus();

    if (isReturn) {
      // For return trips, minimum is 1 hour after pickup
      if (_pickupDateTime == null) {
        CustomSnackbar.show(
            context, 'Please select pickup date and time first.');
        return;
      }

      final minReturnTime = _getMinReturnTimePointToPoint();
      if (minReturnTime == null) return;

      final currentDateTime = _returnDateTime;
      if (currentDateTime == null) {
        CustomSnackbar.show(context, 'Please select a return date first.');
        return;
      }

      final initialTime = TimeOfDay(
        hour: currentDateTime.hour,
        minute: currentDateTime.minute,
      );

      final timeOfDay = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      if (timeOfDay == null || !mounted) {
        // Keep focus removed if user cancels
        FocusScope.of(context).unfocus();
        return;
      }

      final selectedDateTime = DateTime(
        currentDateTime.year,
        currentDateTime.month,
        currentDateTime.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      // Auto-correct if time is before minimum (1 hour after pickup)
      final correctedDateTime = selectedDateTime.isBefore(minReturnTime)
          ? minReturnTime
          : selectedDateTime;

      if (selectedDateTime.isBefore(minReturnTime)) {
        CustomSnackbar.showInfo(
          context,
          'Return pickup must be at least 1 hour after pickup time. Time adjusted automatically.',
        );
      }

      setState(() {
        _returnDateTime = correctedDateTime;
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

    // For pickup time - same validation rules for both one-way and round-trip
    final minBookingTime = _getMinBookingTimePointToPoint();
    final currentDateTime = _pickupDateTime;

    if (currentDateTime == null) {
      CustomSnackbar.show(context, 'Please select a date first.');
      return;
    }

    final initialTime = TimeOfDay(
      hour: currentDateTime.hour,
      minute: currentDateTime.minute,
    );

    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (timeOfDay == null || !mounted) {
      // Keep focus removed if user cancels
      FocusScope.of(context).unfocus();
      return;
    }

    // Use ensureValidPickupTime to auto-correct if needed (like React)
    final selectedDate = DateTime(
        currentDateTime.year, currentDateTime.month, currentDateTime.day);
    final corrected = _ensureValidPickupTime(selectedDate, timeOfDay);

    // Show message if time was auto-corrected
    final selectedDateTime = DateTime(
      currentDateTime.year,
      currentDateTime.month,
      currentDateTime.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    if (selectedDateTime.isBefore(minBookingTime)) {
      CustomSnackbar.showInfo(
        context,
        'Bookings must be at least 1 hour in advance. Time adjusted automatically.',
      );
    }

    setState(() {
      _pickupDateTime = corrected;
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

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    final authProvider = context.watch<AuthProvider>();

    _ensureDefaults(catalog);

    final calculatedDistance = _calculateDistanceInMiles();
    final distanceInMiles = _routeDistanceInMiles ?? calculatedDistance;

    final selectedCar =
        _selectedCarId != null ? catalog.findCarById(_selectedCarId!) : null;
    final selectedGratuity = _findGratuity(catalog, _selectedGratuityId);
    final selectedAdditionalStop =
        _findAdditionalStop(catalog, _selectedAdditionalStopId);
    final priceBreakdown = PricingCalculator.pointToPoint(
      car: selectedCar,
      distanceInMiles: distanceInMiles,
      gratuity: selectedGratuity,
      isRoundTrip: _isRoundTrip,
      extraCatalog: catalog.extraOptions,
      selectedExtras: List<SelectedExtraOption>.from(_selectedExtras),
      additionalStop: selectedAdditionalStop,
    );
    final pricingSubtitle = _buildPointToPointPricingSubtitle(distanceInMiles);
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

    if (!_hasAdditionalStop && _selectedAdditionalStopId != null) {
      _hasAdditionalStop = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (catalog.isLoading) const LinearProgressIndicator(),
        if (catalog.isLoading) const SizedBox(height: 8),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProfessionalSectionHeader(
                title: '1. Pickup & Drop-off Locations',
                subtitle: 'Enter your journey details',
              ),
              const SizedBox(height: 12),
              _LocationPickerField(
                label: 'Pickup location',
                controller: _pickupController,
                placeService: _placeService,
                sessionToken: _sessionToken,
                onPlaceSelected: (detail) {
                  if (!_isValidPointToPointPickup(detail)) return;
                  setState(() {
                    _pickupDetail = detail;
                    _routeDistanceInMiles = null;
                    _routeDurationText = null;
                    _routePolyline = null;
                  });
                  if (_dropoffDetail != null) {
                    _fetchRouteDistance();
                  }
                },
              ),
              const SizedBox(height: 16),
              _LocationPickerField(
                label: 'Drop-off location',
                controller: _dropoffController,
                placeService: _placeService,
                sessionToken: _sessionToken,
                onPlaceSelected: (detail) {
                  setState(() {
                    _dropoffDetail = detail;
                    _routeDistanceInMiles = null;
                    _routeDurationText = null;
                    _routePolyline = null;
                  });
                  if (_pickupDetail != null) {
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
              _TripTypeSelector(
                tripType: _tripType,
                onChanged: (value) {
                  setState(() {
                    _tripType = value;
                    if (!_isRoundTrip) {
                      _returnDateTime = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildRouteOverviewCard(calculatedDistance),
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
                  final summaryItems = [
                    _SummaryItem(label: 'Trip type', value: _tripType),
                    if (_pickupController.text.isNotEmpty)
                      _SummaryItem(
                        label: 'Pickup addr.',
                        value: _pickupController.text,
                      ),
                    if (_dropoffController.text.isNotEmpty)
                      _SummaryItem(
                        label: 'Drop-off addr.',
                        value: _dropoffController.text,
                      ),
                    if (distanceInMiles != null)
                      _SummaryItem(
                        label: 'Distance',
                        value:
                            // Match website: always use 2 decimal places
                            '${distanceInMiles.toStringAsFixed(2)} miles',
                      ),
                    const _SummaryItem(label: 'Service fee', value: '\$0.00'),
                  ];
                  return _VehicleShowcase(
                    cars: filteredCars,
                    selectedCarId: _selectedCarId,
                    distanceInMiles: distanceInMiles,
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
                  onChanged: (options) => setState(() {
                    _selectedExtras
                      ..clear()
                      ..addAll(options);
                  }),
                ),
              ],
              const SizedBox(height: 24),
              const _ProfessionalSectionHeader(
                title: '5. Schedule',
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
                            label: 'Pickup date',
                            date: _pickupDateTime,
                            onTap: () => _pickDateOnly(isReturn: false),
                            icon: Icons.calendar_today,
                            focusNode: _pickupDateFocusNode,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StyledTimePicker(
                            label: 'Pickup time',
                            time: _pickupTimeOfDay,
                            onTap: () => _pickTimeOnly(isReturn: false),
                            icon: Icons.access_time,
                            focusNode: _pickupTimeFocusNode,
                          ),
                        ),
                      ],
                    ),
                    if (_isRoundTrip) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StyledDatePicker(
                              label: 'Return date',
                              date: _returnDateTime,
                              onTap: () => _pickDateOnly(isReturn: true),
                              icon: Icons.calendar_today,
                              focusNode: _returnDateFocusNode,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StyledTimePicker(
                              label: 'Return time',
                              time: _returnTimeOfDay,
                              onTap: () => _pickTimeOnly(isReturn: true),
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
                title: '6. Trip Notes',
                subtitle: 'Any special instructions for your driver',
              ),
              const SizedBox(height: 12),
              _StyledTextField(
                label: 'Special instructions (optional)',
                controller: _instructionsController,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const _ProfessionalSectionHeader(
                title: '7. Additional Stop',
                subtitle: 'Need an extra stop along the way?',
              ),
              const SizedBox(height: 8),
              _StyledCheckbox(
                title: 'Additional stop on the way',
                value: _hasAdditionalStop,
                onChanged: (value) => _handleAdditionalStopToggle(
                  value ?? false,
                  availableAdditionalStops,
                ),
              ),
              if (_hasAdditionalStop && availableAdditionalStops.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No additional stop options are available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (_hasAdditionalStop &&
                  availableAdditionalStops.isNotEmpty) ...[
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
                  label: 'Describe the stop',
                  controller: _additionalStopDescriptionController,
                  maxLines: 2,
                  validator: (value) {
                    if (_hasAdditionalStop &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Please describe the additional stop';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              const _ProfessionalSectionHeader(
                title: '8. Passenger Information',
                subtitle: 'Who is taking this trip?',
              ),
              const SizedBox(height: 12),
              _BookingForSection(
                bookingFor: _bookingFor,
                onChanged: (value) =>
                    _handleBookingForChanged(value, authProvider),
              ),
              const SizedBox(height: 12),
              _StyledTextField(
                label: 'Passenger full name',
                controller: _passengerNameController,
                validator: NameValidator.validate,
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
              const SizedBox(height: 24),
              const _ProfessionalSectionHeader(
                title: '9. Gratuity',
                subtitle: 'Show appreciation for excellent service',
              ),
              const SizedBox(height: 8),
              if (priceBreakdown != null)
                _GratuitySelector(
                  gratuities: catalog.gratuities,
                  selectedId: _selectedGratuityId,
                  onChanged: (value) =>
                      setState(() => _selectedGratuityId = value),
                  subtotal: priceBreakdown.subtotal,
                  currency: priceBreakdown.currency,
                )
              else
                _GratuitySelector(
                  gratuities: catalog.gratuities,
                  selectedId: _selectedGratuityId,
                  onChanged: (value) =>
                      setState(() => _selectedGratuityId = value),
                  subtotal: 0,
                  currency: 'USD',
                ),
              const SizedBox(height: 24),
              const _ProfessionalSectionHeader(
                title: '10. Payment Method',
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
                cardholderNameHint: NameValidator.format(_passengerNameController.text),
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
                      setSquareTokenizedAtTotal: (t) =>
                          _squareTokenizedAtTotal = t,
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
                title: '11. Confirmation',
                subtitle: 'Review and confirm your booking',
              ),
              if (consentHint != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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
              _StyledCheckbox(
                title:
                    'I confirm the trip details and authorize ODA Black Car Service to process payment for this booking.',
                value: _agreedToTerms,
                onChanged: consentReady
                    ? (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      }
                    : null,
              ),
              if (bookingProvider.successMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          bookingProvider.successMessage!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (bookingProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppErrorBanner(
                    message: bookingProvider.errorMessage!,
                    onRetry: null,
                  ),
                ),
              const SizedBox(height: 12),
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
                      : const Icon(Icons.directions_car_filled_rounded),
                  label: const Text('Confirm reservation'),
                  onPressed: bookingProvider.isSubmitting
                      ? null
                      : () => _submit(context),
                ),
              ),
            ],
          ),
        ),
      ],
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
        .where((stop) => stop.stopType.toLowerCase().contains(keyword))
        .toList();
    return filtered.isNotEmpty ? filtered : stops;
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
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
        _additionalStopDescriptionController.clear();
      }
    });
  }

  Widget _buildRouteOverviewCard(double? straightDistance) {
    final theme = Theme.of(context);
    final routeDistance = _routeDistanceInMiles ?? straightDistance;
    // Match website: always use 2 decimal places for distance
    final distanceLabel = routeDistance != null
        ? '${routeDistance.toStringAsFixed(2)} miles'
        : 'Awaiting route';
    final durationLabel = _routeDurationText ?? 'Pending';
    final manifestLabel = '$_passengers pax • $_suitcases bags';
    final hasRoute = _pickupDetail != null && _dropoffDetail != null;

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
            'Journey snapshot',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasRoute
                ? 'We drew the live Google Maps route so you can quickly verify pick-up & drop-off.'
                : 'Add both locations to preview distance, travel time, and routing.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _RouteStopsTimeline(
            stops: [
              _RouteStop(
                label: 'Pickup',
                value: _pickupController.text.isEmpty
                    ? 'Awaiting selection'
                    : _pickupController.text,
                icon: Icons.radio_button_checked,
              ),
              _RouteStop(
                label: 'Drop-off',
                value: _dropoffController.text.isEmpty
                    ? 'Awaiting selection'
                    : _dropoffController.text,
                icon: Icons.flag_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 260,
              child: _HourlyCharterMap(
                pickup: _pickupDetail,
                dropoff: _dropoffDetail,
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
                icon: Icons.groups_2_outlined,
                label: 'Manifest',
                value: manifestLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _ensureDefaults(CatalogProvider catalog) {
    if (_selectedCarId == null && catalog.cars.isNotEmpty) {
      _selectedCarId = catalog.cars.first.carId;
    }
    // Default to "Will tip in cash" (gratuity with percentage 0)
    if (_selectedGratuityId == null && catalog.gratuities.isNotEmpty) {
      final cashTipGratuity = catalog.gratuities.firstWhere(
        (g) => g.percentage == 0,
        orElse: () => catalog.gratuities.first,
      );
      _selectedGratuityId = cashTipGratuity.gratuityId;
    }
  }

  double? _calculateDistanceInMiles() {
    if (_pickupDetail == null || _dropoffDetail == null) return null;

    if (_pickupDetail!.lat == 0 && _pickupDetail!.lng == 0) return null;
    if (_dropoffDetail!.lat == 0 && _dropoffDetail!.lng == 0) return null;

    final distance = haversineDistanceInMiles(
      startLat: _pickupDetail!.lat,
      startLng: _pickupDetail!.lng,
      endLat: _dropoffDetail!.lat,
      endLng: _dropoffDetail!.lng,
    );

    return distance > 0 ? distance : null;
  }

  Future<void> _fetchRouteDistance() async {
    if (_pickupDetail == null || _dropoffDetail == null) return;

    try {
      final waypoints = _sidePickDetails
          .whereType<PlaceDetail>()
          .map((d) => LatLng(d.lat, d.lng))
          .toList();
      final route = await _directionsService.fetchRoute(
        origin: LatLng(_pickupDetail!.lat, _pickupDetail!.lng),
        destination: LatLng(_dropoffDetail!.lat, _dropoffDetail!.lng),
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

  Future<void> _openRoutePlanner() async {
    final result = await showModalBottomSheet<_RouteSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteMapPickerSheet(
        initialPickup: _pickupDetail,
        initialDropoff: _dropoffDetail,
      ),
    );

    if (!mounted) return;
    if (result != null) {
      if (!_isValidPointToPointPickup(result.pickup)) {
        return;
      }
      setState(() {
        _pickupDetail = result.pickup;
        _dropoffDetail = result.dropoff;
        _pickupController.text = result.pickup.formattedAddress;
        _dropoffController.text = result.dropoff.formattedAddress;
        _routeDistanceInMiles = result.distanceInMiles ?? _routeDistanceInMiles;
        _routeDurationText = result.durationText;
        _routePolyline = null;
      });
      if (_pickupDetail != null && _dropoffDetail != null) {
        _fetchRouteDistance();
      }
    }
  }

  bool _isValidPointToPointPickup(PlaceDetail detail) {
    if (_isUnitedStatesLocation(detail)) {
      return true;
    }
    _showSnackbar('Pickup address must be located in the USA.');
    return false;
  }

  String? _buildPointToPointPricingSubtitle(double? distance) {
    if (distance == null) {
      return _isRoundTrip ? 'Round trip service' : 'One-way service';
    }

    // Match website: always use 2 decimal places
    final roundedDistance = distance.toStringAsFixed(2);
    final segments = <String>[
      '$roundedDistance miles',
      _isRoundTrip ? 'Round trip' : 'One-way',
    ];
    return segments.join(' • ');
  }

  Future<void> _submit(BuildContext context) async {
    final bookingProvider = context.read<BookingProvider>();

    if (!_formKey.currentState!.validate()) return;
    if (_pickupDetail == null || _dropoffDetail == null) {
      _showSnackbar('Select pickup and drop-off locations.');
      return;
    }
    if (_pickupDateTime == null) {
      _showSnackbar('Select a pickup date and time.');
      return;
    }

    // Validate 1-hour advance booking requirement (like React website)
    final minBookingTime = _getMinBookingTimePointToPoint();
    if (_pickupDateTime!.isBefore(minBookingTime)) {
      // Auto-correct to minimum time
      final corrected = _ensureValidPickupTime(
        DateTime(_pickupDateTime!.year, _pickupDateTime!.month,
            _pickupDateTime!.day),
        TimeOfDay(hour: _pickupDateTime!.hour, minute: _pickupDateTime!.minute),
      );
      setState(() {
        _pickupDateTime = corrected;
      });
      CustomSnackbar.showInfo(
        context,
        'Pickup time adjusted to meet 1-hour advance booking requirement.',
      );
      return;
    }

    if (_isRoundTrip && _returnDateTime == null) {
      _showSnackbar('Select a return pickup date and time.');
      return;
    }

    // Validate return time is at least 1 hour after pickup (like React website)
    if (_isRoundTrip && _returnDateTime != null) {
      final minReturnTime = _pickupDateTime!.add(const Duration(hours: 1));
      if (_returnDateTime!.isBefore(minReturnTime)) {
        setState(() {
          _returnDateTime = minReturnTime;
        });
        CustomSnackbar.showInfo(
          context,
          'Return pickup time adjusted to be at least 1 hour after pickup.',
        );
        return;
      }
    }
    if (_selectedCarId == null) {
      _showSnackbar('Choose a vehicle class.');
      return;
    }
    if (_selectedGratuityId == null) {
      _showSnackbar('Choose a gratuity preference.');
      return;
    }

    final calculatedDistance = _calculateDistanceInMiles();
    final distance = _routeDistanceInMiles ?? calculatedDistance;
    if (distance == null || distance <= 0) {
      _showSnackbar(
          'Unable to calculate the trip distance. Please adjust locations.');
      return;
    }

    final squareEnabled = context.read<SquareRuntimeConfig>().squareEnabled;
    final bookingTotal = PricingCalculator.pointToPoint(
      car: _selectedCarId != null
          ? context.read<CatalogProvider>().findCarById(_selectedCarId!)
          : null,
      distanceInMiles: distance,
      gratuity: _findGratuity(
        context.read<CatalogProvider>(),
        _selectedGratuityId,
      ),
      isRoundTrip: _isRoundTrip,
      extraCatalog: context.read<CatalogProvider>().extraOptions,
      selectedExtras: List<SelectedExtraOption>.from(_selectedExtras),
      additionalStop: _findAdditionalStop(
        context.read<CatalogProvider>(),
        _selectedAdditionalStopId,
      ),
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
      } else if (_paymentMethod == PaymentMethodType.newCard) {
        if (_cardDetails == null) {
          _showSnackbar('Enter payment card details to confirm booking.');
          return;
        }
      }
    }

    if (!_agreedToTerms) {
      _showSnackbar('Please confirm the booking details.');
      return;
    }

    final passengerName = NameValidator.format(_passengerNameController.text);
    final passengerEmail = _passengerEmailController.text.trim();
    final passengerPhone = _passengerPhoneController.text.trim();

    if (passengerName.isEmpty ||
        passengerEmail.isEmpty ||
        passengerPhone.isEmpty) {
      _showSnackbar('Passenger information is required.');
      return;
    }
    if (_hasAdditionalStop && _selectedAdditionalStopId == null) {
      _showSnackbar('Select an additional stop option.');
      return;
    }

    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final request = PointToPointBookingRequest(
      tripType: _tripType,
      pickupPhysicalAddress: _pickupDetail!.formattedAddress,
      pickupLongitude: _pickupDetail!.lng,
      pickupLatitude: _pickupDetail!.lat,
      dropoffPhysicalAddress: _dropoffDetail!.formattedAddress,
      dropoffLongitude: _dropoffDetail!.lng,
      dropoffLatitude: _dropoffDetail!.lat,
      distanceInMiles: distance,
      numberOfPassengers: _passengers,
      numberOfSuitcases: _suitcases,
      pickupDateTime: dateFormatter.format(_pickupDateTime!),
      returnPickupDateTime: _returnDateTime != null
          ? dateFormatter.format(_returnDateTime!)
          : null,
      specialInstructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      bookingFor: _bookingFor,
      additionalStopId: _hasAdditionalStop ? _selectedAdditionalStopId : null,
      additionalStopOnTheWayDescription: _hasAdditionalStop &&
              _additionalStopDescriptionController.text.trim().isNotEmpty
          ? _additionalStopDescriptionController.text.trim()
          : null,
      passengerFullName: passengerName,
      passengerEmail: passengerEmail,
      gratuityId: _selectedGratuityId!,
      isGuestBooking: false,
      passengerCellPhone: passengerPhone,
      carId: _selectedCarId!,
      extraOptions: List<SelectedExtraOption>.from(_selectedExtras),
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

    final success = await bookingProvider.submitPointToPointBooking(
      request,
      authenticated: true,
    );

    if (success && mounted) {
      CustomSnackbar.showSuccess(
        context,
        bookingProvider.successMessage ??
            'Your booking request has been submitted.',
      );
      setState(() {
        _selectedExtras.clear();
        _instructionsController.clear();
      });
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

  void _showSnackbar(String message) {
    // Use the CustomSnackbar from the main library
    CustomSnackbar.show(context, message);
  }
}

class _RouteStop {
  final String label;
  final String value;
  final IconData icon;

  _RouteStop({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _RouteStopsTimeline extends StatelessWidget {
  final List<_RouteStop> stops;

  const _RouteStopsTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (int i = 0; i < stops.length; i++) ...[
          if (i > 0)
            Container(
              height: 20,
              width: 2,
              color: const Color(0xFF03930A).withOpacity(0.3),
              margin: const EdgeInsets.only(left: 12),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF03930A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  stops[i].icon,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stops[i].label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stops[i].value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Enhanced Section Header
class _ProfessionalSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _ProfessionalSectionHeader({
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF03930A),
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

// Enhanced Styled Counter
class _StyledCounter extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final IconData icon;

  const _StyledCounter({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF03930A)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF03930A),
              ),
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF03930A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Enhanced Styled Date Picker
class _StyledDatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final IconData icon;
  final FocusNode? focusNode;

  const _StyledDatePicker({
    required this.label,
    this.date,
    required this.onTap,
    required this.icon,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF03930A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date != null
                          ? DateFormat('MMM dd, yyyy').format(date!)
                          : 'Select date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFF03930A)),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Styled Time Picker
class _StyledTimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final IconData icon;
  final FocusNode? focusNode;

  const _StyledTimePicker({
    required this.label,
    this.time,
    required this.onTap,
    required this.icon,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF03930A)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time != null ? time!.format(context) : 'Select time',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFF03930A)),
            ],
          ),
        ),
      ),
    );
  }
}

// Enhanced Styled Text Field
class _StyledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool enabled;

  const _StyledTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF03930A),
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

// Enhanced Styled Checkbox
class _StyledCheckbox extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const _StyledCheckbox({
    required this.title,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      activeColor: const Color(0xFF03930A),
      checkColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// Enhanced Styled Radio
class _StyledRadio<T> extends StatelessWidget {
  final String title;
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;

  const _StyledRadio({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Text(title),
      activeColor: const Color(0xFF03930A),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

// Enhanced Metric Pill
class _StyledMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StyledMetricPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF03930A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF03930A).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF03930A)),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF03930A),
            ),
          ),
        ],
      ),
    );
  }
}
