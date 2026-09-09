import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/square_runtime_config.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/square_payment_service.dart';
import '../../../../core/utils/card_validation_utils.dart';
import '../../../../core/utils/name_validator.dart';
import '../../../../core/utils/payment_status_map.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/payment_provider.dart';
import 'book_ride/widgets/square_payment_info_banner.dart';

/// Opens the Square wallet add-card flow (same sequence as oda-ride-transport
/// [SquareWalletAddCard] + [PaymentCards.handleSaveCard]).
Future<bool> showSquareWalletAddSheet(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _SquareWalletAddSheet(),
  );
  return saved == true;
}

enum _WalletSavePhase { form, securing, saving }

class _SquareWalletAddSheet extends StatefulWidget {
  const _SquareWalletAddSheet();

  @override
  State<_SquareWalletAddSheet> createState() => _SquareWalletAddSheetState();
}

class _SquareWalletAddSheetState extends State<_SquareWalletAddSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _zipController;

  bool _isPrimary = false;
  _WalletSavePhase _phase = _WalletSavePhase.form;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController =
        TextEditingController(text: NameValidator.format(user?.fullName ?? ''));
    _zipController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  /// Mirrors website `SquareWalletAddCard` open → GET `/users/me`.
  Future<void> _prefillFromProfile() async {
    try {
      final profile = await AuthService().fetchProfile();
      if (!mounted) return;
      if (_nameController.text.trim().isEmpty && profile.fullName.isNotEmpty) {
        _nameController.text = NameValidator.format(profile.fullName);
      }
    } catch (_) {
      /* guest or profile unavailable */
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  String? _validateBilling() {
    final nameError =
        NameValidator.validateCardholderName(_nameController.text);
    if (nameError != null) return nameError;
    return validateZip(_zipController.text);
  }

  Future<void> _saveCard() async {
    final validationError = _validateBilling();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final cardOwnerName = _nameController.text.trim();
    final zipCode = _zipController.text.trim();
    final isPrimary = _isPrimary;

    setState(() {
      _phase = _WalletSavePhase.securing;
      _error = null;
    });

    try {
      final squareRuntime = context.read<SquareRuntimeConfig>();
      SquarePaymentService.instance.attachRuntimeConfig(squareRuntime);
      final payload = await SquarePaymentService.instance.tokenizeCard();

      if (!mounted) return;
      setState(() => _phase = _WalletSavePhase.saving);

      final provider = context.read<PaymentProvider>();
      final ok = await provider.addSquareCard(
        sourceId: payload.sourceId,
        cardOwnerName: cardOwnerName,
        zipCode: zipCode,
        isPrimary: isPrimary,
        verificationToken: payload.verificationToken,
      );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _phase = _WalletSavePhase.form;
          _error = provider.errorMessage ?? 'Failed to save card';
        });
      }
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.toLowerCase().contains('cancel')) {
        setState(() {
          _phase = _WalletSavePhase.form;
          _error = null;
        });
        return;
      }
      setState(() {
        _phase = _WalletSavePhase.form;
        _error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _phase != _WalletSavePhase.form;
    final phaseLabel = switch (_phase) {
      _WalletSavePhase.form => null,
      _WalletSavePhase.securing => 'Opening secure card entry…',
      _WalletSavePhase.saving => 'Saving card to your wallet…',
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add payment card',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: busy ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SquarePaymentInfoBanner(
              checkoutHint: getCheckoutPaymentHint(
                paymentMode: context.watch<SquareRuntimeConfig>().paymentMode,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Saved cards appear at checkout — no need to re-enter each time.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!busy) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder name',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                enabled: !busy,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _zipController,
                decoration: const InputDecoration(
                  labelText: 'Billing ZIP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [zipInputFormatter()],
                maxLength: 10,
                enabled: !busy,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Set as primary payment method for future bookings',
                ),
                value: _isPrimary,
                activeColor: const Color(0xFF03930A),
                onChanged: (v) => setState(() => _isPrimary = v),
              ),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    if (phaseLabel != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        phaseLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : _saveCard,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF03930A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(busy ? 'Please wait…' : 'Continue to Square'),
            ),
          ],
        ),
      ),
    );
  }
}
