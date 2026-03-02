import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../providers/payment_provider.dart';
import '../../../../data/models/booking_history_item.dart';
import '../../auth/change_password_screen.dart';
import 'current_bookings_page.dart';
import 'booking_history_page.dart';
import 'payment_history_page.dart';
import 'wallet_page.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  @override
  void initState() {
    super.initState();
    // Load bookings and payment info
    Future.microtask(() {
      context.read<BookingProvider>().refreshBookings();
      context.read<PaymentProvider>().loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookingProvider = context.watch<BookingProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    // Calculate counts
    final currentBookingsCount = bookingProvider.bookings
        .where((b) => b.bookingStatus != 'COMPLETED')
        .length;
    final historyBookingsCount = bookingProvider.bookings
        .where((b) => b.bookingStatus == 'COMPLETED')
        .length;

    // Calculate ride statistics
    final totalRides = bookingProvider.bookings.length;
    final pointToPointRides = bookingProvider.bookings
        .where((b) => b.type == BookingType.pointToPoint)
        .length;
    final hourlyRides = bookingProvider.bookings
        .where((b) => b.type == BookingType.hourlyCharter)
        .length;
    final airportRides = bookingProvider.bookings
        .where((b) => b.type == BookingType.airport)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Enhanced header with profile and actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Account',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await context.read<AuthProvider>().logout();
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // User Profile Header with profile image at the top
        _UserProfileHeader(paymentProvider: paymentProvider),
        const SizedBox(height: 24),

        // Ride Statistics Section
        _RideStatisticsCard(
          totalRides: totalRides,
          pointToPointRides: pointToPointRides,
          hourlyRides: hourlyRides,
          airportRides: airportRides,
        ),
        const SizedBox(height: 24),

        // My Bookings Section
        _SectionCard(
          title: 'My Bookings',
          icon: Icons.receipt_long_rounded,
          iconColor: colorScheme.primary,
          children: [
            _MenuItem(
              title: 'Current Bookings',
              icon: Icons.event_available_rounded,
              badge: currentBookingsCount > 0 ? currentBookingsCount : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CurrentBookingsPage(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              title: 'Booking History',
              icon: Icons.history_rounded,
              badge: historyBookingsCount > 0 ? historyBookingsCount : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookingHistoryPage(),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Payments Section
        _SectionCard(
          title: 'Payments',
          icon: Icons.payment_rounded,
          iconColor: colorScheme.tertiary,
          children: [
            _MenuItem(
              title: 'Payment Methods',
              icon: Icons.credit_card_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WalletPage(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              title: 'Payment History',
              icon: Icons.history_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentHistoryPage(),
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Account Management Section
        _SectionCard(
          title: 'Account',
          icon: Icons.person_rounded,
          iconColor: Colors.red,
          children: [
            _MenuItem(
              title: 'Change Password',
              icon: Icons.lock_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            _MenuItem(
              title: 'Delete Account',
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.red,
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    // First confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete your account?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone. All your data will be permanently deleted, including:',
            ),
            SizedBox(height: 8),
            Text('• Your profile information'),
            Text('• Booking history'),
            Text('• Payment methods'),
            Text('• All account data'),
            SizedBox(height: 12),
            Text(
              'If you have any active bookings, please cancel them before deleting your account.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Second confirmation dialog (App Store requirement - prevent accidental deletion)
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Final Confirmation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is your last chance to cancel.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'Your account will be permanently deleted and cannot be recovered. Are you absolutely sure?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (finalConfirmed != true) return;

    // Show loading indicator
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Delete account
    final success = await authProvider.deleteAccount();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      // Show success message and navigate to auth screen
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been permanently deleted.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      // Navigation will happen automatically via AuthProvider state change
    } else {
      // Show error message
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Failed to delete account. Please try again.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _UserProfileHeader extends StatelessWidget {
  final PaymentProvider paymentProvider;

  const _UserProfileHeader({required this.paymentProvider});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    // Get primary payment card
    final primaryCard = paymentProvider.primaryCard;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image at the top
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'O',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // User name
            Center(
              child: Text(
                user?.fullName ?? 'ODA Guest',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Membership status
            Center(
              child: Text(
                'Member since January 2024',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Personal Information & Settings
            Text(
              'Personal Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Full Name
            _ProfileInfoRow(
              label: 'Full Name',
              value: user?.fullName ?? 'Not provided',
            ),
            const SizedBox(height: 8),

            // Phone
            _ProfileInfoRow(
              label: 'Phone',
              value: user?.phoneNumber ?? 'Not provided',
            ),
            const SizedBox(height: 8),

            // Email
            _ProfileInfoRow(
              label: 'Email',
              value: user?.email ?? 'Not provided',
            ),
            const SizedBox(height: 8),

            // Preferred Payment
            if (primaryCard != null)
              _ProfileInfoRow(
                label: 'Preferred Payment',
                value: '${primaryCard.maskedCardNumber} '
                    '(${primaryCard.expirationDate})',
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _RideStatisticsCard extends StatelessWidget {
  final int totalRides;
  final int pointToPointRides;
  final int hourlyRides;
  final int airportRides;

  const _RideStatisticsCard({
    required this.totalRides,
    required this.pointToPointRides,
    required this.hourlyRides,
    required this.airportRides,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ride Statistics',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Total Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.list,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalRides',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total Rides',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Ride Breakdown
            Row(
              children: [
                // Point-to-Point
                Expanded(
                  child: _RideStatCard(
                    icon: Icons.route,
                    count: pointToPointRides,
                    label: 'Point-to-Point',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                // Hourly
                Expanded(
                  child: _RideStatCard(
                    icon: Icons.access_time,
                    count: hourlyRides,
                    label: 'Hourly',
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                // Airport
                Expanded(
                  child: _RideStatCard(
                    icon: Icons.flight_takeoff,
                    count: airportRides,
                    label: 'Airport',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RideStatCard extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _RideStatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badge,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? badge;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: effectiveIconColor),
      title: Text(
        title,
        style: iconColor != null ? TextStyle(color: iconColor) : null,
      ),
      trailing: badge != null
          ? Badge(
              label: Text('$badge'),
              child: const Icon(Icons.chevron_right),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
