import 'package:flutter/material.dart';
import '../../../core/theme/senvo_theme.dart';
import '../../../core/risk/risk_enums.dart';

class OverallRiskCard extends StatelessWidget {
  const OverallRiskCard({
    required this.healthRiskLevel,
    required this.score,
    required this.message,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    super.key,
  });

  final HealthRiskLevel healthRiskLevel;
  final int score;
  final String message;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  String get _title {
    switch (healthRiskLevel) {
      case HealthRiskLevel.normal:
        return 'All Systems Normal';
      case HealthRiskLevel.watch:
        return 'Elevated Risk Detected';
      case HealthRiskLevel.alert:
        return 'High Risk Warning';
      case HealthRiskLevel.emergency:
        return 'Medical Emergency';
    }
  }

  IconData get _icon {
    switch (healthRiskLevel) {
      case HealthRiskLevel.normal:
        return Icons.check_circle_outline;
      case HealthRiskLevel.watch:
        return Icons.warning_amber_rounded;
      case HealthRiskLevel.alert:
        return Icons.error_outline;
      case HealthRiskLevel.emergency:
        return Icons.local_hospital_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = SenvoColors.colorForHealthRisk(healthRiskLevel);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SenvoRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(SenvoSpacing.lg),
      child: isLoading 
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(SenvoSpacing.md),
              child: CircularProgressIndicator(),
            ),
          )
        : hasError
          ? Row(
              children: [
                const Icon(Icons.error_outline, color: SenvoColors.riskEmergency, size: 32),
                const SizedBox(width: SenvoSpacing.md),
                Expanded(
                  child: Text(
                    errorMessage ?? 'Failed to load risk data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SenvoColors.riskEmergency),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_icon, color: color, size: 32),
                    const SizedBox(width: SenvoSpacing.sm),
                    Expanded(
                      child: Text(
                        _title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      '$score/100',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SenvoSpacing.md),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SenvoColors.text.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
    );
  }
}
