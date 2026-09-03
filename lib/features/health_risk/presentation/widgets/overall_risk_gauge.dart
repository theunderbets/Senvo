import 'package:flutter/material.dart';
import '../../../../core/risk/risk_enums.dart';
import '../../../../core/theme/senvo_theme.dart';

class OverallRiskGauge extends StatelessWidget {
  final double score;
  final RiskLevel level;

  const OverallRiskGauge({
    super.key,
    required this.score,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colorForRisk(level);

    return Container(
      padding: const EdgeInsets.all(SenvoSpacing.xl),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color, width: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            level.name.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
