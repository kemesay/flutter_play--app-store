part of 'package:oda_black_car_service/ui/screens/home/pages/book_ride/book_ride_page.dart';

class _HourlyCharterForm extends StatefulWidget {
  const _HourlyCharterForm({super.key});

  @override
  State<_HourlyCharterForm> createState() => _HourlyCharterFormState();
}

// Utility function to get minimum allowed booking time (1 hour from now)
// Matches React website implementation: minimumPickupLeadTime = currentDateTime.add(1, "hour")
DateTime _getMinBookingTimeHourlyCharter() {
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
DateTime _getMinBookingDateHourlyCharter() {
  final minTime = _getMinBookingTimeHourlyCharter();
  return DateTime(minTime.year, minTime.month, minTime.day);
}

// Check if selected date is the same as minimum date (today)
bool _isPickupDateSameAsMinimumHourlyCharter(DateTime? selectedDate) {
  if (selectedDate == null) return false;
  final minDate = _getMinBookingDateHourlyCharter();
  return selectedDate.year == minDate.year &&
      selectedDate.month == minDate.month &&
      selectedDate.day == minDate.day;
}

// Ensure valid pickup time - auto-corrects if time is too early (like React's ensureValidPickupTime)
DateTime _ensureValidPickupTimeHourlyCharter(
    DateTime? selectedDate, TimeOfDay? selectedTime) {
  final minBookingTime = _getMinBookingTimeHourlyCharter();

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

class _HourlyCharterFormState extends State<_HourlyCharterForm> {
  static const String _allVehiclesLabel = 'All Vehicles';

  final _formKey = GlobalKey<FormState>();
  final _placeService = PlaceService();
  final _directionsService = DirectionsService();
  final _sessionToken = const Uuid().v4();

  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _instructionController = TextEditingController();
  final _itineraryNotesController = TextEditingController();
  late final TextEditingController _passengerNameController;
  late final TextEditingController _passengerEmailController;
  late final TextEditingController _passengerPhoneController;

  // Focus nodes for date/time pickers to control focus behavior
  final _pickupDateFocusNode = FocusNode();
  final _pickupTimeFocusNode = FocusNode();

  PlaceDetail? _pickupDetail;
  PlaceDetail? _dropoffDetail;
  DateTime? _pickupDateTime;
  int _selectedHours = 4;
  HourlyBillingMode _billingMode = HourlyBillingMode.preBooked;
  int _passengers = 1;
  int _suitcases = 0;
  int? _selectedCarId;
  int? _selectedGratuityId;
  final List<SelectedExtraOption> _selectedExtras = [];
  String _bookingFor = 'Myself';
  bool _hasItineraryNotes = false;
  bool _agreedToTerms = false;
  String _vehicleClassFilter = _allVehiclesLabel;
  String _selectedOccasion = 'Wedding';

  double? _routeDistanceInMiles;
  String? _routeDurationText;
  List<LatLng>? _routePolyline;

  PaymentMethodType _paymentMethod = PaymentMethodType.newCard;
  int? _selectedPaymentDetailId;
  String? _selectedSquareCardId;
  CardDetails? _cardDetails;
  SquarePaymentPayload? _squarePayload;
  double? _squareTokenizedAtTotal;

  TimeOfDay? get _pickupTimeOfDay => _pickupDateTime != null
      ? TimeOfDay(hour: _pickupDateTime!.hour, minute: _pickupDateTime!.minute)
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
    _instructionController.dispose();
    _itineraryNotesController.dispose();
    _passengerNameController.dispose();
    _passengerEmailController.dispose();
    _passengerPhoneController.dispose();
    _pickupDateFocusNode.dispose();
    _pickupTimeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

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

    final straightDistance = _pickupDetail != null && _dropoffDetail != null
        ? haversineDistanceInMiles(
            startLat: _pickupDetail!.lat,
            startLng: _pickupDetail!.lng,
            endLat: _dropoffDetail!.lat,
            endLng: _dropoffDetail!.lng,
          )
        : null;

    final selectedCar =
        _selectedCarId != null ? catalog.findCarById(_selectedCarId!) : null;
    final selectedGratuity = _findGratuity(catalog, _selectedGratuityId);
    final priceBreakdown = PricingCalculator.hourlyCharter(
      car: selectedCar,
      selectedHours: _selectedHours,
      gratuity: selectedGratuity,
      extraCatalog: catalog.extraOptions,
      selectedExtras: List<SelectedExtraOption>.from(_selectedExtras),
    );
    final pricingSubtitle =
        'Duration: $_selectedHours hour${_selectedHours == 1 ? '' : 's'}';
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

    final authProvider = context.watch<AuthProvider>();
    final plannerCard = _buildPlannerCard(
      context: context,
      straightDistance: straightDistance,
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProfessionalSectionHeader(
            title: '1. Pickup & drop-off',
            subtitle: 'Enter your journey details',
          ),
          const SizedBox(height: 12),
          _LocationPickerField(
            label: 'Select pickup address',
            controller: _pickupController,
            placeService: _placeService,
            sessionToken: _sessionToken,
            onPlaceSelected: (detail) {
              if (!_validateCaliforniaPickup(detail)) return;
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
          const SizedBox(height: 12),
          _LocationPickerField(
            label: 'Select drop-off address',
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
            title: '2. Trip type & duration',
            subtitle: 'Select your preferred journey',
          ),
          const SizedBox(height: 8),
          Text(
            'Hourly charter • multi-stop friendly',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedHours,
            decoration: const InputDecoration(
              labelText: 'Select hours',
              prefixIcon: Icon(Icons.timelapse_outlined),
            ),
            items: List.generate(
              12,
              (index) => DropdownMenuItem<int>(
                value: index + 4,
                child: Text('${index + 4} hours'),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedHours = value);
              }
            },
          ),
          const SizedBox(height: 16),
          _BillingModeSelector(
            value: _billingMode,
            onChanged: (mode) => setState(() => _billingMode = mode),
          ),
          const SizedBox(height: 16),
          plannerCard,
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '3. Choose vehicle',
            subtitle: 'Select your preferred vehicle',
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
            label: 'Suitcases (0-14)',
            value: _suitcases,
            min: 0,
            max: 14,
            onChanged: (value) => setState(() => _suitcases = value),
            icon: Icons.luggage_outlined,
          ),
          const SizedBox(height: 12),
          _StyledCounter(
            label: 'Passengers (0-14)',
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
              // Calculate Service fee (total) from price breakdown (matches React website)
              // Service fee = total (subtotal + gratuity) like React's totalFee
              final serviceFeeValue = priceBreakdown != null
                  ? _formatCurrency(
                      priceBreakdown.total, priceBreakdown.currency)
                  : '\$0.00';

              final summaryItems = [
                _SummaryItem(
                  label: 'Hours reserved',
                  value: '$_selectedHours h',
                ),
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
                if (straightDistance != null)
                  _SummaryItem(
                    label: 'Distance',
                    // Match website: always use 2 decimal places
                    value: '${straightDistance.toStringAsFixed(2)} miles',
                  ),
                _SummaryItem(label: 'Service fee', value: serviceFeeValue),
              ];
              return _VehicleShowcase(
                cars: filteredCars,
                selectedCarId: _selectedCarId,
                distanceInMiles: straightDistance,
                passengers: _passengers,
                suitcases: _suitcases,
                summaryItems: summaryItems,
                selectedHours: _selectedHours,
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
            title: '4. Pickup time',
            subtitle: 'Select your preferred timing',
          ),
          const SizedBox(height: 12),
          // Wrap date/time section in FocusScope to contain focus naturally
          FocusScope(
            child: Row(
              children: [
                Expanded(
                  child: _StyledDatePicker(
                    label: 'Pickup date',
                    date: _pickupDateTime,
                    onTap: _pickPickupDate,
                    icon: Icons.calendar_today,
                    focusNode: _pickupDateFocusNode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StyledTimePicker(
                    label: 'Pickup time',
                    time: _pickupTimeOfDay,
                    onTap: _pickPickupTime,
                    icon: Icons.access_time,
                    focusNode: _pickupTimeFocusNode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '5. Trip Notes',
            subtitle: 'Any special instructions for your driver',
          ),
          const SizedBox(height: 12),
          _StyledTextField(
            label: 'Special instructions (optional)',
            controller: _instructionController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedOccasion,
            decoration: const InputDecoration(
              labelText: 'Occasion',
              prefixIcon: Icon(Icons.event_outlined),
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'Wedding',
                child: Text('Wedding'),
              ),
              DropdownMenuItem<String>(
                value: 'Tour',
                child: Text('Tour'),
              ),
              DropdownMenuItem<String>(
                value: 'Promotion',
                child: Text('Promotion'),
              ),
              DropdownMenuItem<String>(
                value: 'Graduation',
                child: Text('Graduation'),
              ),
              DropdownMenuItem<String>(
                value: 'Concert',
                child: Text('Concert'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedOccasion = value);
              }
            },
          ),
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '6. Passenger Information',
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
          const SizedBox(height: 24),
          const _ProfessionalSectionHeader(
            title: '7. Gratuity',
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
            title: '8. Payment Method',
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
            title: '9. Confirmation',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bookingProvider.successMessage!,
                      style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
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
                  : const Icon(Icons.schedule_rounded),
              label: const Text('Confirm hourly charter'),
              onPressed:
                  bookingProvider.isSubmitting ? null : () => _submit(context),
            ),
          ),
        ],
      ),
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

  Widget _buildPlannerCard({
    required BuildContext context,
    required double? straightDistance,
  }) {
    final theme = Theme.of(context);
    final routeDistance = _routeDistanceInMiles ?? straightDistance;
    // Match website: always use 2 decimal places for distance
    final distanceLabel = routeDistance != null
        ? '${routeDistance.toStringAsFixed(2)} miles'
        : 'Awaiting route';
    final durationLabel = _routeDurationText ?? 'Pending';
    final hoursLabel =
        '$_selectedHours hour${_selectedHours == 1 ? '' : 's'} reserved';

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
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                      'Plan multi-stop itineraries with a dedicated chauffeur.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Pickup & drop-off details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
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
          Text(
            'Live route preview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 260,
              child: _HourlyCharterMap(
                pickup: _pickupDetail,
                dropoff: _dropoffDetail,
                routePolyline: _routePolyline,
                routeDistance: _routeDistanceInMiles,
                routeDuration: _routeDurationText,
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
                label: 'Estimated distance',
                value: distanceLabel,
              ),
              _HourlyMetricPill(
                icon: Icons.schedule_outlined,
                label: 'Travel duration',
                value: durationLabel,
              ),
              _HourlyMetricPill(
                icon: Icons.timelapse,
                label: 'Reservation length',
                value: hoursLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickPickupDate() async {
    // Save scroll position before opening picker
    _BookRidePageState.saveScrollPositionStatic();
    // Unfocus any current focus to prevent auto-jump after picker closes
    FocusScope.of(context).unfocus();

    final minBookingTime = _getMinBookingTimeHourlyCharter();
    final minBookingDate = _getMinBookingDateHourlyCharter();
    final initialDate = _pickupDateTime ?? minBookingTime;
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
          _pickupDateTime ?? DateTime(date.year, date.month, date.day, 10, 0);

      _pickupDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        baseDateTime.hour,
        baseDateTime.minute,
      );

      // If same day and time is too early, auto-correct to minimum time
      final isSameDay = _isPickupDateSameAsMinimumHourlyCharter(date);
      if (isSameDay) {
        final currentTime = TimeOfDay(
            hour: _pickupDateTime!.hour, minute: _pickupDateTime!.minute);
        final corrected =
            _ensureValidPickupTimeHourlyCharter(date, currentTime);
        if (corrected != _pickupDateTime) {
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

  Future<void> _pickPickupTime() async {
    // Save scroll position before opening picker
    _BookRidePageState.saveScrollPositionStatic();
    // Unfocus any current focus to prevent auto-jump after picker closes
    FocusScope.of(context).unfocus();

    final minBookingTime = _getMinBookingTimeHourlyCharter();

    // If no date is selected, we can't pick a time
    if (_pickupDateTime == null) {
      CustomSnackbar.show(context, 'Please select a date first.');
      return;
    }

    final initialTime = TimeOfDay(
      hour: _pickupDateTime!.hour,
      minute: _pickupDateTime!.minute,
    );

    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time == null || !mounted) {
      // Keep focus removed if user cancels
      FocusScope.of(context).unfocus();
      return;
    }

    // Use ensureValidPickupTime to auto-correct if needed (like React)
    final selectedDate = DateTime(
        _pickupDateTime!.year, _pickupDateTime!.month, _pickupDateTime!.day);
    final corrected = _ensureValidPickupTimeHourlyCharter(selectedDate, time);

    // Show message if time was auto-corrected
    final selectedDateTime = DateTime(
      _pickupDateTime!.year,
      _pickupDateTime!.month,
      _pickupDateTime!.day,
      time.hour,
      time.minute,
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

  Future<void> _fetchRouteDistance() async {
    if (_pickupDetail == null || _dropoffDetail == null) return;

    try {
      final route = await _directionsService.fetchRoute(
        origin: LatLng(_pickupDetail!.lat, _pickupDetail!.lng),
        destination: LatLng(_dropoffDetail!.lat, _dropoffDetail!.lng),
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

  bool _validateCaliforniaPickup(PlaceDetail detail) {
    if (_isAllowedPickupState(detail)) {
      return true;
    }
    _showSnackbar(
        'Pickup location must be within California or Washington, USA.');
    return false;
  }

  GratuityModel? _findGratuity(CatalogProvider catalog, int? gratuityId) {
    if (gratuityId == null) return null;
    for (final gratuity in catalog.gratuities) {
      if (gratuity.gratuityId == gratuityId) return gratuity;
    }
    return null;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickupDetail == null || _dropoffDetail == null) {
      _showSnackbar('Select pickup and drop-off locations.');
      return;
    }
    if (_pickupDateTime == null) {
      _showSnackbar('Select pickup date/time.');
      return;
    }

    // Validate 1-hour advance booking requirement (like React website)
    final minBookingTime = _getMinBookingTimeHourlyCharter();
    if (_pickupDateTime!.isBefore(minBookingTime)) {
      // Auto-correct to minimum time
      final selectedDate = DateTime(
          _pickupDateTime!.year, _pickupDateTime!.month, _pickupDateTime!.day);
      final selectedTime = TimeOfDay(
          hour: _pickupDateTime!.hour, minute: _pickupDateTime!.minute);
      final corrected =
          _ensureValidPickupTimeHourlyCharter(selectedDate, selectedTime);
      setState(() {
        _pickupDateTime = corrected;
      });
      CustomSnackbar.showInfo(
        context,
        'Pickup time adjusted to meet 1-hour advance booking requirement.',
      );
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
    final bookingTotal = PricingCalculator.hourlyCharter(
      car: _selectedCarId != null ? catalog.findCarById(_selectedCarId!) : null,
      selectedHours: _selectedHours,
      gratuity: _findGratuity(catalog, _selectedGratuityId),
      extraCatalog: catalog.extraOptions,
      selectedExtras: List<SelectedExtraOption>.from(_selectedExtras),
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
    if (_hasItineraryNotes && _itineraryNotesController.text.trim().isEmpty) {
      _showSnackbar('Describe the additional stops.');
      return;
    }
    if (!_agreedToTerms) {
      _showSnackbar('Please confirm the booking details.');
      return;
    }

    final passengerName = _passengerNameController.text.trim();
    final passengerEmail = _passengerEmailController.text.trim();
    final passengerPhone = _passengerPhoneController.text.trim();

    if (passengerName.isEmpty ||
        passengerEmail.isEmpty ||
        passengerPhone.isEmpty) {
      _showSnackbar('Passenger information is required.');
      return;
    }

    final bookingProvider = context.read<BookingProvider>();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final itineraryNotes =
        _hasItineraryNotes ? _itineraryNotesController.text.trim() : '';
    final instructions = [
      _instructionController.text.trim(),
      itineraryNotes.isEmpty ? null : 'Additional stops: $itineraryNotes',
    ].whereType<String>().where((value) => value.isNotEmpty).toList();

    final request = HourlyCharterBookingRequest(
      pickupPhysicalAddress: _pickupDetail!.formattedAddress,
      pickupLongitude: _pickupDetail!.lng,
      pickupLatitude: _pickupDetail!.lat,
      dropoffPhysicalAddress: _dropoffDetail!.formattedAddress,
      dropoffLongitude: _dropoffDetail!.lng,
      dropoffLatitude: _dropoffDetail!.lat,
      pickupDateTime: dateFormatter.format(_pickupDateTime!),
      selectedHours: _selectedHours,
      billingMode: _billingMode,
      occasion: _selectedOccasion,
      specialInstructions:
          instructions.isEmpty ? null : instructions.join('\n\n'),
      isGuestBooking: false,
      bookingFor: _bookingFor,
      passengerFullName: passengerName,
      paymentMethod: _paymentMethod,
      passengerCellPhone: passengerPhone,
      passengerEmail: passengerEmail,
      numberOfPassengers: _passengers,
      numberOfSuitcases: _suitcases,
      gratuityId: _selectedGratuityId!,
      carId: _selectedCarId!,
      extraOptions: _selectedExtras,
      paymentDetailId: _selectedPaymentDetailId,
      cardDetails:
          _paymentMethod == PaymentMethodType.newCard ? _cardDetails : null,
      square: _paymentMethod == PaymentMethodType.squareNewCard
          ? _squarePayload
          : null,
      squareCardId: _paymentMethod == PaymentMethodType.squareSavedCard
          ? _selectedSquareCardId
          : null,
    );

    final success = await bookingProvider.submitHourlyCharterBooking(
      request,
      authenticated: true,
    );
    if (success && mounted) {
      CustomSnackbar.showSuccess(
        context,
        bookingProvider.successMessage ?? 'Hourly charter request submitted.',
      );
      bookingProvider.clearMessages();
      _BookRidePageState.scrollToTopStatic();
    } else if (!success && mounted) {
      _showSnackbar(
          bookingProvider.errorMessage ?? 'Unable to submit reservation.');
    }
  }

  void _showSnackbar(String message) {
    // Use the CustomSnackbar from the main library
    CustomSnackbar.show(context, message);
  }
}

class _HourlyMetricPill extends StatelessWidget {
  const _HourlyMetricPill({
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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
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

// ─── Billing Mode Toggle Widget ──────────────────────────────────────────────

class _BillingModeSelector extends StatelessWidget {
  const _BillingModeSelector({
    required this.value,
    required this.onChanged,
  });

  final HourlyBillingMode value;
  final ValueChanged<HourlyBillingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Billing Mode',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  'Fixed Booking: you pay for exactly the hours you booked.\n'
                  'Live Meter: card is pre-authorized for booked hours + 2 hr buffer. '
                  'Your booked hours are a minimum charge — extra time is billed '
                  'at the same normal hourly rate when the driver ends the trip.',
              child: Icon(
                Icons.info_outline,
                size: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.12),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: HourlyBillingMode.values.map((mode) {
              final active = value == mode;
              final isLive = mode == HourlyBillingMode.live;
              final activeColor =
                  isLive ? const Color(0xFFF59E0B) : const Color(0xFF03930A);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    decoration: BoxDecoration(
                      color: active
                          ? (isLive
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF0FDF4))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active
                            ? activeColor.withOpacity(0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: activeColor.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLive
                              ? Icons.speed_outlined
                              : Icons.lock_clock_outlined,
                          size: 18,
                          color: active
                              ? activeColor
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLive ? 'Live Meter' : 'Fixed Booking',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? activeColor
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isLive ? 'Pay actual time' : 'Pay booked hours',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: active
                                      ? activeColor.withOpacity(0.7)
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.3),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (value == HourlyBillingMode.live) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.speed_outlined,
                    size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Card pre-authorized for booked hours + 2 hr buffer. '
                    'Actual charge set when driver ends the trip. '
                    'Booked hours are a minimum charge; extra time is billed '
                    'at the same normal hourly rate.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
