import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/json_parsing.dart';
import '../../../../../core/utils/payment_status_map.dart';
import '../../../../../data/models/booking_history_item.dart';
import '../../../../../data/services/booking_service.dart';
import '../../../../../ui/theme/app_tokens.dart';
import '../../../../../ui/widgets/app_card.dart';
import '../../../../../ui/widgets/app_section_header.dart';
import '../../../../../ui/widgets/field_widget.dart';
import '../update_booking/update_booking_page.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.booking,
    this.showDetailsButton = true,
    this.allowEdit = false,
  });

  final BookingHistoryItem booking;
  final bool showDetailsButton;
  final bool allowEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paymentColor = _statusColor(booking.paymentStatus, colorScheme);
    final bookingColor = _statusColor(booking.bookingStatus, colorScheme);
    final paymentLabel = formatPaymentStatusLabel(booking.paymentStatus);
    final paymentHint = paymentStatusHint(booking.paymentStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03930A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF03930A).withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    booking.displayTitle,
                    style: const TextStyle(
                      color: Color(0xFF03930A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (booking.type == BookingType.hourlyCharter &&
                    booking.rawData['billingMode'] == 'LIVE')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF60A5FA).withOpacity(0.5)),
                    ),
                    child: const Text(
                      '⚡ Live',
                      style: TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (booking.type == BookingType.hourlyCharter &&
                    booking.rawData['liveExtensionStartedAt'] != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC4B5FD).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFC4B5FD).withOpacity(0.5)),
                    ),
                    child: const Text(
                      '⚡ Extended',
                      style: TextStyle(
                          color: Color(0xFFC4B5FD),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const Spacer(),
                Text(
                  booking.referenceLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.pickupAddress ?? 'Pickup address unavailable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      if (booking.dropoffAddress != null)
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                booking.dropoffAddress!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Match website: <Field label="pickup Date Time" value={formatDateToPacific(pickupDateTime)} />
            Field(
              label: 'Pickup Date Time',
              value: booking.pickupDateTime,
              direction: Axis.horizontal,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 350;
                if (isCompact) {
                  // Stack vertically on very small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusChip(
                            icon: Icons.payments,
                            label: paymentLabel,
                            color: paymentColor,
                          ),
                          _StatusChip(
                            icon: Icons.assignment_turned_in,
                            label: booking.bookingStatus,
                            color: bookingColor,
                          ),
                        ],
                      ),
                      if (booking.totalFee != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '\$${booking.totalFee!.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                      if (paymentHint != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          paymentHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                      if (showDetailsButton) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showBookingDetails(context, booking),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('View Details'),
                          ),
                        ),
                      ],
                    ],
                  );
                } else {
                  // Horizontal layout for larger screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _StatusChip(
                                  icon: Icons.payments,
                                  label: paymentLabel,
                                  color: paymentColor,
                                ),
                                _StatusChip(
                                  icon: Icons.assignment_turned_in,
                                  label: booking.bookingStatus,
                                  color: bookingColor,
                                ),
                              ],
                            ),
                          ),
                          if (booking.totalFee != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '\$${booking.totalFee!.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (paymentHint != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          paymentHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                      if (showDetailsButton) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showBookingDetails(context, booking),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('View Details'),
                          ),
                        ),
                      ],
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingHistoryItem booking) {
    showDialog<void>(
      context: context,
      builder: (context) => BookingDetailsDialog(
        booking: booking,
        allowEdit: allowEdit,
      ),
    );
  }

  _StatusColor _statusColor(String status, ColorScheme colorScheme) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
        return _StatusColor(
            colorScheme.secondaryContainer, colorScheme.onSecondaryContainer);
      case 'AUTHORIZED':
        return const _StatusColor(Color(0xFFFFF3E0), Color(0xFFE65100));
      case 'PENDING_APPROVAL':
      case 'AWAITING_PAYMENT':
        return _StatusColor(
            colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer);
      case 'CANCELLED':
      case 'NOT_PAID':
      case 'REJECTED':
      case 'FAILED':
        return _StatusColor(
            colorScheme.errorContainer, colorScheme.onErrorContainer);
      case 'REFUNDED':
        return _StatusColor(
            colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant);
      default:
        return _StatusColor(
            colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant);
    }
  }
}

class _StatusColor {
  const _StatusColor(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final _StatusColor color;

  @override
  Widget build(BuildContext context) {
    // Truncate long status labels
    final displayLabel =
        label.length > 15 ? '${label.substring(0, 12)}...' : label;

    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(
        displayLabel,
        style: const TextStyle(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: color.background,
      labelStyle: TextStyle(color: color.foreground),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ---------------------------------------------------------------------------
// BookingDetailsDialog — StatefulWidget with live status polling
// ---------------------------------------------------------------------------

class BookingDetailsDialog extends StatefulWidget {
  const BookingDetailsDialog({
    super.key,
    required this.booking,
    this.allowEdit = false,
  });

  final BookingHistoryItem booking;
  final bool allowEdit;

  @override
  State<BookingDetailsDialog> createState() => _BookingDetailsDialogState();
}

class _BookingDetailsDialogState extends State<BookingDetailsDialog> {
  static const _brandGreen = Color(0xFF03930A);

  Map<String, dynamic>? _liveStatus;
  Timer? _liveTimer;

  bool get _canEdit {
    if (!widget.allowEdit) return false;
    final status = widget.booking.bookingStatus.toUpperCase();
    return status != 'COMPLETED' &&
        status != 'CANCELLED' &&
        status != 'REJECTED';
  }

  bool get _shouldPollLiveStatus {
    final rawData = widget.booking.rawData;
    return widget.booking.type == BookingType.hourlyCharter &&
        rawData['bookingStatus'] == 'EN_ROUTE';
  }

  @override
  void initState() {
    super.initState();
    if (_shouldPollLiveStatus) {
      _fetchLiveStatus();
      _liveTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _fetchLiveStatus(),
      );
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveStatus() async {
    final rawData = widget.booking.rawData;
    final id = rawData['hourlyCharterBookId'];
    if (id == null) return;
    try {
      final status = await BookingService().getHourlyLiveStatus(id as int);
      if (mounted) {
        setState(() {
          _liveStatus = status;
        });
      }
    } catch (_) {
      // Silently ignore errors; the panel will retain its previous state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawData = widget.booking.rawData;
    final bookingType = widget.booking.type;

    final bool showLivePanel = bookingType == BookingType.hourlyCharter &&
        (rawData['bookingStatus'] == 'EN_ROUTE' || _liveStatus != null);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Booking Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      'Booking Information',
                      [
                        _buildDetailRow('Confirmation Number',
                            rawData['confirmationNumber']?.toString() ?? 'N/A'),
                        _buildDetailRow('Booking ID', _getBookingId(rawData)),
                        _buildDetailRow('Booking Status',
                            rawData['bookingStatus']?.toString() ?? 'N/A'),
                        _buildDetailRow(
                            'Payment Status',
                            formatPaymentStatusLabel(
                                rawData['paymentStatus']?.toString() ?? 'N/A')),
                        if (paymentStatusHint(
                                rawData['paymentStatus']?.toString()) !=
                            null)
                          _buildDetailRow(
                            'Payment note',
                            paymentStatusHint(
                                rawData['paymentStatus']?.toString())!,
                          ),
                        _buildDetailRow(
                            'Payment Method',
                            formatPaymentMethodLabel(
                                rawData['paymentMethod']?.toString() ?? 'N/A')),
                        if (rawData['tripType'] != null)
                          _buildDetailRow('Trip Type',
                              rawData['tripType']?.toString() ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Passenger Information',
                      [
                        _buildDetailRow('Full Name',
                            rawData['passengerFullName']?.toString() ?? 'N/A'),
                        _buildDetailRow('Email',
                            rawData['passengerEmail']?.toString() ?? 'N/A'),
                        _buildDetailRow('Phone',
                            rawData['passengerCellPhone']?.toString() ?? 'N/A'),
                        _buildDetailRow('Booking For',
                            rawData['bookingFor']?.toString() ?? 'N/A'),
                        _buildDetailRow('Is Guest Booking',
                            rawData['isGuestBooking']?.toString() ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Trip Details',
                      [
                        if (rawData['pickupPhysicalAddress'] != null)
                          _buildDetailRow(
                              'Pickup Address',
                              rawData['pickupPhysicalAddress']?.toString() ??
                                  'N/A'),
                        if (rawData['dropoffPhysicalAddress'] != null)
                          _buildDetailRow(
                              'Drop-off Address',
                              rawData['dropoffPhysicalAddress']?.toString() ??
                                  'N/A'),
                        if (rawData['accommodationAddress'] != null)
                          _buildDetailRow(
                              'Accommodation',
                              rawData['accommodationAddress']?.toString() ??
                                  'N/A'),
                        if (rawData['pickupDateTime'] != null)
                          _buildDetailRow('Pickup Date/Time',
                              _formatDateTime(rawData['pickupDateTime'])),
                        if (rawData['returnPickupDateTime'] != null)
                          _buildDetailRow('Return Pickup Date/Time',
                              _formatDateTime(rawData['returnPickupDateTime'])),
                        if (rawData['selectedHours'] != null)
                          _buildDetailRow('Selected Hours',
                              rawData['selectedHours']?.toString() ?? 'N/A'),
                        if (rawData['occasion'] != null)
                          _buildDetailRow('Occasion',
                              rawData['occasion']?.toString() ?? 'N/A'),
                        if (rawData['distanceInMiles'] != null)
                          _buildDetailRow('Distance (Miles)',
                              rawData['distanceInMiles']?.toString() ?? 'N/A'),
                        if (rawData['numberOfPassengers'] != null)
                          _buildDetailRow(
                              'Number of Passengers',
                              rawData['numberOfPassengers']?.toString() ??
                                  'N/A'),
                        if (rawData['numberOfSuitcases'] != null)
                          _buildDetailRow(
                              'Number of Suitcases',
                              rawData['numberOfSuitcases']?.toString() ??
                                  'N/A'),
                        if (rawData['specialInstructions'] != null)
                          _buildDetailRow(
                              'Special Instructions',
                              rawData['specialInstructions']?.toString() ??
                                  'N/A'),
                        if (rawData['additionalStopOnTheWayDescription'] !=
                            null)
                          _buildDetailRow(
                              'Additional Stop Description',
                              rawData['additionalStopOnTheWayDescription']
                                      ?.toString() ??
                                  'N/A'),
                      ],
                    ),
                    // Airport Information (for airport bookings)
                    if (bookingType == BookingType.airport) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        'Airport Information',
                        [
                          if (rawData['airportLocationAddress'] != null)
                            _buildDetailRow(
                                'Airport / Terminal',
                                rawData['airportLocationAddress']?.toString() ??
                                    'N/A'),
                          if (rawData['airline'] != null)
                            _buildDetailRow('Airline',
                                rawData['airline']?.toString() ?? 'N/A'),
                          if (rawData['arrivalFlightNumber'] != null)
                            _buildDetailRow(
                                'Arrival Flight Number',
                                rawData['arrivalFlightNumber']?.toString() ??
                                    'N/A'),
                          if (rawData['returnAirline'] != null)
                            _buildDetailRow('Return Airline',
                                rawData['returnAirline']?.toString() ?? 'N/A'),
                          if (rawData['returnFlightNumber'] != null)
                            _buildDetailRow(
                                'Return Flight Number',
                                rawData['returnFlightNumber']?.toString() ??
                                    'N/A'),
                        ],
                      ),
                    ],

                    // Additional Stop - for point-to-point and airport bookings
                    if (rawData['AdditionalStopOnTheWay'] != null &&
                        rawData['AdditionalStopOnTheWay'] is Map) ...[
                      const SizedBox(height: 20),
                      _buildSection(
                        context,
                        'Additional Stop',
                        [
                          _buildDetailRow(
                              'Stop ID',
                              (rawData['AdditionalStopOnTheWay'] as Map<String,
                                          dynamic>?)?['additionalStopId']
                                      ?.toString() ??
                                  'N/A'),
                          _buildDetailRow(
                              'Stop Type',
                              (rawData['AdditionalStopOnTheWay']
                                          as Map<String, dynamic>?)?['stopType']
                                      ?.toString() ??
                                  'N/A'),
                          _buildDetailRow('Stop Price',
                              '\$${(rawData['AdditionalStopOnTheWay'] as Map<String, dynamic>?)?['additionalStopPrice']?.toString() ?? '0.00'}'),
                          _buildDetailRow(
                              'Currency',
                              (rawData['AdditionalStopOnTheWay']
                                          as Map<String, dynamic>?)?['currency']
                                      ?.toString() ??
                                  'N/A'),
                        ],
                      ),
                    ],

                    // Live Trip Status panel — hourly EN_ROUTE bookings only
                    if (showLivePanel) ...[
                      const SizedBox(height: 20),
                      _buildLiveTripStatusSection(context, rawData),
                    ],

                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Pricing',
                      [
                        _buildDetailRow('Total Trip Fee',
                            '\$${rawData['totalTripFeeInDollars']?.toString() ?? '0.00'}'),
                        _buildDetailRow('Promo Discount',
                            '\$${rawData['promoDiscountAmountInDollars']?.toString() ?? '0.00'}'),
                        _buildDetailRow('Manual Discount',
                            '\$${rawData['discountAmountInDollars']?.toString() ?? '0.00'}'),
                        _buildDetailRow('Has Discount Applied',
                            rawData['hasDiscountApplied']?.toString() ?? 'N/A'),
                        if (rawData['billingMode'] != null)
                          _buildDetailRow(
                              'Billing Mode',
                              rawData['billingMode'] == 'LIVE'
                                  ? 'Live Meter'
                                  : rawData['billingMode'] == 'PRE_BOOKED'
                                      ? 'Fixed Rate'
                                      : rawData['billingMode'].toString()),
                        if (rawData['convertedToLiveAt'] != null)
                          _buildDetailRow('Converted At Start', 'Yes'),
                        if (rawData['liveExtensionBaseFare'] != null)
                          _buildDetailRow('Fixed Base Fare',
                              '\$${rawData['liveExtensionBaseFare']}'),
                        if (asDouble(rawData['liveExtensionFareInDollars']) > 0)
                          _buildDetailRow('Live Extension Charge',
                              '+\$${rawData['liveExtensionFareInDollars']}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_canEdit)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandGreen,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) =>
                                UpdateBookingPage(booking: widget.booking),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Update booking'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Live Trip Status section
  // ---------------------------------------------------------------------------

  Widget _buildLiveTripStatusSection(
      BuildContext context, Map<String, dynamic> rawData) {
    final mode = _liveStatus?['mode'] as String?;
    final billingMode = rawData['billingMode'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Trip Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a0a2e), Color(0xFF0d1628)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _liveStatus == null
              ? _buildLiveLoadingState()
              : _buildLiveContent(context, rawData, mode, billingMode),
        ),
      ],
    );
  }

  Widget _buildLiveLoadingState() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF60A5FA),
          ),
        ),
        SizedBox(width: 12),
        Text(
          'Fetching live status...',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLiveContent(
    BuildContext context,
    Map<String, dynamic> rawData,
    String? mode,
    String? billingMode,
  ) {
    final elapsedFormatted = _liveStatus!['elapsedFormatted'] as String? ??
        _computeElapsed(_liveStatus!['elapsedMinutes']);
    final runningFareNum = asNum(_liveStatus!['runningFare']);
    final runningFareStr = runningFareNum != null
        ? '\$${runningFareNum.toStringAsFixed(2)}'
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode chip row
        Row(
          children: [
            _buildModeBadge(mode, billingMode),
          ],
        ),
        const SizedBox(height: 12),

        // Elapsed time
        _buildLiveRow(
          icon: Icons.timer_outlined,
          label: 'Elapsed Time',
          value: elapsedFormatted,
          valueColor: const Color(0xFF93C5FD),
        ),

        // Running fare
        _buildLiveRow(
          icon: Icons.attach_money,
          label: 'Running Fare',
          value: runningFareStr,
          valueColor: const Color(0xFF4ADE80),
        ),

        // Extended mode: base fare + extension fare
        if (mode == 'EXTENDED') ...[
          const SizedBox(height: 4),
          _buildLiveRow(
            icon: Icons.lock_outline,
            label: 'Locked Base Fare',
            value: asNum(_liveStatus!['baseFare']) != null
                ? '\$${asNum(_liveStatus!['baseFare'])!.toStringAsFixed(2)}'
                : 'N/A',
            valueColor: const Color(0xFFC4B5FD),
          ),
          _buildLiveRow(
            icon: Icons.bolt,
            label: 'Extension Fare',
            value: asNum(_liveStatus!['extensionFare']) != null
                ? '+\$${asNum(_liveStatus!['extensionFare'])!.toStringAsFixed(2)}'
                : 'N/A',
            valueColor: const Color(0xFFF9A8D4),
          ),
        ],
      ],
    );
  }

  Widget _buildModeBadge(String? mode, String? billingMode) {
    if (mode == 'EXTENDED') {
      return _liveBadge(
          '⚡ Extended', const Color(0xFFA855F7), const Color(0xFFA855F7));
    }
    if (mode == 'CONVERTED') {
      return _liveBadge(
          '↔ Converted', const Color(0xFF3B82F6), const Color(0xFF3B82F6));
    }
    if (mode == 'LIVE') {
      return _liveBadge(
          'Live Meter', const Color(0xFF22C55E), const Color(0xFF22C55E));
    }
    // Fallback: show billing mode from rawData
    if (billingMode == 'LIVE') {
      return _liveBadge(
          'Live Meter', const Color(0xFF22C55E), const Color(0xFF22C55E));
    }
    if (billingMode != null) {
      return _liveBadge(
          billingMode, const Color(0xFF94A3B8), const Color(0xFF94A3B8));
    }
    return const SizedBox.shrink();
  }

  Widget _liveBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bg.withOpacity(0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLiveRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = const Color(0xFFE2E8F0),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _computeElapsed(dynamic minutes) {
    final mins = asNum(minutes)?.toInt();
    if (mins == null) return 'N/A';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  // ---------------------------------------------------------------------------
  // Shared helper methods
  // ---------------------------------------------------------------------------

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _getBookingId(Map<String, dynamic> rawData) {
    if (rawData['pointToPointBookId'] != null) {
      return rawData['pointToPointBookId'].toString();
    }
    if (rawData['airportBookId'] != null) {
      return rawData['airportBookId'].toString();
    }
    if (rawData['hourlyCharterBookId'] != null) {
      return rawData['hourlyCharterBookId'].toString();
    }
    return 'N/A';
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      DateTime dt;
      if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return dateTime.toString();
      }
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt.toLocal());
    } catch (e) {
      return dateTime.toString();
    }
  }

  // ignore: unused_element
  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  // Helper method to check if a nested object exists and is a valid Map
  // ignore: unused_element
  bool _hasNestedObject(Map<String, dynamic> rawData, String key) {
    final obj = rawData[key];
    return obj != null && obj is Map<String, dynamic> && obj.isNotEmpty;
  }

  // Helper method to safely get nested value - directly access the API structure
  // ignore: unused_element
  String? _getNestedValue(
    Map<String, dynamic> rawData,
    String parentKey,
    String childKey,
  ) {
    try {
      // Direct access to parent object (e.g., "Car", "Gratuity", "PaymentDetail")
      final parent = rawData[parentKey];
      if (parent == null) return null;

      // Direct access - parent should be Map<String, dynamic> from API
      if (parent is Map<String, dynamic>) {
        final value = parent[childKey];
        if (value == null) return null;
        // Convert to string, handling different types
        if (value is String) return value;
        if (value is num) return value.toString();
        if (value is bool) return value.toString();
        return value.toString();
      }

      // Fallback: try to convert if it's a different Map type
      if (parent is Map) {
        final parentMap = Map<String, dynamic>.from(parent);
        final value = parentMap[childKey];
        if (value == null) return null;
        if (value is String) return value;
        if (value is num) return value.toString();
        if (value is bool) return value.toString();
        return value.toString();
      }

      return null;
    } catch (e) {
      // If any error occurs, return null
      return null;
    }
  }

  // Helper method to check if ExtraOptions exist and have items
  // ignore: unused_element
  bool _hasExtraOptions(Map<String, dynamic> rawData) {
    final options = rawData['ExtraOptions'];
    return options != null && options is List && options.isNotEmpty;
  }

  // Helper method to get ExtraOptions list
  // ignore: unused_element
  List<dynamic> _getExtraOptions(Map<String, dynamic> rawData) {
    final options = rawData['ExtraOptions'];
    if (options is List) {
      return options;
    }
    return [];
  }

  // Helper method to get quantity from extra option
  // ignore: unused_element
  String _getExtraOptionQuantity(Map<String, dynamic> option) {
    // Check all possible quantity locations
    final airportQty = option['AirportBookExtraOption']?['quantity'];
    final pointToPointQty = option['PointToPointBookExtraOption']?['quantity'];
    final hourlyQty = option['HourlyCharterBookExtraOption']?['quantity'];

    final quantity = airportQty ?? pointToPointQty ?? hourlyQty;
    return quantity?.toString() ?? '0';
  }
}
