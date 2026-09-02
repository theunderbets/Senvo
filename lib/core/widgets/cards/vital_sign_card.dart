import 'package:flutter/material.dart';
import '../../theme/senvo_theme.dart';
import '../../risk/risk_enums.dart';

class VitalSignCard extends StatelessWidget {
  const VitalSignCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.riskLevel = RiskLevel.unknown,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.confidence,
    super.key,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final RiskLevel riskLevel;

  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final double? confidence;

  @override
  Widget build(BuildContext context) {
    final color = riskLevel != RiskLevel.unknown 
        ? SenvoColors.colorForRisk(riskLevel)
        : SenvoColors.text;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SenvoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: SenvoColors.muted),
                const SizedBox(width: SenvoSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (confidence != null && confidence! < 0.6) ...[
                  const Spacer(),
                  const Icon(Icons.warning_amber_rounded, size: 16, color: SenvoColors.riskWatch),
                ],
              ],
            ),
            const SizedBox(height: SenvoSpacing.md),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (hasError)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Icon(Icons.error_outline, color: SenvoColors.riskEmergency, size: 24),
                  const SizedBox(width: SenvoSpacing.xs),
                  Expanded(
                    child: Text(
                      errorMessage ?? 'Failed to load',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SenvoColors.riskEmergency),
                    ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                    ),
                  ),
                  const SizedBox(width: SenvoSpacing.xs),
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
