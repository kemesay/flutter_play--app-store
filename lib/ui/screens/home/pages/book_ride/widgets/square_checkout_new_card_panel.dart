import 'package:flutter/material.dart';

import '../../../../../../core/utils/booking_square_payment.dart';
import '../../../../../../data/models/square_payment_payload.dart';
import 'square_step_label.dart';

/// Billing + Square verify step (oda-ride-transport [SquarePaymentForm]).
class SquareCheckoutNewCardPanel extends StatefulWidget {
  const SquareCheckoutNewCardPanel({
    super.key,
    required this.verifiedPayload,
    required this.tokenizedAtTotal,
    required this.bookingTotal,
    required this.onVerified,
    required this.onVerificationCleared,
    this.initialCardholderName,
    this.initialZip,
  });

  final SquarePaymentPayload? verifiedPayload;
  final double? tokenizedAtTotal;
  final double? bookingTotal;
  final void Function(SquarePaymentPayload payload, double totalAtVerify)
      onVerified;
  final VoidCallback onVerificationCleared;
  final String? initialCardholderName;
  final String? initialZip;

  @override
  State<SquareCheckoutNewCardPanel> createState() =>
      _SquareCheckoutNewCardPanelState();
}

class _SquareCheckoutNewCardPanelState extends State<SquareCheckoutNewCardPanel> {
  late final TextEditingController _nameController;
  late final TextEditingController _zipController;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialCardholderName?.trim() ?? '',
    );
    _zipController = TextEditingController(
      text: widget.initialZip?.trim() ?? '',
    );
  }

  @override
  void didUpdateWidget(SquareCheckoutNewCardPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final name = widget.initialCardholderName?.trim();
    if (name != null &&
        name.isNotEmpty &&
        _nameController.text.trim().isEmpty) {
      _nameController.text = name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  String? _validateBilling() {
    final name = _nameController.text.trim();
    final zip = _zipController.text.trim();
    if (name.length < 2) {
      return 'Cardholder name is required';
    }
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(zip)) {
      return 'Enter a valid US ZIP code';
    }
    return null;
  }

  void _invalidateVerification() {
    if (widget.verifiedPayload != null) {
      widget.onVerificationCleared();
    }
  }

  Future<void> _verifyCard() async {
    final validationError = _validateBilling();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final total = widget.bookingTotal;
    if (total == null || total <= 0) {
      setState(() => _error = 'Complete trip pricing before verifying your card.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final payload = await tokenizeSquareCheckoutCard(context);
      if (!mounted) return;
      widget.onVerified(payload, total);
      setState(() {
        _verifying = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('cancel')) {
        setState(() {
          _verifying = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _verifying = false;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verified = hasVerifiedSquarePayment(widget.verifiedPayload);
    final feeStale = verified &&
        widget.bookingTotal != null &&
        widget.tokenizedAtTotal != null &&
        squareFeeChangedSinceTokenize(
          widget.tokenizedAtTotal,
          widget.bookingTotal!,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SquareStepLabel(step: 1, title: 'Billing details'),
        const SizedBox(height: 6),
        if (_verifying)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Opening secure card entry…', style: TextStyle(fontSize: 13)),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 400;
              final fieldDecoration = InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              );
              final nameField = TextField(
                controller: _nameController,
                decoration: fieldDecoration.copyWith(
                  labelText: 'Cardholder name',
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => _invalidateVerification(),
              );
              final zipField = TextField(
                controller: _zipController,
                decoration: fieldDecoration.copyWith(
                  labelText: 'Billing ZIP',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => _invalidateVerification(),
              );

              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: nameField),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: zipField),
                  ],
                );
              }
              return Column(
                children: [
                  nameField,
                  const SizedBox(height: 8),
                  zipField,
                ],
              );
            },
          ),
        if (!_verifying) ...[
          const SizedBox(height: 8),
          Divider(height: 1, color: Color(0x3303930A)),
          const SizedBox(height: 8),
          const SquareStepLabel(step: 2, title: 'Verify card with Square'),
          const SizedBox(height: 6),
          if (verified && !feeStale)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF03930A).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF03930A).withOpacity(0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Color(0xFF03930A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Card verified — confirm your booking below.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          if (feeStale)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total changed — verify again.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: _verifying ? null : _verifyCard,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF03930A),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(
            feeStale
                ? 'Verify again'
                : verified
                    ? 'Verify again'
                    : 'Continue to Square',
          ),
        ),
      ],
    );
  }
}
