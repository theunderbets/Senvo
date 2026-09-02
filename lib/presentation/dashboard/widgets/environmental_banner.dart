import 'package:flutter/material.dart';
import '../../../core/theme/senvo_theme.dart';
import '../../../core/risk/risk_enums.dart';

class EnvironmentalBanner extends StatelessWidget {
  const EnvironmentalBanner({
    required this.temperature,
    required this.humidity,
    required this.aqi,
    required this.heatStressRisk,
    super.key,
  });

  final double temperature;
  final double humidity;
  final int aqi;
  final RiskLevel heatStressRisk;

  @override
  Widget build(BuildContext context) {
    final riskColor = SenvoColors.colorForRisk(heatStressRisk);

    return Container(
      padding: const EdgeInsets.all(SenvoSpacing.md),
      decoration: BoxDecoration(
        color: SenvoColors.surface,
        borderRadius: BorderRadius.circular(SenvoRadius.lg),
        border: Border.all(color: SenvoColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 20, color: SenvoColors.muted),
              const SizedBox(width: SenvoSpacing.sm),
              Text(
                'Local Environment',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(SenvoRadius.sm),
                ),
                child: Text(
                  heatStressRisk == RiskLevel.low ? 'Favorable' : 'Elevated Risk',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SenvoSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric(context, '${temperature.toStringAsFixed(1)}°C', 'Temp'),
              _buildMetric(context, '${humidity.toStringAsFixed(0)}%', 'Humidity'),
              _buildMetric(context, '$aqi', 'AQI'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: SenvoColors.text,
          ),
        ),
        const SizedBox(height: SenvoSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
