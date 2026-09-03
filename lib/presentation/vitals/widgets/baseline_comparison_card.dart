import 'package:flutter/material.dart';
import '../../../core/theme/senvo_theme.dart';

class BaselineComparisonCard extends StatelessWidget {
  const BaselineComparisonCard({
    required this.title,
    required this.currentValue,
    required this.baselineValue,
    required this.unit,
    required this.icon,
    this.isHigherWorse = true,
    super.key,
  });

  final String title;
  final double currentValue;
  final double baselineValue;
  final String unit;
  final IconData icon;
  final bool isHigherWorse; // E.g. HR up is usually worse, SpO2 up is better

  @override
  Widget build(BuildContext context) {
    final diff = currentValue - baselineValue;
    final isIncrease = diff > 0;
    final isSignificant = diff.abs() > (baselineValue * 0.05); // 5% diff
    
    Color trendColor = context.themeColors.text;
    IconData trendIcon = Icons.trending_flat;

    if (isSignificant) {
      if (isIncrease) {
        trendIcon = Icons.trending_up;
        trendColor = isHigherWorse ? context.themeColors.riskEmergency : context.themeColors.riskNormal;
      } else {
        trendIcon = Icons.trending_down;
        trendColor = isHigherWorse ? context.themeColors.riskNormal : context.themeColors.riskEmergency;
      }
    } else {
      trendColor = context.themeColors.muted;
    }

    final diffString = isIncrease ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SenvoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: context.themeColors.accent),
                const SizedBox(width: SenvoSpacing.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: SenvoSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentValue.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          unit,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Baseline (${baselineValue.toStringAsFixed(1)})',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Row(
                      children: [
                        Icon(trendIcon, size: 16, color: trendColor),
                        const SizedBox(width: 4),
                        Text(
                          '$diffString $unit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
