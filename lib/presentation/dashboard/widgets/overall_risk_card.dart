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
    final color = context.themeColors.colorForHealthRisk(healthRiskLevel);

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
                const Icon(Icons.error_outline, color: context.themeColors.riskEmergency, size: 32),
                const SizedBox(width: SenvoSpacing.md),
                Expanded(
                  child: Text(
                    errorMessage ?? 'Failed to load risk data',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.themeColors.riskEmergency),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: SenvoSpacing.sm),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: score > 0 ? (100 - score) / 100 : 1.0,
                        strokeWidth: 12,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.2),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$score',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: color,
                            fontSize: 48,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: SenvoSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon, color: color, size: 24),
                    const SizedBox(width: SenvoSpacing.sm),
                    Text(
                      _title.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SenvoSpacing.md),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.themeColors.text.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
    );
  }
}
