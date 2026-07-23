import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/square_runtime_config.dart';
import '../../../../core/utils/payment_card_utils.dart';
import '../../../../providers/payment_provider.dart';
import 'square_wallet_add_sheet.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final squareConfig = context.watch<SquareRuntimeConfig>();
    final squareEnabled = squareConfig.squareEnabled;
    final squareLoading = squareConfig.isLoading && !squareConfig.hasConfig;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MaterialButton(
                  onPressed: () => Navigator.of(context).pop(),
                  color: Theme.of(context).colorScheme.surface,
                  textColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  'Payment Methods',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!squareEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SquareUnavailableBanner(
                isLoading: squareLoading,
                lastError: squareConfig.lastError,
                onRetry: () => squareConfig.load(force: true),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: RefreshIndicator(
              onRefresh: paymentProvider.loadCards,
              child: paymentProvider.isLoading && paymentProvider.cards.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : paymentProvider.cards.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        Icon(
                          Icons.credit_card_off_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          squareEnabled
                              ? 'No saved cards yet. Tap Add Square card to save one securely.'
                              : 'Card wallet is unavailable until Square payments are configured.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: paymentProvider.cards.length,
                      itemBuilder: (context, index) {
                        final card = paymentProvider.cards[index];
                        final displayNumber = isSquareReadyCard(card)
                            ? formatSquareWalletCardNumber(card)
                            : card.maskedCardNumber;
                        final expiry = formatSquareExpiry(card);
                        return _PaymentCardTile(
                          cardNumber: displayNumber,
                          cardOwnerName: card.cardOwnerName,
                          expirationDate: expiry ?? card.expirationDate,
                          isPrimary: card.isPrimary,
                          isSquareCard: isSquareReadyCard(card),
                          onMakePrimary: () => context
                              .read<PaymentProvider>()
                              .setPrimary(card.paymentDetailId),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(squareEnabled ? 'Add Square card' : 'Add card'),
        onPressed: squareLoading
            ? null
            : () => _handleAddCard(context, squareEnabled: squareEnabled),
      ),
    );
  }

  Future<void> _handleAddCard(
    BuildContext context, {
    required bool squareEnabled,
  }) async {
    if (!squareEnabled) {
      await _showSquareUnavailableDialog(context);
      return;
    }

    final saved = await showSquareWalletAddSheet(context);
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card saved to your wallet'),
          backgroundColor: Color(0xFF03930A),
        ),
      );
    }
  }

  Future<void> _showSquareUnavailableDialog(BuildContext context) async {
    final squareConfig = context.read<SquareRuntimeConfig>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payments unavailable'),
        content: Text(
          squareConfig.lastError != null
              ? 'We could not load Square payment settings. '
                    'Adding a card requires  please try again in a moment.'
              : 'Adding a card requires  secure payments. '
                    'This service is not available right now — please try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await squareConfig.load(force: true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF03930A),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SquareUnavailableBanner extends StatelessWidget {
  const _SquareUnavailableBanner({
    required this.isLoading,
    required this.onRetry,
    this.lastError,
  });

  final bool isLoading;
  final Object? lastError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading
                        ? 'Loading Square payment settings…'
                        : 'Square wallet unavailable',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading
                        ? 'Please wait before adding a card.'
                        : 'Cards are saved securely with Square. '
                              'Raw card entry is no longer supported in the app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!isLoading)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PaymentCardTile extends StatelessWidget {
  const _PaymentCardTile({
    required this.cardNumber,
    required this.cardOwnerName,
    required this.expirationDate,
    required this.isPrimary,
    required this.onMakePrimary,
    this.isSquareCard = false,
  });

  final String cardNumber;
  final String cardOwnerName;
  final String expirationDate;
  final bool isPrimary;
  final bool isSquareCard;
  final VoidCallback onMakePrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      color: isPrimary
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    cardNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isPrimary
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.credit_card,
                  color: isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARDHOLDER',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isPrimary
                              ? colorScheme.onPrimary.withOpacity(0.85)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        cardOwnerName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isPrimary
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EXPIRY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isPrimary
                            ? colorScheme.onPrimary.withOpacity(0.85)
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      expirationDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isPrimary
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!isPrimary)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onMakePrimary,
                  child: const Text('Make primary'),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  avatar: Icon(Icons.star, color: colorScheme.onPrimary),
                  label: const Text('Primary card'),
                  backgroundColor: colorScheme.primaryContainer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
