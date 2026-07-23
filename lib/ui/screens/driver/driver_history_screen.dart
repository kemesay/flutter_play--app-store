import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/json_parsing.dart';
import '../../../data/services/driver_service.dart';
import '../../theme/app_tokens.dart';

// ─── Palette (matches driver_home_screen.dart / live_meter_screen.dart) ───────

const _kBg = Color(0xFF0F0F1A);
const _kCard = Color(0xFF16213E);
const _kCardDeep = Color(0xFF1A1A2E);
const _kAmber = Color(0xFFF59E0B);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFDC2626);
const _kMuted = Color(0xFF94A3B8);

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  final _service = DriverService();
  final _trips = <Map<String, dynamic>>[];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _pageNumber = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadPage(1, replace: true);
  }

  bool get _hasMore => _pageNumber < _totalPages;

  Future<void> _loadPage(int page, {bool replace = false}) async {
    setState(() {
      if (replace) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final result = await _service.getTripHistory(page: page);
      final data = (result['data'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        if (replace) _trips.clear();
        _trips.addAll(data.whereType<Map<String, dynamic>>());
        _pageNumber = asInt(result['pageNumber'], page);
        _totalPages = asInt(result['totalPages'], 1);
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _refresh() => _loadPage(1, replace: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        title: const Text('Trip History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: _kAmber,
        backgroundColor: _kCard,
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kAmber))
            : _error != null && _trips.isEmpty
                ? _ErrorView(error: _error!, onRetry: _refresh)
                : _trips.isEmpty
                    ? const _EmptyView()
                    : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!_loadingMore &&
            _hasMore &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _loadPage(_pageNumber + 1);
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _trips.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _trips.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                  child: CircularProgressIndicator(
                      color: _kAmber, strokeWidth: 2)),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(trip: _trips[index]),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.trip});
  final Map<String, dynamic> trip;

  ({String label, Color color}) get _statusStyle {
    switch (trip['bookingStatus']) {
      case 'COMPLETED':
        return (label: 'Completed', color: _kGreen);
      case 'CANCELLED':
        return (label: 'Cancelled', color: _kRed);
      case 'REJECTED':
        return (label: 'Rejected', color: _kRed);
      default:
        return (label: '${trip['bookingStatus']}', color: _kMuted);
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return raw.toString();
    return DateFormat('MMM d, yyyy · h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final car = trip['Car'] as Map<String, dynamic>?;
    final status = _statusStyle;
    final fee = asDouble(trip['totalTripFeeInDollars']);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kCardDeep, _kCard],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                    color: status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(status.label,
                      style: TextStyle(
                          color: status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),
            const SizedBox(height: 12),
            _AddressRow(
                icon: Icons.location_on,
                color: _kAmber,
                label: 'Pickup',
                address: trip['pickupPhysicalAddress'] ?? '—'),
            const SizedBox(height: AppSpacing.sm),
            _AddressRow(
                icon: Icons.location_on,
                color: _kMuted,
                label: 'Dropoff',
                address: trip['dropoffPhysicalAddress'] ?? '—'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(trip['pickupDateTime']),
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
                Text('\$${fee.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow(
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

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
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history,
                      color: Colors.white.withOpacity(0.12), size: 72),
                  const SizedBox(height: AppSpacing.md),
                  Text('No trip history yet',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Completed, cancelled, or rejected trips will appear here.',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
