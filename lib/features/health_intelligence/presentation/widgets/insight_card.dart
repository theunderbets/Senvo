import 'package:flutter/material.dart';
import '../../domain/entities/health_insight.dart';

class InsightCard extends StatelessWidget {
  final HealthInsight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (insight.type) {
      case InsightType.positiveTrend:
        icon = Icons.trending_up;
        iconColor = Colors.green;
        bgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case InsightType.anomaly:
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case InsightType.caution:
        icon = Icons.error_outline;
        iconColor = Colors.red;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case InsightType.educational:
        icon = Icons.lightbulb_outline;
        iconColor = Colors.blue;
        bgColor = Colors.blue.withValues(alpha: 0.1);
        break;
    }

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insight.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (insight.urgency == InsightUrgency.high)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HIGH',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (insight.relatedDomain != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  insight.relatedDomain!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
