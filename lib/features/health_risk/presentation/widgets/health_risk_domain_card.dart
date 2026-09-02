import 'package:flutter/material.dart';
import '../../domain/entities/risk_result.dart';
import '../../../../core/theme/senvo_theme.dart';

class HealthRiskDomainCard extends StatelessWidget {
  final DomainRiskResult domainResult;
  final VoidCallback? onTap;

  const HealthRiskDomainCard({
    super.key,
    required this.domainResult,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = SenvoColors.colorForRisk(domainResult.level);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: SenvoSpacing.sm, horizontal: SenvoSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SenvoRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(SenvoSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(SenvoRadius.md),
                ),
                child: Icon(
                  _getIconForDomain(domainResult.domain),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: SenvoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domainResult.domain,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      domainResult.level.name.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    domainResult.score.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: SenvoColors.text,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right, color: SenvoColors.muted, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForDomain(String domain) {
    switch (domain.toLowerCase()) {
      case 'heat stress':
        return Icons.thermostat;
      case 'respiratory':
        return Icons.air;
      case 'cardiovascular':
        return Icons.favorite;
      case 'dehydration':
        return Icons.water_drop;
      case 'fatigue':
        return Icons.battery_alert;
      default:
        return Icons.health_and_safety;
    }
  }
}
