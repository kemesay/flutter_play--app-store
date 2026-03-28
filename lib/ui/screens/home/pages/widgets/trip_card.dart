import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../data/models/booking_history_item.dart';
import '../../../../../ui/widgets/field_widget.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.booking,
    this.showDetailsButton = true,
  });

  final BookingHistoryItem booking;
  final bool showDetailsButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final paymentColor = _statusColor(booking.paymentStatus, colorScheme);
    final bookingColor = _statusColor(booking.bookingStatus, colorScheme);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.displayTitle,
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
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
                            label: booking.paymentStatus,
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
                                  label: booking.paymentStatus,
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
    showDialog(
      context: context,
      builder: (context) => BookingDetailsDialog(booking: booking),
    );
  }

  _StatusColor _statusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'PAID':
      case 'COMPLETED':
        return _StatusColor(
            colorScheme.secondaryContainer, colorScheme.onSecondaryContainer);
      case 'PENDING_APPROVAL':
      case 'AWAITING_PAYMENT':
        return _StatusColor(
            colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer);
      case 'CANCELLED':
      case 'NOT_PAID':
      case 'REJECTED':
        return _StatusColor(
            colorScheme.errorContainer, colorScheme.onErrorContainer);
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

class BookingDetailsDialog extends StatelessWidget {
  const BookingDetailsDialog({super.key, required this.booking});

  final BookingHistoryItem booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawData = booking.rawData;
    final bookingType = booking.type;

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
                        _buildDetailRow('Payment Status',
                            rawData['paymentStatus']?.toString() ?? 'N/A'),
                        _buildDetailRow('Payment Method',
                            rawData['paymentMethod']?.toString() ?? 'N/A'),
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
                   
                    const SizedBox(height: 20),
                    _buildSection(
                      context,
                      'Pricing',
                      [
                        _buildDetailRow('Total Trip Fee',
                            '\$${rawData['totalTripFeeInDollars']?.toString() ?? '0.00'}'),
                        _buildDetailRow('Discount Amount',
                            '\$${rawData['discountAmountInDollars']?.toString() ?? '0.00'}'),
                        _buildDetailRow('Has Discount Applied',
                            rawData['hasDiscountApplied']?.toString() ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
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

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  // Helper method to check if a nested object exists and is a valid Map
  bool _hasNestedObject(Map<String, dynamic> rawData, String key) {
    final obj = rawData[key];
    return obj != null && obj is Map<String, dynamic> && obj.isNotEmpty;
  }

  // Helper method to safely get nested value - directly access the API structure
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
  bool _hasExtraOptions(Map<String, dynamic> rawData) {
    final options = rawData['ExtraOptions'];
    return options != null && options is List && options.isNotEmpty;
  }

  // Helper method to get ExtraOptions list
  List<dynamic> _getExtraOptions(Map<String, dynamic> rawData) {
    final options = rawData['ExtraOptions'];
    if (options is List) {
      return options;
    }
    return [];
  }

  // Helper method to get quantity from extra option
  String _getExtraOptionQuantity(Map<String, dynamic> option) {
    // Check all possible quantity locations
    final airportQty = option['AirportBookExtraOption']?['quantity'];
    final pointToPointQty = option['PointToPointBookExtraOption']?['quantity'];
    final hourlyQty = option['HourlyCharterBookExtraOption']?['quantity'];

    final quantity = airportQty ?? pointToPointQty ?? hourlyQty;
    return quantity?.toString() ?? '0';
  }
}
