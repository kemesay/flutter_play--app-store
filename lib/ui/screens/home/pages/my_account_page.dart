import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../providers/booking_provider.dart';
import '../../../../providers/payment_provider.dart';
import '../../../../data/models/booking_history_item.dart';
import '../../../../data/services/promo_code_service.dart';
import '../../../../core/exceptions/api_exception.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/field_widget.dart';
import '../../auth/change_password_screen.dart';
import '../../admin/admin_active_trips_screen.dart';
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
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.role == 'admin';
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
                  context.read<BookingProvider>().resetRealtimeState();
                  await context.read<AuthProvider>().logout();
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // User Profile Header with profile image at the top
        _UserProfileHeader(paymentProvider: paymentProvider),
        const SizedBox(height: AppSpacing.lg),

        // Ride Statistics Section
        _RideStatisticsCard(
          totalRides: totalRides,
          pointToPointRides: pointToPointRides,
          hourlyRides: hourlyRides,
          airportRides: airportRides,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Savings & Rewards Summary
        const _DiscountSummaryCard(),
        const SizedBox(height: AppSpacing.lg),

        // Active Promotion (a currently-live public promo code, if any)
        const _ActivePromoCard(),
        const SizedBox(height: AppSpacing.lg),

        // Referral Code Section
        const _ReferralCodeCard(),
        const SizedBox(height: AppSpacing.lg),

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

        const SizedBox(height: AppSpacing.md),

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

        const SizedBox(height: AppSpacing.md),

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

        if (isAdmin) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'Admin Panel',
            icon: Icons.admin_panel_settings,
            iconColor: const Color(0xFFF472B6),
            children: [
              _MenuItem(
                title: 'Active Trips Control',
                icon: Icons.speed,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminActiveTripsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
            SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),

            // User name
            Center(
              child: Text(
                user?.fullName ?? 'ODA Guest',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Membership status
            Center(
              child: Text(
                'Member since ${_formatMemberSince(user?.createdAt)}',
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
            Field(
              label: 'Full Name',
              value: user?.fullName ?? 'Not provided',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Phone
            Field(
              label: 'Phone',
              value: user?.phoneNumber ?? 'Not provided',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Email
            Field(
              label: 'Email',
              value: user?.email ?? 'Not provided',
            ),
            const SizedBox(height: AppSpacing.sm),

            // Preferred Payment
            if (primaryCard != null)
              Field(
                label: 'Preferred Payment',
                value: '${primaryCard.maskedCardNumber} '
                    '(${primaryCard.expirationDate})',
              ),
          ],
        ),
      ),
    );
  }

  static String _formatMemberSince(DateTime? createdAt) {
    if (createdAt == null) return '—';
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[createdAt.month - 1]} ${createdAt.year}';
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
            const SizedBox(height: AppSpacing.md),

            // Total Summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.list,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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

class _DiscountSummaryCard extends StatefulWidget {
  const _DiscountSummaryCard();

  @override
  State<_DiscountSummaryCard> createState() => _DiscountSummaryCardState();
}

class _DiscountSummaryCardState extends State<_DiscountSummaryCard> {
  final _promoCodeService = PromoCodeService();

  bool _loading = true;
  DiscountSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _promoCodeService.getMyDiscountSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      // Non-critical section — fail silently rather than blocking the rest
      // of the account page (mirrors the referral card's behavior).
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _progressRow(
    ThemeData theme,
    String label,
    int used,
    int? limit, {
    String verb = 'earned',
  }) {
    final colorScheme = theme.colorScheme;

    // Null limit means this bucket is uncapped (e.g. referral rewards
    // earned, or public codes now that each code caps itself instead of a
    // shared lifetime bucket) — show a count instead of a progress bar with
    // no ceiling.
    if (limit == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              '$used $verb — unlimited',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$used of $limit used',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0,
              minHeight: 8,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    final summary = _summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'My Savings & Rewards',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Every discount you've used, and every reward you've earned "
              'by referring friends.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$${summary.totalSaved.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total Saved',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.referralRewardsEarned.used}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Rewards Earned by Referring',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _progressRow(
              theme,
              'First-booking / occasion promo codes',
              summary.publicCodes.used,
              summary.publicCodes.limit,
              verb: 'used',
            ),
            _progressRow(
              theme,
              "Referral codes you've used",
              summary.referralCodesSpent.used,
              summary.referralCodesSpent.limit,
            ),
            _progressRow(
              theme,
              'Referral rewards earned',
              summary.referralRewardsEarned.used,
              summary.referralRewardsEarned.limit,
            ),
            if (summary.pendingReferralRewards > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      size: 16, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${summary.pendingReferralRewards} referral'
                      '${summary.pendingReferralRewards > 1 ? 's' : ''} pending '
                      '— reward arrives once their trip is completed and paid.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivePromoCard extends StatefulWidget {
  const _ActivePromoCard();

  @override
  State<_ActivePromoCard> createState() => _ActivePromoCardState();
}

class _ActivePromoCardState extends State<_ActivePromoCard> {
  final _promoCodeService = PromoCodeService();

  bool _loading = true;
  ActivePublicPromo? _promo;
  Timer? _countdownTimer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _loadPromo();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPromo() async {
    try {
      final promo = await _promoCodeService.getActivePublicPromo();
      if (!mounted) return;
      setState(() {
        _promo = promo;
        _loading = false;
      });
      _startCountdownIfNeeded();
    } catch (_) {
      // Non-critical section — fail silently, same as the other account cards.
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _startCountdownIfNeeded() {
    if (_promo?.expiresAt == null) return;
    _tickCountdown();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  void _tickCountdown() {
    final expiresAt = _promo?.expiresAt;
    if (expiresAt == null || !mounted) return;
    setState(() => _countdown = _formatCountdown(expiresAt.difference(DateTime.now())));
  }

  static String _formatCountdown(Duration remaining) {
    if (remaining.isNegative) return 'Expired';
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    final promo = _promo;
    if (promo == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Active Promotion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'A current promo code you can use right now on your next booking.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  promo.code,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  promo.discountLabel,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (_countdown.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Expires in $_countdown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                Text(
                  '${promo.remainingUses} use${promo.remainingUses == 1 ? '' : 's'} left for you',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((promo.minFareAmount ?? 0) > 0)
                  Text(
                    'Minimum fare \$${promo.minFareAmount!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

class _ReferralCodeCard extends StatefulWidget {
  const _ReferralCodeCard();

  @override
  State<_ReferralCodeCard> createState() => _ReferralCodeCardState();
}

class _ReferralCodeCardState extends State<_ReferralCodeCard> {
  final _promoCodeService = PromoCodeService();

  bool _loading = true;
  ReferralCodeInfo? _referral;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    try {
      final referral = await _promoCodeService.getMyReferralCode();
      if (!mounted) return;
      setState(() {
        _referral = referral;
        _loading = false;
      });
    } on ApiException {
      // Non-critical section — fail silently rather than blocking the rest
      // of the account page (mirrors the website's My Account behavior).
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _copyLink() async {
    final referral = _referral;
    if (referral == null) return;
    await Clipboard.setData(ClipboardData(text: referral.link));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _shareLink() async {
    final referral = _referral;
    if (referral == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text: referral.shareMessage,
        subject: 'ODA Transportation — Refer a Friend',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    final referral = _referral;
    if (referral == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Refer a Friend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Share your link, your friend gets '
              '${referral.discountValue.toStringAsFixed(0)}% off their first '
              'ride, and you get a reward once they complete it.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                referral.code,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    referral.link,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _copyLink,
                  tooltip: 'Copy link',
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: _copied ? colorScheme.primary : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _shareLink,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
