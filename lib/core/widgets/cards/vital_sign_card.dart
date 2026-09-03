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
    // We rely on the master prompt's visual rules.
    return Card(
      color: context.themeColors.surface, // Surface (dark blue)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Padding EdgeInsets.all(16)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                if (confidence != null && confidence! < 0.6) ...[
                  const Spacer(),
                  Icon(Icons.warning_amber_rounded, size: 16, color: context.themeColors.riskWatch),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (hasError)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Icon(Icons.error_outline, color: context.themeColors.riskEmergency, size: 20),
                  const SizedBox(width: SenvoSpacing.xs),
                  Expanded(
                    child: Text(
                      errorMessage ?? 'Error',
                      style: TextStyle(color: context.themeColors.riskEmergency, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
