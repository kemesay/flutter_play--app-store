import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../core/config/square_runtime_config.dart';
import '../../../../../../core/utils/payment_card_utils.dart';
import '../../../../../../core/utils/payment_status_map.dart';
import '../../../../../../data/models/payment_detail_model.dart';
import '../../../../../../data/models/payment_method_type.dart';
import '../../../../../../data/models/square_payment_payload.dart';
import '../../../../../../providers/auth_provider.dart';
import '../../../../../../providers/payment_provider.dart';
import 'square_checkout_new_card_panel.dart';
import 'square_payment_info_banner.dart';

/// Floor height only while new-card Square flow is open.
const double kSquareNewCardPanelMinHeight = 240;

/// Square checkout: primary / saved wallet / new card (verify before consent).
class SquarePaymentMethodSection extends StatefulWidget {
  const SquarePaymentMethodSection({
    super.key,
    required this.paymentProvider,
    required this.paymentMethod,
    required this.selectedPaymentDetailId,
    required this.selectedSquareCardId,
    required this.onMethodChanged,
    required this.onSavedCardSelected,
    required this.verifiedSquarePayload,
    required this.squareTokenizedAtTotal,
    required this.bookingTotal,
    required this.onSquareVerified,
    required this.onSquareVerificationCleared,
    this.cardholderNameHint,
    this.billingZipHint,
    this.showTitle = false,
  });

  final PaymentProvider paymentProvider;
  final PaymentMethodType paymentMethod;
  final int? selectedPaymentDetailId;
  final String? selectedSquareCardId;
  final ValueChanged<PaymentMethodType> onMethodChanged;
  final ValueChanged<PaymentDetailModel> onSavedCardSelected;
  final SquarePaymentPayload? verifiedSquarePayload;
  final double? squareTokenizedAtTotal;
  final double? bookingTotal;
  final void Function(SquarePaymentPayload payload, double totalAtVerify)
  onSquareVerified;
  final VoidCallback onSquareVerificationCleared;
  final String? cardholderNameHint;
  final String? billingZipHint;
  final bool showTitle;

  @override
  State<SquarePaymentMethodSection> createState() =>
      _SquarePaymentMethodSectionState();
}

class _SquarePaymentMethodSectionState
    extends State<SquarePaymentMethodSection> {
  bool _defaultsApplied = false;
  bool _userOverrode = false;

  @override
  void didUpdateWidget(covariant SquarePaymentMethodSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeApplyDefaults();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeApplyDefaults());
  }

  void _maybeApplyDefaults() {
    if (_defaultsApplied || _userOverrode || !mounted) return;
    if (widget.paymentProvider.isLoading) return;

    final isLegacyDefault =
        widget.paymentMethod == PaymentMethodType.newCard ||
        widget.paymentMethod == PaymentMethodType.primaryCard ||
        widget.paymentMethod == PaymentMethodType.existingCard;

    if (!isLegacyDefault) {
      _defaultsApplied = true;
      return;
    }

    final primary = widget.paymentProvider.primarySquareCard;
    final cards = widget.paymentProvider.squareCards;
    if (primary != null) {
      _handleSavedCardSelected(primary, fromDefaults: true);
    } else if (cards.isNotEmpty) {
      _handleSavedCardSelected(cards.first, fromDefaults: true);
    } else {
      widget.onMethodChanged(PaymentMethodType.squareNewCard);
    }
    _defaultsApplied = true;
  }

  void _handleMethodChanged(PaymentMethodType method) {
    _userOverrode = true;
    widget.onMethodChanged(method);
  }

  void _handleSavedCardSelected(
    PaymentDetailModel card, {
    bool fromDefaults = false,
  }) {
    if (!fromDefaults) _userOverrode = true;
    widget.onMethodChanged(PaymentMethodType.squareSavedCard);
    widget.onSavedCardSelected(card);
  }

  @override
  Widget build(BuildContext context) {
    final paymentMode = context.select<SquareRuntimeConfig, String>(
      (c) => c.paymentMode,
    );
    final checkoutHint = getCheckoutPaymentHint(paymentMode: paymentMode);
    final savedCardHint = getSavedCardCheckoutHint(paymentMode: paymentMode);

    final auth = context.select<AuthProvider, bool>((a) => a.isAuthenticated);
    final squareCards = widget.paymentProvider.squareCards;
    final primary = widget.paymentProvider.primarySquareCard;
    final alternateCards = savedCardsForAlternateDropdown(
      squareCards,
      primary: primary,
    );
    final selectedCard = findSavedSquareCard(
      cards: squareCards,
      paymentDetailId: widget.selectedPaymentDetailId,
      squareCardId: widget.selectedSquareCardId,
    );
    final isPrimarySelected =
        widget.paymentMethod == PaymentMethodType.squareSavedCard &&
        primary != null &&
        selectedCard != null &&
        selectedCard.paymentDetailId == primary.paymentDetailId;
    final isNewCard = widget.paymentMethod == PaymentMethodType.squareNewCard;

    String? dropdownValue;
    if (widget.paymentMethod == PaymentMethodType.squareSavedCard &&
        selectedCard != null &&
        alternateCards.any(
          (c) =>
              savedCardSelectionKey(c) == savedCardSelectionKey(selectedCard),
        )) {
      dropdownValue = savedCardSelectionKey(selectedCard);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF03930A),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SquarePaymentInfoBanner(checkoutHint: checkoutHint),
        if (auth && widget.paymentProvider.isLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (auth &&
            !widget.paymentProvider.isLoading &&
            squareCards.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'No saved cards yet. Add one in Payment Methods, or pay with a new card below.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        if (auth && primary != null)
          _SquareMethodTile(
            title: 'Primary card',
            subtitle: formatSavedCardDropdownLabel(primary),
            selected: isPrimarySelected && !isNewCard,
            icon: Icons.star,
            onTap: () => _handleSavedCardSelected(primary),
          ),
        if (auth && alternateCards.isNotEmpty) ...[
          const SizedBox(height: 6),
          _SquareMethodTile(
            title: alternateCards.length == 1 && primary != null
                ? 'Another saved card'
                : 'Select saved card',
            subtitle: 'Pick from your wallet',
            selected:
                widget.paymentMethod == PaymentMethodType.squareSavedCard &&
                !isPrimarySelected,
            icon: Icons.credit_card,
            onTap: () {
              final card =
                  findSavedCardBySelectionKey(alternateCards, dropdownValue) ??
                  alternateCards.first;
              _handleSavedCardSelected(card);
            },
          ),
        ],
        const SizedBox(height: 6),
        _SquareMethodTile(
          title: 'Pay with a new card',
          subtitle: 'Billing + secure card entry',
          selected: isNewCard,
          icon: Icons.add_card,
          onTap: () => _handleMethodChanged(PaymentMethodType.squareNewCard),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: isNewCard ? kSquareNewCardPanelMinHeight : 0,
          ),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF03930A).withOpacity(0.25),
            ),
          ),
          child: _buildPanelBody(
            context,
            isNewCard: isNewCard,
            isPrimarySelected: isPrimarySelected,
            selectedCard: selectedCard,
            savedCardHint: savedCardHint,
          ),
        ),
      ],
    );
  }

  Widget _buildPanelBody(
    BuildContext context, {
    required bool isNewCard,
    required bool isPrimarySelected,
    required PaymentDetailModel? selectedCard,
    required String savedCardHint,
  }) {
    if (isNewCard) {
      return SquareCheckoutNewCardPanel(
        verifiedPayload: widget.verifiedSquarePayload,
        tokenizedAtTotal: widget.squareTokenizedAtTotal,
        bookingTotal: widget.bookingTotal,
        initialCardholderName: widget.cardholderNameHint,
        initialZip: widget.billingZipHint,
        onVerified: widget.onSquareVerified,
        onVerificationCleared: widget.onSquareVerificationCleared,
      );
    }

    if (widget.paymentMethod == PaymentMethodType.squareSavedCard &&
        isPrimarySelected &&
        selectedCard != null) {
      return _SavedCardCompactPanel(
        card: selectedCard,
        savedCardHint: savedCardHint,
        isPrimary: true,
      );
    }

    if (widget.paymentMethod == PaymentMethodType.squareSavedCard) {
      final cardsForPicker = widget.paymentProvider.squareCards;
      final pickValue = selectedCard != null
          ? savedCardSelectionKey(selectedCard)
          : (cardsForPicker.isNotEmpty
                ? savedCardSelectionKey(cardsForPicker.first)
                : null);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Pick a saved card',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (selectedCard != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03930A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ready',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF03930A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: pickValue,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'Select payment card',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
            ),
            isExpanded: true,
            items: cardsForPicker
                .map(
                  (card) => DropdownMenuItem<String>(
                    value: savedCardSelectionKey(card),
                    child: Text(
                      formatSavedCardDropdownLabel(card),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (key) {
              if (key == null) return;
              final card = findSavedCardBySelectionKey(cardsForPicker, key);
              if (card == null) return;
              _handleSavedCardSelected(card);
            },
          ),
          if (selectedCard != null) ...[
            const SizedBox(height: 6),
            _SavedCardCompactPanel(
              card: selectedCard,
              savedCardHint: savedCardHint,
              isPrimary: isPrimarySelected,
            ),
          ],
        ],
      );
    }

    return Center(
      child: Text(
        'Choose a payment option above.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SavedCardCompactPanel extends StatelessWidget {
  const _SavedCardCompactPanel({
    required this.card,
    required this.savedCardHint,
    required this.isPrimary,
  });

  final PaymentDetailModel card;
  final String savedCardHint;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final owner = card.cardOwnerName.trim();
    final expiry = formatSquareExpiry(card);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF03930A).withOpacity(0.14),
                const Color(0xFF03930A).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF03930A).withOpacity(0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.credit_card,
                  size: 22,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatSquareWalletCardNumber(card),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (owner.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        owner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (expiry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Exp $expiry',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03930A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Primary',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF03930A),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              size: 14,
              color: const Color(0xFF03930A).withOpacity(0.85),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                savedCardHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF03930A),
                  height: 1.3,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SquareMethodTile extends StatelessWidget {
  const _SquareMethodTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: selected
          ? const Color(0xFF03930A).withOpacity(0.1)
          : Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0xFF03930A) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Icon(icon, color: const Color(0xFF03930A), size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.2),
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Color(0xFF03930A))
            : null,
        onTap: onTap,
      ),
    );
  }
}
