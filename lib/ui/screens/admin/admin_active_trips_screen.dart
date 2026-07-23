import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/json_parsing.dart';
import '../../../data/services/driver_service.dart';
import '../../../providers/auth_provider.dart';
import '../driver/driver_history_screen.dart';
import '../driver/live_meter_screen.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

const _kAdminAccent = Color(0xFFF472B6); // pink/rose — admin branding
const _kLiveAccent = Color(0xFF60A5FA); // blue
const _kFixedAccent = Color(0xFFC4B5FD); // purple
const _kGreen = Color(0xFF10B981);
const _kAmber = Color(0xFFF59E0B);
const _kRed = Color(0xFFEF4444);
const _kBg = Color(0xFF0B0B1A);
const _kCard = Color(0xFF161626);
const _kCardDeep = Color(0xFF1A1A2E);

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminActiveTripsScreen extends StatefulWidget {
  const AdminActiveTripsScreen({super.key});

  @override
  State<AdminActiveTripsScreen> createState() => _AdminActiveTripsScreenState();
}

class _AdminActiveTripsScreenState extends State<AdminActiveTripsScreen> {
  final _svc = DriverService();
  List<Map<String, dynamic>> _trips = [];
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
      final raw = await _svc.getActiveDriverTrips();
      setState(() {
        _trips = raw.whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ─── Grouped views ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _liveTrips =>
      _trips.where((t) => t['billingMode'] == 'LIVE').toList();
  List<Map<String, dynamic>> get _fixedTrips =>
      _trips.where((t) => t['billingMode'] == 'PRE_BOOKED').toList();

  // ─── Actions ────────────────────────────────────────────────────────────────

  Future<void> _doStart(Map<String, dynamic> trip,
      {bool convertToLive = false}) async {
    final id = trip['hourlyCharterBookId'] as int;
    try {
      await _svc.startTrip(id, convertToLive: convertToLive);
      if (!mounted) return;
      _snack(
          convertToLive
              ? 'Trip started as live meter!'
              : 'Trip started (fixed rate).',
          _kGreen);
      _loadTrips();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), _kRed);
    }
  }

  Future<void> _doExtend(Map<String, dynamic> trip) async {
    final id = trip['hourlyCharterBookId'] as int;
    try {
      await _svc.extendLive(id);
      if (!mounted) return;
      _snack('Live meter extension activated!', const Color(0xFF7C3AED));
      _loadTrips();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), _kRed);
    }
  }

  Future<void> _doEnd(Map<String, dynamic> trip) async {
    final id = trip['hourlyCharterBookId'] as int;
    try {
      final res = await _svc.endTrip(id);
      if (!mounted) return;
      final total = asDouble(res['totalTripFeeInDollars']).toStringAsFixed(2);
      _snack('Trip ended! Total: \$$total', _kGreen);
      _loadTrips();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString(), _kRed);
    }
  }

  void _openLiveMeter(Map<String, dynamic> trip) {
    final id = trip['hourlyCharterBookId'] as int;
    Navigator.push(context,
            MaterialPageRoute(builder: (_) => LiveMeterScreen(bookingId: id)))
        .then((_) => _loadTrips());
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bg),
    );
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
                gradient: const LinearGradient(
                    colors: [_kAdminAccent, Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Trips',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text(user?.fullName ?? 'Admin',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kAdminAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kAdminAccent.withOpacity(0.35)),
              ),
              child: Text('${_trips.length}',
                  style: const TextStyle(
                      color: _kAdminAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
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
              icon: const Icon(Icons.refresh, color: _kAdminAccent),
              onPressed: _loadTrips),
        ],
      ),
      body: RefreshIndicator(
        color: _kAdminAccent,
        backgroundColor: _kCard,
        onRefresh: _loadTrips,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _kAdminAccent))
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _loadTrips)
                : _trips.isEmpty
                    ? _EmptyView(onRefresh: _loadTrips)
                    : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_liveTrips.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.speed,
              label: 'Live Meter',
              count: _liveTrips.length,
              accent: _kLiveAccent),
          const SizedBox(height: 8),
          for (final t in _liveTrips) ...[
            _AdminTripCard(
              trip: t,
              onStart: (c) => _doStart(t, convertToLive: c),
              onExtend: () => _doExtend(t),
              onEnd: () => _doEnd(t),
              onOpenMeter: () => _openLiveMeter(t),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
        if (_fixedTrips.isNotEmpty) ...[
          _SectionHeader(
              icon: Icons.lock_clock,
              label: 'Fixed Rate',
              count: _fixedTrips.length,
              accent: _kFixedAccent),
          const SizedBox(height: 8),
          for (final t in _fixedTrips) ...[
            _AdminTripCard(
              trip: t,
              onStart: (c) => _doStart(t, convertToLive: c),
              onExtend: () => _doExtend(t),
              onEnd: () => _doEnd(t),
              onOpenMeter: () => _openLiveMeter(t),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

// ─── Trip card ─────────────────────────────────────────────────────────────────

class _AdminTripCard extends StatefulWidget {
  const _AdminTripCard({
    required this.trip,
    required this.onStart,
    required this.onExtend,
    required this.onEnd,
    required this.onOpenMeter,
  });
  final Map<String, dynamic> trip;
  final void Function(bool convertToLive) onStart;
  final VoidCallback onExtend;
  final VoidCallback onEnd;
  final VoidCallback onOpenMeter;

  @override
  State<_AdminTripCard> createState() => _AdminTripCardState();
}

class _AdminTripCardState extends State<_AdminTripCard> {
  Map<String, dynamic>? _liveStatus;
  Timer? _timer;
  bool _actionLoading = false;

  Map<String, dynamic> get _t => widget.trip;
  String get _status => (_t['bookingStatus'] as String?) ?? '';
  String get _billing => (_t['billingMode'] as String?) ?? 'LIVE';
  bool get _isLive => _billing == 'LIVE';
  bool get _isEnRoute => _status == 'EN_ROUTE';
  bool get _isAccepted => _status == 'ACCEPTED';
  bool get _hasExtension => _t['liveExtensionStartedAt'] != null;
  int get _id => (_t['hourlyCharterBookId'] as int?) ?? 0;
  Color get _accent => _isLive ? _kLiveAccent : _kFixedAccent;

  @override
  void initState() {
    super.initState();
    if (_isEnRoute) _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _fetchLiveStatus();
    _timer =
        Timer.periodic(const Duration(seconds: 15), (_) => _fetchLiveStatus());
  }

  Future<void> _fetchLiveStatus() async {
    if (_id == 0) return;
    try {
      final s = await DriverService().getLiveStatus(_id);
      if (mounted) setState(() => _liveStatus = s);
    } catch (_) {}
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────────

  Future<void> _showStartDialog() async {
    bool convert = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AdminStartDialog(
        isFixed: !_isLive,
        passengerName: _t['passengerFullName']?.toString() ?? 'Passenger',
        onConfirm: (v) {
          convert = v;
          Navigator.pop(ctx, true);
        },
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (ok != true) return;
    setState(() => _actionLoading = true);
    try {
      widget.onStart(convert);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showExtendDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Activate Live Extension?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'This will lock the current fixed fare and start billing the passenger at the live meter rate for additional time.',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED)),
            child: const Text('Activate',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionLoading = true);
    try {
      widget.onExtend();
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showEndDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Trip & Finalize?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will finalize billing and close the trip.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
            if (_liveStatus != null) ...[
              const SizedBox(height: 12),
              _StatRow(
                  'Running Fare',
                  '\$${asDouble(_liveStatus!['runningFare']).toStringAsFixed(2)}',
                  _kGreen),
              if (_liveStatus!['mode'] == 'EXTENDED')
                _StatRow(
                    'Base Fare',
                    '\$${asDouble(_liveStatus!['baseFare']).toStringAsFixed(2)}',
                    _kFixedAccent),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed),
            child: const Text('End & Finalize',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _actionLoading = true);
    try {
      widget.onEnd();
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final car = _t['Car'] as Map<String, dynamic>?;
    final passenger = _t['passengerFullName']?.toString() ?? '—';
    final mode = _liveStatus?['mode'] as String?;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCardDeep, _kCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _kAdminAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: _kAdminAccent, size: 22),
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
                      Text('#${_t['confirmationNumber'] ?? '—'}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 12)),
                    ],
                  ),
                ),
                _StatusPill(status: _status),
              ],
            ),

            const SizedBox(height: 10),

            // ── Passenger ────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline,
                    color: Colors.white.withOpacity(0.35), size: 14),
                const SizedBox(width: 6),
                Text(passenger,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13)),
                const SizedBox(width: 10),
                Icon(Icons.access_time,
                    color: Colors.white.withOpacity(0.35), size: 14),
                const SizedBox(width: 4),
                Text('${_t['selectedHours']}h',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 13)),
              ],
            ),

            // ── Extension badge ────────────────────────────────────────────
            if (_hasExtension) ...[
              const SizedBox(height: 8),
              _Pill(
                  label: '⚡ Live Extending',
                  bg: _kFixedAccent.withOpacity(0.12),
                  fg: _kFixedAccent,
                  border: _kFixedAccent),
            ],

            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.07), height: 1),
            const SizedBox(height: 12),

            // ── Live status panel ──────────────────────────────────────────
            if (_isEnRoute && _liveStatus != null) ...[
              _LiveStatusPanel(status: _liveStatus!, mode: mode),
              const SizedBox(height: 12),
            ],

            // ── Billing mode chips row ─────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Pill(
                  label: _isLive ? '⚡ LIVE meter' : '🔒 Fixed rate',
                  bg: _accent.withOpacity(0.1),
                  fg: _accent,
                  border: _accent,
                ),
                if (mode == 'EXTENDED')
                  const _Pill(
                      label: '↔ Extended',
                      bg: Color(0x1AC4B5FD),
                      fg: _kFixedAccent,
                      border: _kFixedAccent),
                if (mode == 'CONVERTED')
                  const _Pill(
                      label: '↔ Converted',
                      bg: Color(0x1A60A5FA),
                      fg: _kLiveAccent,
                      border: _kLiveAccent),
              ],
            ),

            const SizedBox(height: 14),

            // ── Action buttons ─────────────────────────────────────────────
            if (_isAccepted) ...[
              _ActionButton(
                label: '▶ Start Trip',
                color: _kGreen,
                fg: Colors.white,
                loading: _actionLoading,
                onTap: _showStartDialog,
              ),
            ],

            if (_isEnRoute) ...[
              if (_isLive || _hasExtension)
                _ActionButton(
                  label: '⏱ View Live Meter',
                  color: _kAmber,
                  fg: _kCardDeep,
                  loading: _actionLoading,
                  onTap: widget.onOpenMeter,
                ),
              if (!_isLive && !_hasExtension) ...[
                _ActionButton(
                  label: '⚡ Extend with Live Meter',
                  color: const Color(0xFF7C3AED),
                  fg: Colors.white,
                  loading: _actionLoading,
                  onTap: _showExtendDialog,
                ),
              ],
              const SizedBox(height: 8),
              _ActionButton(
                label: '⏹ End Trip & Finalize',
                color: _kRed,
                fg: Colors.white,
                loading: _actionLoading,
                onTap: _showEndDialog,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Live status panel ─────────────────────────────────────────────────────────

class _LiveStatusPanel extends StatelessWidget {
  const _LiveStatusPanel({required this.status, required this.mode});
  final Map<String, dynamic> status;
  final String? mode;

  @override
  Widget build(BuildContext context) {
    final bg = mode == 'EXTENDED'
        ? const Color(0xFF1A0A2E)
        : mode == 'CONVERTED'
            ? const Color(0xFF0A1220)
            : const Color(0xFF0A1A0A);
    final border = mode == 'EXTENDED'
        ? _kFixedAccent.withOpacity(0.3)
        : mode == 'CONVERTED'
            ? _kLiveAccent.withOpacity(0.3)
            : _kGreen.withOpacity(0.3);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Status',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 10,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatRow('Elapsed', _elapsedStr, Colors.white70)),
              Expanded(
                  child: _StatRow(
                      'Running Fare',
                      '\$${asDouble(status['runningFare']).toStringAsFixed(2)}',
                      _kGreen)),
            ],
          ),
          if (mode == 'EXTENDED') ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                    child: _StatRow(
                        '🔒 Base Fare',
                        '\$${asDouble(status['baseFare']).toStringAsFixed(2)}',
                        _kFixedAccent)),
                Expanded(
                    child: _StatRow(
                        'Extension',
                        '+\$${asDouble(status['extensionFare']).toStringAsFixed(2)}',
                        _kFixedAccent)),
              ],
            ),
          ],
          if (status['isOvertime'] == true) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warning_amber, color: _kAmber, size: 14),
                const SizedBox(width: 4),
                Text('Past booked hours — normal rate',
                    style: TextStyle(
                        color: _kAmber.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String get _elapsedStr {
    final formatted = status['elapsedFormatted'];
    if (formatted is String && formatted.isNotEmpty) return formatted;
    // EXTENDED shows the continuous total (booked hours + extension so far),
    // matching the driver's live meter clock, instead of resetting to zero.
    final mins = mode == 'EXTENDED'
        ? asNum(status['totalElapsedMinutes'])?.toInt() ??
            asNum(status['extensionMinutes'])?.toInt() ??
            0
        : asInt(status['elapsedMinutes']);
    final h = mins ~/ 60;
    final m = mins % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

// ─── Stat row ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label,
      required this.color,
      required this.fg,
      required this.loading,
      required this.onTap});
  final String label;
  final Color color;
  final Color fg;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: fg,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          disabledBackgroundColor: color.withOpacity(0.4),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: TextStyle(
                    color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

// ─── Pill chip ────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label,
      required this.bg,
      required this.fg,
      required this.border});
  final String label;
  final Color bg;
  final Color fg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border.withOpacity(0.45)),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'EN_ROUTE'
        ? const Color(0xFFFCD34D)
        : status == 'ACCEPTED'
            ? const Color(0xFF6EE7B7)
            : Colors.white60;
    final bg = status == 'EN_ROUTE'
        ? const Color(0xFF78350F)
        : status == 'ACCEPTED'
            ? const Color(0xFF065F46)
            : const Color(0xFF374151);
    final label = status == 'EN_ROUTE'
        ? 'In Progress'
        : status == 'ACCEPTED'
            ? 'Accepted'
            : status;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
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
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$count',
              style: TextStyle(
                  color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ─── Admin start dialog ───────────────────────────────────────────────────────

class _AdminStartDialog extends StatefulWidget {
  const _AdminStartDialog(
      {required this.isFixed,
      required this.passengerName,
      required this.onConfirm,
      required this.onCancel});
  final bool isFixed;
  final String passengerName;
  final void Function(bool convertToLive) onConfirm;
  final VoidCallback onCancel;

  @override
  State<_AdminStartDialog> createState() => _AdminStartDialogState();
}

class _AdminStartDialogState extends State<_AdminStartDialog> {
  bool _convert = false;

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
            'Passenger: ${widget.passengerName}',
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            widget.isFixed
                ? 'This booking is fixed-rate. You can optionally convert it to live meter billing at start.'
                : 'This will start the live meter for the booking.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          if (widget.isFixed) ...[
            const SizedBox(height: 16),
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
                        Text('Bill by actual trip time instead of fixed rate',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _convert,
                    onChanged: (v) => setState(() => _convert = v),
                    activeColor: _kFixedAccent,
                    inactiveTrackColor: Colors.white.withOpacity(0.08),
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
          onPressed: () => widget.onConfirm(_convert),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Start',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _convert ? _kFixedAccent : _kGreen,
            foregroundColor: _convert ? _kCardDeep : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}

// ─── Error / empty views ──────────────────────────────────────────────────────

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
              style: ElevatedButton.styleFrom(backgroundColor: _kAdminAccent),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
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
                color: Colors.white.withOpacity(0.1), size: 72),
            const SizedBox(height: 16),
            Text('No active trips',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Accepted and in-progress trips from all drivers will appear here.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.28), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: _kAdminAccent, size: 18),
              label:
                  const Text('Refresh', style: TextStyle(color: _kAdminAccent)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kAdminAccent, width: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
