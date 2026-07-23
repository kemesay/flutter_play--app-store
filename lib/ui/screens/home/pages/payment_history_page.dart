import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/payment_status_map.dart';
import '../../../../data/models/booking_history_item.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../core/utils/date_utils.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    // Get all bookings and transform to payment history
    final payments = bookingProvider.bookings
        .where((booking) => booking.totalFee != null)
        .toList()
      ..sort((a, b) {
        final aDate =
            a.pickupDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.pickupDateTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: bookingProvider.refreshBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: bookingProvider.refreshBookings,
        child: bookingProvider.isLoadingHistory
            ? const Center(child: CircularProgressIndicator())
            : payments.isEmpty
                ? _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _PaymentCard(payment: payment);
                    },
                  ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final BookingHistoryItem payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Match website: format to Pacific timezone
    final dateText = formatDateToPacific(payment.pickupDateTime);

    final statusColor = _getStatusColor(payment.paymentStatus, colorScheme);
    final paymentMethodText = formatPaymentMethodLabel(payment.paymentMethod);
    final statusLabel = formatPaymentStatusLabel(payment.paymentStatus);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.displayTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor.foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (payment.pickupAddress != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      payment.pickupAddress!,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      paymentMethodText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${payment.totalFee!.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (payment.confirmationNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Confirmation: #${payment.confirmationNumber}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusColor _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return _StatusColor(
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        );
      case 'AUTHORIZED':
        return const _StatusColor(Color(0xFFFFF3E0), Color(0xFFE65100));
      case 'AWAITING_PAYMENT':
      case 'PENDING':
      case 'PENDING_APPROVAL':
        return _StatusColor(
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        );
      case 'NOT_PAID':
      case 'FAILED':
      case 'CANCELLED':
        return _StatusColor(
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        );
      case 'REFUNDED':
        return _StatusColor(
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        );
      default:
        return _StatusColor(
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        );
    }
  }
}

extension StringExtension on String {
  String toTitleCase() {
    return split(' ')
        .map((word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

class _StatusColor {
  const _StatusColor(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.payment_outlined,
          size: 64,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No payment history yet.\nYour payment transactions will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
