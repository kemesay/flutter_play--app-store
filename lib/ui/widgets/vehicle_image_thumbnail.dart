import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/utils/media_url_resolver.dart';

const _brandGreen = Color(0xFF03930A);

/// Compact, high-quality vehicle photo for horizontal pickers and cards.
class VehicleImageThumbnail extends StatelessWidget {
  const VehicleImageThumbnail({
    super.key,
    required this.imageUrl,
    this.height = 96,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(14)),
    this.fallbackLabel,
  });

  final String? imageUrl;
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMediaUrl(imageUrl);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cacheWidth = (width == double.infinity ? 280.0 : width) * pixelRatio;

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: width,
        child: resolved != null
            ? CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                memCacheWidth: cacheWidth.round(),
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, __) => const _VehicleImageSkeleton(),
                errorWidget: (_, __, ___) =>
                    _VehicleImagePlaceholder(label: fallbackLabel),
              )
            : _VehicleImagePlaceholder(label: fallbackLabel),
      ),
    );
  }
}

class _VehicleImageSkeleton extends StatelessWidget {
  const _VehicleImageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: _brandGreen),
        ),
      ),
    );
  }
}

class _VehicleImagePlaceholder extends StatelessWidget {
  const _VehicleImagePlaceholder({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _brandGreen.withOpacity(0.12),
            Colors.grey.shade100,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_filled_outlined,
            size: 36,
            color: _brandGreen.withOpacity(0.7),
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
