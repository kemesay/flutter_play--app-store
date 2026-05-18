import 'package:flutter/material.dart';

import '../../data/models/extra_option_model.dart';
import '../../data/models/selected_extra_option.dart';

const _brandGreen = Color(0xFF03930A);

class ExtraOptionsSelector extends StatefulWidget {
  const ExtraOptionsSelector({
    super.key,
    required this.extraOptions,
    required this.selectedOptions,
    required this.onChanged,
    this.originallyBookedIds = const {},
    this.highlightOriginalBooking = false,
  });

  final List<ExtraOptionModel> extraOptions;
  final List<SelectedExtraOption> selectedOptions;
  final ValueChanged<List<SelectedExtraOption>> onChanged;

  /// Extra option IDs that were on the booking when the user opened edit mode.
  final Set<int> originallyBookedIds;

  /// When true, shows a summary banner for originally booked add-ons (update flow).
  final bool highlightOriginalBooking;

  @override
  State<ExtraOptionsSelector> createState() => _ExtraOptionsSelectorState();
}

class _ExtraOptionsSelectorState extends State<ExtraOptionsSelector> {
  void _toggleOption(ExtraOptionModel option) {
    final options = List<SelectedExtraOption>.from(widget.selectedOptions);
    final index = options
        .indexWhere((e) => e.extraOptionId == option.extraOptionId);
    if (index >= 0) {
      options.removeAt(index);
    } else {
      options.add(
        SelectedExtraOption(extraOptionId: option.extraOptionId, quantity: 1),
      );
    }
    widget.onChanged(options);
  }

  void _editQuantity(ExtraOptionModel option) {
    final current = widget.selectedOptions.firstWhere(
      (e) => e.extraOptionId == option.extraOptionId,
      orElse: () =>
          SelectedExtraOption(extraOptionId: option.extraOptionId, quantity: 1),
    );
    final maxQuantity = option.hasMaxAllowedLimit
        ? ((option.maxAllowedItems != null && option.maxAllowedItems! > 0)
            ? option.maxAllowedItems
            : 1)
        : null;
    var quantity = current.quantity < 1 ? 1 : current.quantity;
    if (maxQuantity != null && quantity > maxQuantity) {
      quantity = maxQuantity;
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(option.description),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => modalSetState(() => quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        onPressed:
                            maxQuantity == null || quantity < maxQuantity
                                ? () => modalSetState(() => quantity++)
                                : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandGreen,
                      ),
                      onPressed: () {
                        final options = List<SelectedExtraOption>.from(
                          widget.selectedOptions,
                        );
                        final index = options.indexWhere(
                          (e) => e.extraOptionId == option.extraOptionId,
                        );
                        final selection = SelectedExtraOption(
                          extraOptionId: option.extraOptionId,
                          quantity: quantity,
                        );
                        if (index >= 0) {
                          options[index] = selection;
                        } else {
                          options.add(selection);
                        }
                        widget.onChanged(options);
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  int? _quantityFor(int extraOptionId) {
    for (final e in widget.selectedOptions) {
      if (e.extraOptionId == extraOptionId) return e.quantity;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.extraOptions.isEmpty) return const SizedBox.shrink();

    final originalCount = widget.originallyBookedIds.length;
    final activeOriginalCount = widget.extraOptions
        .where(
          (o) =>
              widget.originallyBookedIds.contains(o.extraOptionId) &&
              widget.selectedOptions
                  .any((s) => s.extraOptionId == o.extraOptionId),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.add_box_outlined, color: _brandGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              'Extra options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _brandGreen,
                  ),
            ),
          ],
        ),
        if (widget.highlightOriginalBooking && originalCount > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _brandGreen.withOpacity(0.18),
                  _brandGreen.withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _brandGreen.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _brandGreen.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bookmark_added,
                    size: 18,
                    color: _brandGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$originalCount add-on${originalCount == 1 ? '' : 's'} from your '
                    'original booking — highlighted in green below.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (activeOriginalCount < originalCount)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${originalCount - activeOriginalCount} off',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        ...widget.extraOptions.map((option) {
          final isSelected = widget.selectedOptions
              .any((e) => e.extraOptionId == option.extraOptionId);
          final qty = _quantityFor(option.extraOptionId);
          final wasOnOriginalBooking =
              widget.originallyBookedIds.contains(option.extraOptionId);

          return _ExtraOptionCard(
            option: option,
            isSelected: isSelected,
            quantity: qty,
            wasOnOriginalBooking: wasOnOriginalBooking,
            highlightOriginalBooking: widget.highlightOriginalBooking,
            onToggle: () => _toggleOption(option),
            onEditQuantity: () => _editQuantity(option),
          );
        }),
      ],
    );
  }
}

class _ExtraOptionCard extends StatelessWidget {
  const _ExtraOptionCard({
    required this.option,
    required this.isSelected,
    required this.quantity,
    required this.wasOnOriginalBooking,
    required this.highlightOriginalBooking,
    required this.onToggle,
    required this.onEditQuantity,
  });

  final ExtraOptionModel option;
  final bool isSelected;
  final int? quantity;
  final bool wasOnOriginalBooking;
  final bool highlightOriginalBooking;
  final VoidCallback onToggle;
  final VoidCallback onEditQuantity;

  bool get _showOriginalHighlight =>
      highlightOriginalBooking && wasOnOriginalBooking;

  bool get _showActiveOriginalStyle => _showOriginalHighlight && isSelected;

  bool get _showRemovedOriginalStyle => _showOriginalHighlight && !isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    BoxDecoration decoration;
    Color titleColor;
    Color subtitleColor;

    if (_showActiveOriginalStyle) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _brandGreen,
            _brandGreen.withOpacity(0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
      titleColor = Colors.white;
      subtitleColor = Colors.white.withOpacity(0.9);
    } else if (_showRemovedOriginalStyle) {
      decoration = BoxDecoration(
        color: _brandGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _brandGreen.withOpacity(0.45),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      );
      titleColor = _brandGreen;
      subtitleColor = Colors.grey.shade700;
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: _brandGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGreen.withOpacity(0.5)),
      );
      titleColor = _brandGreen;
      subtitleColor = Colors.grey.shade700;
    } else {
      decoration = BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      );
      titleColor = theme.colorScheme.onSurface;
      subtitleColor = Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelected ? onEditQuantity : onToggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: decoration,
            child: Stack(
              children: [
                if (_showActiveOriginalStyle)
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.local_offer_outlined,
                      size: 88,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SelectionIndicator(
                        isSelected: isSelected,
                        isOriginalActive: _showActiveOriginalStyle,
                        isOriginalRemoved: _showRemovedOriginalStyle,
                        onTap: onToggle,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_showOriginalHighlight)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: _OriginalBookingBadge(
                                  isActive: isSelected,
                                ),
                              ),
                            Text(
                              option.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '\$${option.pricePerItem.toStringAsFixed(2)} each',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _showActiveOriginalStyle
                                    ? Colors.white.withOpacity(0.95)
                                    : _brandGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        _QuantityChip(
                          quantity: quantity ?? 1,
                          onTap: onEditQuantity,
                          inverted: _showActiveOriginalStyle,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OriginalBookingBadge extends StatelessWidget {
  const _OriginalBookingBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withOpacity(0.22)
            : _brandGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.white.withOpacity(0.4)
              : _brandGreen.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history_edu,
            size: 12,
            color: isActive ? Colors.white : _brandGreen,
          ),
          const SizedBox(width: 4),
          Text(
            'On original booking',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isActive ? Colors.white : _brandGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.isSelected,
    required this.isOriginalActive,
    required this.isOriginalRemoved,
    required this.onTap,
  });

  final bool isSelected;
  final bool isOriginalActive;
  final bool isOriginalRemoved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? (isOriginalActive ? Colors.white : _brandGreen)
              : Colors.transparent,
          border: Border.all(
            color: isOriginalActive
                ? Colors.white
                : isOriginalRemoved
                    ? _brandGreen
                    : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                size: 18,
                color: isOriginalActive ? _brandGreen : Colors.white,
              )
            : isOriginalRemoved
                ? Icon(Icons.restore, size: 16, color: _brandGreen.withOpacity(0.7))
                : null,
      ),
    );
  }
}

class _QuantityChip extends StatelessWidget {
  const _QuantityChip({
    required this.quantity,
    required this.onTap,
    required this.inverted,
  });

  final int quantity;
  final VoidCallback onTap;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: inverted ? Colors.white.withOpacity(0.2) : _brandGreen.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 14,
                color: inverted ? Colors.white : _brandGreen,
              ),
              const SizedBox(width: 4),
              Text(
                '×$quantity',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: inverted ? Colors.white : _brandGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
