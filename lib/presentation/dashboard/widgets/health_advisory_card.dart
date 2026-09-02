import 'package:flutter/material.dart';
import '../../../core/theme/senvo_theme.dart';

class HealthAdvisoryCard extends StatelessWidget {
  const HealthAdvisoryCard({
    required this.advisoryText,
    super.key,
  });

  final String advisoryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SenvoSpacing.md),
      decoration: BoxDecoration(
        color: SenvoColors.surface2,
        borderRadius: BorderRadius.circular(SenvoRadius.lg),
        border: Border.all(color: SenvoColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: SenvoColors.accent,
            size: 24,
          ),
          const SizedBox(width: SenvoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Senvo AI Advisory',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: SenvoColors.accent,
                  ),
                ),
                const SizedBox(height: SenvoSpacing.xs),
                Text(
                  advisoryText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
