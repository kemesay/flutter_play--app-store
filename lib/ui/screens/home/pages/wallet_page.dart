import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/card_validation_utils.dart';
import '../../../../data/models/card_details.dart';
import '../../../../providers/payment_provider.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Header with back arrow
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                MaterialButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  color: Theme.of(context).colorScheme.surface,
                  textColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Payment Methods",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
              ],
            ),
          ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: paymentProvider.loadCards,
              child: paymentProvider.isLoading && paymentProvider.cards.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: paymentProvider.cards.length,
                      itemBuilder: (context, index) {
                        final card = paymentProvider.cards[index];
                        return _PaymentCardTile(
                          cardNumber: card.maskedCardNumber,
                          cardOwnerName: card.cardOwnerName,
                          expirationDate: card.expirationDate,
                          isPrimary: card.isPrimary,
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
        label: const Text('Add card'),
        onPressed: () => _showAddCardSheet(context),
      ),
    );
  }

  Future<void> _showAddCardSheet(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final cardNameController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final zipController = TextEditingController();
    bool isPrimary = false;
    CardBrand cardBrand = CardBrand.unknown;
    bool isValidating = false;
    bool isValidated = false;
    String? validationError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              void clearValidationState() {
                if (isValidated || validationError != null) {
                  setState(() {
                    isValidated = false;
                    validationError = null;
                  });
                }
              }

              Future<void> handleValidateAndSave() async {
                if (!formKey.currentState!.validate()) return;

                final cardDetails = CardDetails(
                  creditCardNumber: cardNumberController.text
                      .replaceAll(RegExp(r'\s+'), '')
                      .trim(),
                  cardOwnerName: cardNameController.text.trim(),
                  expirationDate: expiryController.text.trim(),
                  securityCode: cvvController.text.trim(),
                  zipCode: zipController.text.trim(),
                  isPrimary: isPrimary,
                );

                // Client-side validation
                if (cardDetails.creditCardNumber.isEmpty ||
                    cardDetails.cardOwnerName.isEmpty ||
                    cardDetails.expirationDate.isEmpty ||
                    cardDetails.securityCode.isEmpty ||
                    cardDetails.zipCode.isEmpty) {
                  setState(() {
                    validationError = 'All card fields are required';
                    isValidated = false;
                  });
                  return;
                }

                setState(() {
                  isValidating = true;
                  validationError = null;
                  isValidated = false;
                });

                try {
                  final paymentProvider = context.read<PaymentProvider>();
                  final success = await paymentProvider.addCard(cardDetails);

                  if (success && context.mounted) {
                    setState(() {
                      isValidating = false;
                      isValidated = true;
                      validationError = null;
                    });

                    // Show success message and close after a brief delay
                    await Future.delayed(const Duration(milliseconds: 500));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Card validated and saved successfully!',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF03930A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          margin: const EdgeInsets.all(16.0),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } else if (context.mounted) {
                    setState(() {
                      isValidating = false;
                      isValidated = false;
                      validationError = paymentProvider.errorMessage ??
                          'Card validation failed. Please check your card details.';
                    });
                  }
                } catch (e) {
                  if (context.mounted) {
                    setState(() {
                      isValidating = false;
                      isValidated = false;
                      validationError =
                          'Card validation failed: ${e.toString()}';
                    });
                  }
                }
              }

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Payment Card',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Validate and save new card for future use',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: cardNameController,
                        decoration: const InputDecoration(
                          labelText: 'Name on card',
                        ),
                        onChanged: (_) => clearValidationState(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the cardholder name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(23),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Card number',
                        ),
                        onChanged: (value) {
                          final formatted = formatCardNumber(value);
                          if (formatted != value) {
                            final selection = TextSelection.collapsed(
                                offset: formatted.length);
                            cardNumberController.value = TextEditingValue(
                                text: formatted, selection: selection);
                          }
                          setState(() {
                            cardBrand = detectCardBrand(value);
                          });
                          clearValidationState();
                        },
                        validator: validateCardNumber,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                                detectCardBrand(cardNumberController.text)
                                    .label),
                            avatar: const Icon(Icons.credit_card, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CVV: ${cvvExpectedLength(cardBrand)} digits',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: Theme.of(context).hintColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              decoration: const InputDecoration(
                                labelText: 'Expiry (MM/YY)',
                              ),
                              inputFormatters: [
                                expiryInputFormatter(),
                                LengthLimitingTextInputFormatter(5),
                              ],
                              onChanged: (value) {
                                final formatted = formatExpiryInput(value);
                                if (formatted != value) {
                                  final selection = TextSelection.collapsed(
                                      offset: formatted.length);
                                  expiryController.value = TextEditingValue(
                                    text: formatted,
                                    selection: selection,
                                  );
                                }
                                clearValidationState();
                              },
                              validator: validateExpiry,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'CVV',
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: (_) => clearValidationState(),
                              validator: (value) => validateCvv(value,
                                  detectCardBrand(cardNumberController.text)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: zipController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          zipInputFormatter(),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'ZIP code',
                        ),
                        onChanged: (_) => clearValidationState(),
                        validator: validateZip,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isPrimary,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => isPrimary = value);
                          }
                        },
                        title: const Text('Set as primary card'),
                        subtitle: const Text(
                          'This card will be used as your default payment method',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      if (validationError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  validationError!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isValidated) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Card validated and saved successfully!',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              isValidating ? null : handleValidateAndSave,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: const Color(0xFF03930A),
                          ),
                          child: isValidating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Validate & Save Card',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
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
  });

  final String cardNumber;
  final String cardOwnerName;
  final String expirationDate;
  final bool isPrimary;
  final VoidCallback onMakePrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 16),
      color:
          isPrimary ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  cardNumber,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isPrimary
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                ),
                Icon(
                  Icons.credit_card,
                  color:
                      isPrimary ? colorScheme.onPrimary : colorScheme.primary,
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CARDHOLDER'),
                    Text(
                      cardOwnerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isPrimary
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EXPIRY'),
                    Text(
                      expirationDate,
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
