import 'package:flutter/material.dart';

/// Compact step chip — matches web SquarePaymentForm step strip.
class SquareStepLabel extends StatelessWidget {
  const SquareStepLabel({
    super.key,
    required this.step,
    required this.title,
  });

  final int step;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF03930A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'STEP $step',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Color(0xFF03930A),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
          ),
        ),
      ],
    );
  }
}
