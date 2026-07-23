import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/driver_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../theme/app_tokens.dart';
import 'driver_history_screen.dart';
import 'live_meter_screen.dart';

// ─── Palette helpers ──────────────────────────────────────────────────────────

const _kLiveAccent = Color(0xFF60A5FA); // blue
const _kFixedAccent = Color(0xFFC4B5FD); // purple
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kRed = Color(0xFFDC2626);
const _kBg = Color(0xFF0F0F1A);
const _kCard = Color(0xFF16213E);
const _kCardDeep = Color(0xFF1A1A2E);

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _driverService = DriverService();
  List<dynamic> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await _driverService.getActiveDriverTrips();
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _liveTrips => _trips
      .whereType<Map<String, dynamic>>()
      .where((t) => t['billingMode'] == 'LIVE')
      .toList();

  List<Map<String, dynamic>> get _fixedTrips => _trips
      .whereType<Map<String, dynamic>>()
      .where((t) => t['billingMode'] == 'PRE_BOOKED')
      .toList();

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _startTrip(Map<String, dynamic> trip,
      {bool convertToLive = false}) async {
    final id = trip['hourlyCharterBookId'] as int;
    try {
      await _driverService.startTrip(id, convertToLive: convertToLive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(convertToLive
            ? 'Trip started — running as live meter!'
            : 'Trip started — fixed rate billing active.'),
        backgroundColor: _kGreen,
      ));
      _loadTrips();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _kRed),
      );
    }
  }

  Future<void> _extendWithLive(Map<String, dynamic> trip) async {
    final id = trip['hourlyCharterBookId'] as int;
    try {
      await _driverService.extendLive(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Live meter extension activated!'),
        backgroundColor: Color(0xFF7C3AED),
      ));
      _loadTrips();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: _kRed),
      );
    }
  }

  void _openLiveMeter(Map<String, dynamic> trip) {
    final id = trip['hourlyCharterBookId'] as int;
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => LiveMeterScreen(bookingId: id)))
        .then((_) => _loadTrips());
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_kAmber, Color(0xFFD97706)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car_filled,
                  color: _kCardDeep, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Driver Mode',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(user?.fullName ?? '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white54),
            tooltip: 'Trip History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriverHistoryScreen()),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.refresh, color: _kAmber),
              onPressed: _loadTrips),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () {
              context.read<BookingProvider>().resetRealtimeState();
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _kAmber,
        backgroundColor: _kCard,
        onRefresh: _loadTrips,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAmber))
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _loadTrips)
                : _trips.isEmpty
                    ? _EmptyView(onRefresh: _loadTrips)
                    : _buildTripList(),
      ),
    );
  }

  Widget _buildTripList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_liveTrips.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.speed,
            label: 'Live Meter Trips',
            count: _liveTrips.length,
            accent: _kLiveAccent,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final t in _liveTrips) ...[
            _TripCard(
              trip: t,
              onStartTrip: (convert) => _startTrip(t, convertToLive: convert),
              onExtendLive: () => _extendWithLive(t),
              onOpenMeter: () => _openLiveMeter(t),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_fixedTrips.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.lock_clock,
            label: 'Fixed Rate Trips',
            count: _fixedTrips.length,
            accent: _kFixedAccent,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final t in _fixedTrips) ...[
            _TripCard(
              trip: t,
              onStartTrip: (convert) => _startTrip(t, convertToLive: convert),
              onExtendLive: () => _extendWithLive(t),
              onOpenMeter: () => _openLiveMeter(t),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.icon,
      required this.label,
      required this.count,
      required this.accent});
  final IconData icon;
  final String label;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(label,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5)),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$count',
              style: TextStyle(
                  color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ─── Trip card ───────────────────────────────────────────────────────────────

class _TripCard extends StatefulWidget {
  const _TripCard({
    required this.trip,
    required this.onStartTrip,
    required this.onExtendLive,
    required this.onOpenMeter,
  });
  final Map<String, dynamic> trip;
  final void Function(bool convertToLive) onStartTrip;
  final VoidCallback onExtendLive;
  final VoidCallback onOpenMeter;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _loading = false;

  Map<String, dynamic> get _trip => widget.trip;
  String get _status => (_trip['bookingStatus'] as String?) ?? '';
  String get _billing => (_trip['billingMode'] as String?) ?? 'LIVE';
  bool get _isLive => _billing == 'LIVE';
  bool get _isEnRoute => _status == 'EN_ROUTE';
  bool get _hasExtension => _trip['liveExtensionStartedAt'] != null;

  Color get _accent => _isLive ? _kLiveAccent : _kFixedAccent;

  // ─── Dialogs ────────────────────────────────────────────────────────────

  Future<void> _showStartDialog() async {
    bool convertToLive = false;

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _StartTripDialog(
        isFixed: !_isLive,
        onConfirm: (bool convert) {
          convertToLive = convert;
          Navigator.pop(ctx, true);
        },
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    widget.onStartTrip(convertToLive);
    setState(() => _loading = false);
  }

  Future<void> _showExtendDialog() async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Extend with Live Meter?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The booked hours have ended. Activate the live meter to continue billing the customer in real time.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kFixedAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kFixedAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: _kFixedAccent, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Original fixed fare is locked in. Extension is billed at the live rate.',
                      style: TextStyle(
                          color: _kFixedAccent.withOpacity(0.9), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.timer, size: 16),
            label: const Text('Activate Extension',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    widget.onExtendLive();
    setState(() => _loading = false);
  }

  // ─── Action logic ────────────────────────────────────────────────────────

  void _handleAction() {
    if (_isEnRoute) {
      if (!_isLive && !_hasExtension) {
        _showExtendDialog();
      } else {
        widget.onOpenMeter();
      }
    } else {
      _showStartDialog();
    }
  }

  // ─── Action button appearance ────────────────────────────────────────────

  ({String label, IconData icon, Color bg, Color fg}) get _actionBtn {
    if (_isEnRoute) {
      if (!_isLive && !_hasExtension) {
        return (
          label: 'Extend with Live Meter',
          icon: Icons.timer,
          bg: const Color(0xFF7C3AED),
          fg: Colors.white
        );
      }
      final color = _isLive ? _kAmber : _kFixedAccent;
      return (
        label: 'Open Live Meter',
        icon: Icons.speed,
        bg: color,
        fg: _kCardDeep
      );
    }
    return (
      label: 'Start Trip',
      icon: Icons.play_arrow_rounded,
      bg: _kGreen,
      fg: Colors.white
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final car = trip['Car'] as Map<String, dynamic>?;

    final statusColor =
        _isEnRoute ? const Color(0xFFFCD34D) : const Color(0xFF6EE7B7);
    final statusBg =
        _isEnRoute ? const Color(0xFF78350F) : const Color(0xFF065F46);
    final statusLabel = _isEnRoute ? 'In Progress' : 'Accepted';
    final btn = _actionBtn;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCardDeep, _kCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car_filled,
                      color: _accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(car?['carName'] ?? 'Vehicle',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text('#${trip['confirmationNumber'] ?? '—'}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusBg, borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),

            // ── Extension badge ──────────────────────────────────────────
            if (_hasExtension) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kFixedAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kFixedAccent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, color: _kFixedAccent, size: 14),
                    const SizedBox(width: 5),
                    const Text('Live Extending',
                        style: TextStyle(
                            color: _kFixedAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 14),

            // ── Route (left) + trip meta (right), as two columns ─────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationRow(
                          icon: Icons.location_on,
                          color: _kAmber,
                          label: 'Pickup',
                          address: trip['pickupPhysicalAddress'] ?? '—'),
                      const SizedBox(height: AppSpacing.sm),
                      _LocationRow(
                          icon: Icons.location_on,
                          color: _kLiveAccent,
                          label: 'Dropoff',
                          address: trip['dropoffPhysicalAddress'] ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 1,
                  height: 56,
                  color: Colors.white.withOpacity(0.08),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _MetaChip(
                          icon: Icons.access_time,
                          label: '${trip['selectedHours']}h booked',
                          color: _kAmber),
                      const SizedBox(height: 8),
                      _MetaChip(
                        icon: _isLive ? Icons.speed : Icons.lock_clock,
                        label: _isLive ? 'LIVE meter' : 'Fixed rate',
                        color: _accent,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Action button ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _handleAction,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(btn.icon, size: 20),
                label: Text(btn.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btn.bg,
                  foregroundColor: btn.fg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: btn.bg.withOpacity(0.4),
                  disabledForegroundColor: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Start Trip Dialog ────────────────────────────────────────────────────────

class _StartTripDialog extends StatefulWidget {
  const _StartTripDialog(
      {required this.isFixed, required this.onConfirm, required this.onCancel});
  final bool isFixed;
  final void Function(bool convertToLive) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_StartTripDialog> createState() => _StartTripDialogState();
}

class _StartTripDialogState extends State<_StartTripDialog> {
  bool _convertToLive = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Start Trip?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isFixed
                ? 'This will start the trip and begin the fixed-rate booking period.'
                : 'This will start the live meter billing.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          if (widget.isFixed) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _kFixedAccent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kFixedAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Convert to Live Meter',
                            style: TextStyle(
                                color: _kFixedAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('Bill by actual time instead of fixed rate',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.45),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _convertToLive,
                    onChanged: (v) => setState(() => _convertToLive = v),
                    activeColor: _kFixedAccent,
                    inactiveTrackColor: Colors.white.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton.icon(
          onPressed: () => widget.onConfirm(_convertToLive),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Start',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _convertToLive ? _kFixedAccent : _kGreen,
            foregroundColor: _convertToLive ? _kCardDeep : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _LocationRow extends StatelessWidget {
  const _LocationRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.address});
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 10)),
              Text(address,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 52),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: _kAmber),
              child: const Text('Retry',
                  style: TextStyle(
                      color: _kCardDeep, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car_outlined,
                color: Colors.white.withOpacity(0.12), size: 72),
            const SizedBox(height: AppSpacing.md),
            Text('No active trips',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Accepted or in-progress bookings (LIVE or fixed) will appear here.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: _kAmber, size: 18),
              label: const Text('Refresh', style: TextStyle(color: _kAmber)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kAmber, width: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
