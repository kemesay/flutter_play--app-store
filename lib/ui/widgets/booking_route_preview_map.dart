import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/distance_utils.dart';
import '../../model/place_model.dart';

const _brandGreen = Color(0xFF03930A);
const _kDefaultUsTarget = LatLng(39.8283, -98.5795);

/// Interactive Google Map with markers, driving polyline, and distance overlay.
class BookingRoutePreviewMap extends StatefulWidget {
  const BookingRoutePreviewMap({
    super.key,
    this.pickup,
    this.dropoff,
    this.routePolyline,
    this.distanceInMiles,
    this.durationText,
    this.height = 240,
    this.isLoading = false,
    this.pickupLabel = 'Pickup',
    this.dropoffLabel = 'Drop-off',
  });

  final PlaceDetail? pickup;
  final PlaceDetail? dropoff;
  final List<LatLng>? routePolyline;
  final double? distanceInMiles;
  final String? durationText;
  final double height;
  final bool isLoading;
  final String pickupLabel;
  final String dropoffLabel;

  @override
  State<BookingRoutePreviewMap> createState() => _BookingRoutePreviewMapState();
}

class _BookingRoutePreviewMapState extends State<BookingRoutePreviewMap> {
  GoogleMapController? _controller;
  MapType _mapType = MapType.normal;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BookingRoutePreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = widget.pickup != oldWidget.pickup ||
        widget.dropoff != oldWidget.dropoff ||
        widget.routePolyline != oldWidget.routePolyline;
    if (changed && _controller != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  LatLng? get _pickupLatLng {
    final p = widget.pickup;
    if (p == null) return null;
    return LatLng(p.lat, p.lng);
  }

  LatLng? get _dropoffLatLng {
    final d = widget.dropoff;
    if (d == null) return null;
    return LatLng(d.lat, d.lng);
  }

  bool get _hasBothPoints => _pickupLatLng != null && _dropoffLatLng != null;

  void _fitCamera() {
    final controller = _controller;
    if (controller == null) return;

    final polyline = widget.routePolyline;
    if (polyline != null && polyline.isNotEmpty) {
      var minLat = polyline.first.latitude;
      var maxLat = polyline.first.latitude;
      var minLng = polyline.first.longitude;
      var maxLng = polyline.first.longitude;
      for (final point in polyline) {
        minLat = minLat < point.latitude ? minLat : point.latitude;
        maxLat = maxLat > point.latitude ? maxLat : point.latitude;
        minLng = minLng < point.longitude ? minLng : point.longitude;
        maxLng = maxLng > point.longitude ? maxLng : point.longitude;
      }
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          64,
        ),
      );
      return;
    }

    if (_hasBothPoints) {
      final pickup = _pickupLatLng!;
      final dropoff = _dropoffLatLng!;
      final distance = widget.distanceInMiles ??
          haversineDistanceInMiles(
            startLat: pickup.latitude,
            startLng: pickup.longitude,
            endLat: dropoff.latitude,
            endLng: dropoff.longitude,
          );
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              (pickup.latitude + dropoff.latitude) / 2,
              (pickup.longitude + dropoff.longitude) / 2,
            ),
            zoom: _zoomForDistance(distance),
          ),
        ),
      );
    } else if (_pickupLatLng != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLatLng!, 13),
      );
    } else if (_dropoffLatLng != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_dropoffLatLng!, 13),
      );
    }
  }

  double _zoomForDistance(double distance) {
    if (distance < 5) return 13;
    if (distance < 15) return 12;
    if (distance < 35) return 10.5;
    if (distance < 80) return 9;
    if (distance < 150) return 8;
    return 6.5;
  }

  LatLng _initialTarget() {
    if (_hasBothPoints) {
      return LatLng(
        (_pickupLatLng!.latitude + _dropoffLatLng!.latitude) / 2,
        (_pickupLatLng!.longitude + _dropoffLatLng!.longitude) / 2,
      );
    }
    return _pickupLatLng ?? _dropoffLatLng ?? _kDefaultUsTarget;
  }

  double _initialZoom() {
    if (_hasBothPoints) {
      final distance = widget.distanceInMiles ??
          haversineDistanceInMiles(
            startLat: _pickupLatLng!.latitude,
            startLng: _pickupLatLng!.longitude,
            endLat: _dropoffLatLng!.latitude,
            endLng: _dropoffLatLng!.longitude,
          );
      return _zoomForDistance(distance);
    }
    if (_pickupLatLng != null || _dropoffLatLng != null) return 13;
    return 5;
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    if (_pickupLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: widget.pickupLabel,
            snippet: widget.pickup?.formattedAddress,
          ),
        ),
      );
    }
    if (_dropoffLatLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.dropoffLabel,
            snippet: widget.dropoff?.formattedAddress,
          ),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _polylines() {
    final polyline = widget.routePolyline;
    if (polyline != null && polyline.isNotEmpty) {
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polyline,
          color: _brandGreen,
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
    }
    if (_hasBothPoints) {
      return {
        Polyline(
          polylineId: const PolylineId('straight'),
          points: [_pickupLatLng!, _dropoffLatLng!],
          color: _brandGreen.withOpacity(0.45),
          width: 3,
          patterns: [PatternItem.dash(18), PatternItem.gap(10)],
        ),
      };
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final hasRoute = _hasBothPoints;
    final distanceLabel = widget.distanceInMiles != null
        ? '${widget.distanceInMiles!.toStringAsFixed(2)} mi'
        : '—';
    final durationLabel = widget.durationText ?? '—';

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasRoute)
              _EmptyMapPlaceholder(
                pickupLabel: widget.pickupLabel,
                dropoffLabel: widget.dropoffLabel,
              )
            else
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialTarget(),
                  zoom: _initialZoom(),
                ),
                mapType: _mapType,
                liteModeEnabled:
                    !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
                markers: _markers(),
                polylines: _polylines(),
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                compassEnabled: true,
                onMapCreated: (controller) {
                  _controller = controller;
                  Future.delayed(const Duration(milliseconds: 350), () {
                    if (mounted) _fitCamera();
                  });
                },
              ),
            if (widget.isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              top: 10,
              left: 10,
              child: _LiveRouteBadge(hasPolyline: widget.routePolyline?.isNotEmpty == true),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _MapTypeChip(
                value: _mapType,
                onChanged: (type) => setState(() => _mapType = type),
              ),
            ),
            if (hasRoute)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _RouteStatsBar(
                  distanceLabel: distanceLabel,
                  durationLabel: durationLabel,
                  pickupLabel: widget.pickupLabel,
                  dropoffLabel: widget.dropoffLabel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveRouteBadge extends StatelessWidget {
  const _LiveRouteBadge({required this.hasPolyline});

  final bool hasPolyline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hasPolyline ? Colors.lightGreenAccent : Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            hasPolyline ? 'LIVE ROUTE' : 'ESTIMATED',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTypeChip extends StatelessWidget {
  const _MapTypeChip({required this.value, required this.onChanged});

  final MapType value;
  final ValueChanged<MapType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapTypeButton(
            icon: Icons.map_outlined,
            selected: value == MapType.normal,
            onTap: () => onChanged(MapType.normal),
          ),
          _MapTypeButton(
            icon: Icons.satellite_alt_outlined,
            selected: value == MapType.hybrid,
            onTap: () => onChanged(MapType.hybrid),
          ),
        ],
      ),
    );
  }
}

class _MapTypeButton extends StatelessWidget {
  const _MapTypeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 20,
          color: selected ? _brandGreen : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _RouteStatsBar extends StatelessWidget {
  const _RouteStatsBar({
    required this.distanceLabel,
    required this.durationLabel,
    required this.pickupLabel,
    required this.dropoffLabel,
  });

  final String distanceLabel;
  final String durationLabel;
  final String pickupLabel;
  final String dropoffLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(icon: Icons.route, label: distanceLabel),
          const SizedBox(width: 10),
          _StatChip(icon: Icons.schedule, label: durationLabel),
          const Spacer(),
          Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$pickupLabel → $dropoffLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _brandGreen),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    );
  }
}

class _EmptyMapPlaceholder extends StatelessWidget {
  const _EmptyMapPlaceholder({
    required this.pickupLabel,
    required this.dropoffLabel,
  });

  final String pickupLabel;
  final String dropoffLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _brandGreen.withOpacity(0.08),
            Colors.grey.shade100,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: _brandGreen.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'Set $pickupLabel & $dropoffLabel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your driving route will appear here',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
