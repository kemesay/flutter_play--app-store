import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/utils/json_parsing.dart';
import '../../../data/services/driver_service.dart';
import '../../theme/app_tokens.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0F0F1A);
const _kCard = Color(0xFF16213E);
const _kCardDeep = Color(0xFF1A1A2E);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);
const _kPurple = Color(0xFFA78BFA);
const _kBlue = Color(0xFF60A5FA);
const _kRed = Color(0xFFDC2626);

class LiveMeterScreen extends StatefulWidget {
  const LiveMeterScreen({super.key, required this.bookingId});
  final int bookingId;

  @override
  State<LiveMeterScreen> createState() => _LiveMeterScreenState();
}

class _LiveMeterScreenState extends State<LiveMeterScreen> {
  final _service = DriverService();

  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _liveStatus;
  Map<String, dynamic>? _completedResult;

  bool _loadingBooking = true;
  bool _ending = false;
  String? _error;

  Timer? _clockTimer;
  Timer? _pollTimer;
  int _elapsedSeconds = 0;

  // ─── Derived mode ────────────────────────────────────────────────────────

  String get _mode => (_liveStatus?['mode'] as String?) ?? 'LIVE';
  bool get _isExtended => _mode == 'EXTENDED';
  bool get _isConverted => _mode == 'CONVERTED';
  bool get _isOvertime => (_liveStatus?['isOvertime'] == true) || _isExtended;

  Color get _clockColor => _isExtended
      ? _kPurple
      : _isOvertime
          ? _kAmber
          : const Color(0xFF34D399);

  String get _meterLabel => _isExtended
      ? 'EXTENSION RUNNING'
      : _isOvertime
          ? 'OVERTIME RUNNING'
          : 'METER RUNNING';

  // ─── Init ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final booking = await _service.getBooking(widget.bookingId);
      final status = await _service.getLiveStatus(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _liveStatus = status;
        _loadingBooking = false;
      });
      if (_isExtended) {
        // The clock shows the TOTAL trip time — it starts from the booked
        // hours already used under the fixed rate, then keeps ticking up
        // through the extension (computed fresh below), instead of
        // resetting to zero.
        final bookedHours = asDouble(booking['selectedHours']);
        _startClockFrom(
          booking['liveExtensionStartedAt'] ?? status['liveExtensionStartedAt'],
          baseOffsetSeconds: (bookedHours * 3600).round(),
        );
      } else {
        _startClockFrom(booking['actualStartTime']);
      }
      _pollTimer =
          Timer.periodic(const Duration(seconds: 15), (_) => _pollStatus());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingBooking = false;
      });
    }
  }

  void _startClockFrom(dynamic startTimeRaw, {int baseOffsetSeconds = 0}) {
    if (startTimeRaw == null) return;
    final start = DateTime.tryParse(startTimeRaw.toString());
    if (start == null) return;
    final sinceStart = DateTime.now().difference(start).inSeconds;
    _elapsedSeconds = (baseOffsetSeconds + sinceStart).clamp(0, 999999);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _pollStatus() async {
    try {
      final status = await _service.getLiveStatus(widget.bookingId);
      if (mounted) setState(() => _liveStatus = status);
    } catch (_) {}
  }

  // ─── End trip ─────────────────────────────────────────────────────────────

  Future<void> _endTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Trip?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          _isExtended
              ? 'This will stop the extension meter, finalize the extension fare, and complete the trip.'
              : 'This will stop the live meter, calculate overtime if any, and finalize payment.',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('End & Finalize',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _ending = true);
    _clockTimer?.cancel();
    _pollTimer?.cancel();

    try {
      final result = await _service.endTrip(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _completedResult = result;
        _ending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _ending = false;
      });
    }
  }

  // ─── Formatters ───────────────────────────────────────────────────────────

  String _formatClock() {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtMinutes(int? minutes) {
    if (minutes == null) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  double get _progressPct {
    if (_isExtended) return 1.0;
    final booked = asDouble(_booking?['selectedHours'], 1);
    final elapsed = asDouble(_liveStatus?['elapsedHoursRaw']);
    return (elapsed / booked).clamp(0.0, 1.0);
  }

  /// Booked hours + extension time so far, in minutes — the same continuous
  /// total the clock card shows, for the progress/stats labels.
  int? get _extendedTotalMinutes {
    final fromApi = asNum(_liveStatus?['totalElapsedMinutes'])?.toInt();
    if (fromApi != null) return fromApi;
    final bookedHours = asNum(_booking?['selectedHours'])?.toDouble();
    final extMinutes = asNum(_liveStatus?['extensionMinutes'])?.toInt();
    if (bookedHours == null || extMinutes == null) return null;
    return (bookedHours * 60).round() + extMinutes;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white54, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _clockColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.speed, color: _clockColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _isExtended ? 'Live Extension' : 'Live Meter',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ],
        ),
      ),
      body: _loadingBooking
          ? const Center(child: CircularProgressIndicator(color: _kAmber))
          : _error != null && _completedResult == null
              ? _ErrorCard(error: _error!, onRetry: _init)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_completedResult != null) ...[
                        _CompletedBanner(result: _completedResult!),
                        const SizedBox(height: AppSpacing.md),
                        _BackButton(onBack: () => Navigator.pop(context)),
                      ],
                      if (_completedResult == null) ...[
                        // ── Mode indicator / converted badge ────────────
                        if (_isConverted) _ConvertedBadge(),
                        if (_isConverted) const SizedBox(height: 12),

                        // ── Base fare row for extended mode ─────────────
                        if (_isExtended && _booking != null) ...[
                          _BaseFareRow(
                            baseFare: asDouble(_liveStatus?['baseFare']),
                            bookedHours: _booking!['selectedHours'],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Clock card ──────────────────────────────────
                        _ClockCard(
                          clock: _formatClock(),
                          label: _meterLabel,
                          clockColor: _clockColor,
                          borderColor: _clockColor,
                          gradientColors: _isExtended
                              ? const [Color(0xFF2E1065), Color(0xFF3B0764)]
                              : _isOvertime
                                  ? const [Color(0xFF78350F), Color(0xFF92400E)]
                                  : const [_kCardDeep, _kCard],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ── Progress card ───────────────────────────────
                        _ProgressCard(
                          progressPct: _progressPct,
                          elapsedLabel: _fmtMinutes(
                            _isExtended
                                ? _extendedTotalMinutes
                                : asNum(_liveStatus?['elapsedMinutes'])
                                    ?.toInt(),
                          ),
                          bookedHours: _booking?['selectedHours'],
                          isExtended: _isExtended,
                          isOvertime: _isOvertime,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // ── Stats row ───────────────────────────────────
                        _StatsRow(
                          liveStatus: _liveStatus,
                          booking: _booking!,
                          isExtended: _isExtended,
                          fmtMinutes: _fmtMinutes,
                        ),

                        // ── Extension fare row ──────────────────────────
                        if (_isExtended) ...[
                          const SizedBox(height: 12),
                          _ExtensionFareRow(
                            extensionFare:
                                asDouble(_liveStatus?['extensionFare']),
                            runningFare: asDouble(_liveStatus?['runningFare']),
                          ),
                        ],

                        // ── Overtime banner (standard) ──────────────────
                        if (_isOvertime && !_isExtended) ...[
                          const SizedBox(height: AppSpacing.md),
                          _OvertimeBanner(liveStatus: _liveStatus!),
                        ],

                        const SizedBox(height: AppSpacing.lg),
                        _EndTripButton(ending: _ending, onEnd: _endTrip),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ConvertedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz, color: _kBlue, size: 18),
          const SizedBox(width: 10),
          Text(
            'Converted from fixed rate to live meter at trip start',
            style: TextStyle(color: _kBlue.withOpacity(0.9), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BaseFareRow extends StatelessWidget {
  const _BaseFareRow({required this.baseFare, required this.bookedHours});
  final double baseFare;
  final dynamic bookedHours;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: _kPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original fixed fare (locked in)',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45), fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                    '\$${baseFare.toStringAsFixed(2)} · ${bookedHours}h booked',
                    style: const TextStyle(
                        color: _kPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ],
            ),
          ),
          const Icon(Icons.receipt_long, color: Colors.white24, size: 18),
        ],
      ),
    );
  }
}

class _ExtensionFareRow extends StatelessWidget {
  const _ExtensionFareRow(
      {required this.extensionFare, required this.runningFare});
  final double extensionFare;
  final double runningFare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kPurple.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kPurple.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Extension fare (so far)',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 11)),
              Text('+\$${extensionFare.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _kPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Total est.',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 11)),
              Text('\$${runningFare.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.clock,
    required this.label,
    required this.clockColor,
    required this.borderColor,
    required this.gradientColors,
  });
  final String clock;
  final String label;
  final Color clockColor;
  final Color borderColor;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: borderColor.withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2)
        ],
      ),
      child: Column(
        children: [
          Text(
            clock,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: clockColor,
              letterSpacing: 4,
              height: 1,
              shadows: [
                Shadow(color: clockColor.withOpacity(0.6), blurRadius: 20)
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: clockColor,
                  boxShadow: [
                    BoxShadow(color: clockColor.withOpacity(0.8), blurRadius: 8)
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progressPct,
    required this.elapsedLabel,
    required this.bookedHours,
    required this.isExtended,
    required this.isOvertime,
  });
  final double progressPct;
  final String elapsedLabel;
  final dynamic bookedHours;
  final bool isExtended;
  final bool isOvertime;

  Color get _barColor => isExtended
      ? _kPurple
      : isOvertime
          ? _kAmber
          : _kGreen;
  String get _badge => isExtended
      ? 'LIVE EXT'
      : isOvertime
          ? 'OVERTIME'
          : '${(progressPct * 100).toStringAsFixed(0)}%';
  Color get _badgeColor => isExtended
      ? _kPurple
      : isOvertime
          ? const Color(0xFFFCD34D)
          : const Color(0xFF6EE7B7);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trip Progress',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _barColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_badge,
                    style: TextStyle(
                        color: _badgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExtended ? 'Total: $elapsedLabel' : 'Elapsed: $elapsedLabel',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              Text('Booked: ${bookedHours}h',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.liveStatus,
    required this.booking,
    required this.isExtended,
    required this.fmtMinutes,
  });
  final Map<String, dynamic>? liveStatus;
  final Map<String, dynamic> booking;
  final bool isExtended;
  final String Function(int?) fmtMinutes;

  @override
  Widget build(BuildContext context) {
    final runningFare = asDouble(liveStatus?['runningFare']);
    final elapsedLabel = isExtended
        ? fmtMinutes(asNum(liveStatus?['totalElapsedMinutes'])?.toInt())
        : fmtMinutes(asNum(liveStatus?['elapsedMinutes'])?.toInt());

    return Row(
      children: [
        Expanded(
            child: _StatCard(
                icon: Icons.access_time,
                iconColor: _kAmber,
                label: 'Booked',
                value: '${booking['selectedHours']}h')),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                icon: Icons.attach_money,
                iconColor: _kBlue,
                label: isExtended ? 'Total Est.' : 'Running Fare',
                value: '\$${runningFare.toStringAsFixed(2)}')),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                icon: Icons.timer,
                iconColor: _kGreen,
                label: isExtended ? 'Total Time' : 'Elapsed',
                value: elapsedLabel)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

class _OvertimeBanner extends StatelessWidget {
  const _OvertimeBanner({required this.liveStatus});
  final Map<String, dynamic> liveStatus;

  @override
  Widget build(BuildContext context) {
    final otHours = asDouble(liveStatus['overtimeHours']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmber.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _kAmber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Past booked hours — ${otHours.toStringAsFixed(2)}h over',
                    style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text('Extra time billed at the same normal hourly rate',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndTripButton extends StatelessWidget {
  const _EndTripButton({required this.ending, required this.onEnd});
  final bool ending;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: ending ? null : onEnd,
        icon: ending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.stop_circle_outlined, size: 22),
        label: Text(ending ? 'Finalizing Billing…' : 'End Trip & Finalize',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          disabledBackgroundColor: _kRed.withOpacity(0.5),
          disabledForegroundColor: Colors.white54,
        ),
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final total = asDouble(result['totalTripFeeInDollars']);
    final otHours = asDouble(result['overtimeHours']);
    final otAmount = asDouble(result['overtimeAmountInDollars']);
    final baseFare = asDouble(result['liveExtensionBaseFare']);
    final extFare = asDouble(result['liveExtensionFareInDollars']);
    final isExtended = result['liveExtensionStartedAt'] != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF065F46), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF6EE7B7), size: 56),
          const SizedBox(height: 12),
          const Text('Trip Completed',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const SizedBox(height: AppSpacing.xs),
          Text('Payment finalized and reconciled',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 13)),

          // Extension breakdown
          if (isExtended && extFare > 0) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ResultChip(
                    label: 'Base  \$${baseFare.toStringAsFixed(2)}',
                    color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: AppSpacing.sm),
                _ResultChip(
                    label: '+Ext  \$${extFare.toStringAsFixed(2)}',
                    color: _kPurple),
              ],
            ),
          ],

          // Overtime breakdown
          if (!isExtended && otHours > 0) ...[
            const SizedBox(height: 14),
            _ResultChip(
              label:
                  '+${otHours.toStringAsFixed(2)}h past booked hours  (+\$${otAmount.toStringAsFixed(2)})',
              color: const Color(0xFFFCD34D),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Text('Total Charged',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: AppSpacing.xs),
          Text('\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 42)),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Back to Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCardDeep, _kCard],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});
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
