import 'package:flutter/material.dart';
import '../../theme/senvo_theme.dart';
import '../../risk/risk_enums.dart';

class RiskStatusCard extends StatelessWidget {
  const RiskStatusCard({
    required this.title,
    required this.riskLevel,
    required this.icon,
    this.value,
    this.subtitle,
    super.key,
  });

  final String title;
  final RiskLevel riskLevel;
  final IconData icon;
  final String? value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final color = context.themeColors.colorForRisk(riskLevel);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SenvoSpacing.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SenvoSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(SenvoRadius.md),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: SenvoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: SenvoSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
