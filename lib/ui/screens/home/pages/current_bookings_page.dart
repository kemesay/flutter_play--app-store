import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/booking_history_item.dart';
import '../../../../providers/booking_provider.dart';
import 'widgets/trip_card.dart';

class CurrentBookingsPage extends StatefulWidget {
  const CurrentBookingsPage({super.key});

  @override
  State<CurrentBookingsPage> createState() => _CurrentBookingsPageState();
}

class _CurrentBookingsPageState extends State<CurrentBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    // Filter only current (non-completed) bookings
    final currentBookings = bookingProvider.bookings.where((booking) {
      return booking.bookingStatus != 'COMPLETED';
    }).toList();

    // Group bookings by type
    final airportBookings =
        currentBookings.where((b) => b.type == BookingType.airport).toList();
    final pointToPointBookings = currentBookings
        .where((b) => b.type == BookingType.pointToPoint)
        .toList();
    final hourlyBookings = currentBookings
        .where((b) => b.type == BookingType.hourlyCharter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current Bookings',
          style: TextStyle(
            color: Color(0xFF03930A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isVerySmall = screenWidth < 340;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 8 : 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03930A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 8 : 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab Bar - Responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isSmallScreen = screenWidth < 360;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: isSmallScreen,
                  indicatorColor: const Color(0xFF03930A),
                  indicatorWeight: 3,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                  tabAlignment:
                      isSmallScreen ? TabAlignment.start : TabAlignment.fill,
                  tabs: [
                    _TabWithBadge(
                      icon: Icons.flight,
                      label: 'Airport',
                      badge: airportBookings.isNotEmpty
                          ? airportBookings.length
                          : null,
                      isCompact: isSmallScreen,
                    ),
                    _TabWithBadge(
                      icon: Icons.location_on,
                      label: 'Point To Point',
                      badge: pointToPointBookings.isNotEmpty
                          ? pointToPointBookings.length
                          : null,
                      isCompact: isSmallScreen,
                    ),
                    _TabWithBadge(
                      icon: Icons.access_time,
                      label: 'Hourly',
                      badge: hourlyBookings.isNotEmpty
                          ? hourlyBookings.length
                          : null,
                      isCompact: isSmallScreen,
                    ),
                  ],
                ),
              );
            },
          ),
          // Tab Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: bookingProvider.refreshBookings,
              child: bookingProvider.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _BookingList(bookings: airportBookings),
                        _BookingList(bookings: pointToPointBookings),
                        _BookingList(bookings: hourlyBookings),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabWithBadge extends StatelessWidget {
  const _TabWithBadge({
    required this.icon,
    required this.label,
    this.badge,
    this.isCompact = false,
  });

  final IconData icon;
  final String label;
  final int? badge;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    // Shorten label for compact mode intelligently
    String displayLabel = label;
    if (isCompact) {
      if (label == 'Point To Point') {
        displayLabel = 'P to P';
      } else if (label.length > 10) {
        displayLabel = '${label.substring(0, 8)}...';
      }
    }

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? 16 : 18),
          SizedBox(width: isCompact ? 4 : 6),
          Flexible(
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (badge != null && badge! > 0) ...[
            SizedBox(width: isCompact ? 4 : 6),
            Container(
              padding: EdgeInsets.all(isCompact ? 3 : 4),
              decoration: const BoxDecoration(
                color: Color(0xFF03930A),
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: isCompact ? 16 : 18,
                minHeight: isCompact ? 16 : 18,
              ),
              child: Center(
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 9 : 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings});

  final List<BookingHistoryItem> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return TripCard(
          booking: bookings[index],
          showDetailsButton: true,
          allowEdit: true,
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.event_available_outlined,
          size: 64,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Center(
          child: Text(
            'No active bookings.\nYour current trips will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
