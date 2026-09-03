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
    final riskColor = context.themeColors.colorForRisk(heatStressRisk);

    return Card(
      color: context.themeColors.surface, // Surface (dark blue)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'Local Environment',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
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
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
