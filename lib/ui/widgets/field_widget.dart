import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';

class Field extends StatelessWidget {
  const Field({
    super.key,
    required this.label,
    required this.value,
    this.direction = Axis.horizontal,
    this.padding,
  });

  /// The label text (e.g., "Pickup Date Time")
  final String label;

  /// The value to display. If it's a DateTime, it will be automatically
  /// formatted to Pacific timezone using formatDateToPacific
  final dynamic value;

  /// Layout direction: horizontal (label left, value right) or vertical (stacked)
  final Axis direction;

  /// Custom padding. Defaults to EdgeInsets.all(8)
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedValue = _formatValue(value);

    // Match website styling: backgroundColor: "#EEE", padding: 2, borderRadius: 2
    return Container(
      padding: padding ?? const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: direction == Axis.horizontal
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    formattedValue,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedValue,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';

    // If it's a DateTime, format to Pacific timezone (matches website)
    if (value is DateTime) {
      return formatDateToPacific(value);
    }

    // Convert to string
    return value.toString();
  }
}
