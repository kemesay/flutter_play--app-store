import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/booking_provider.dart';
import 'widgets/trip_card.dart';

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    // Filter out COMPLETED bookings - only show non-completed bookings
    final filteredBookings = bookingProvider.bookings
        .where((booking) => booking.bookingStatus != 'COMPLETED')
        .toList();

    return RefreshIndicator(
      onRefresh: bookingProvider.refreshBookings,
      child: bookingProvider.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : filteredBookings.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(
                      Icons.directions_car_filled_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No active trips.\nYour active bookings will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredBookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final booking = filteredBookings[index];
                    return TripCard(booking: booking);
                  },
                ),
    );
  }
}
