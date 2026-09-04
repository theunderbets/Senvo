import 'package:flutter/material.dart';
import '../../domain/entities/vitals_result.dart';
import '../../../../core/theme/senvo_theme.dart';

class VitalsSummaryPage extends StatelessWidget {
  const VitalsSummaryPage({
    required this.result,
    required this.onScanAgain,
    super.key,
  });
  final VitalsResult result;
  final VoidCallback onScanAgain;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeColors = context.themeColors;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vitals summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'SCAN COMPLETE',
            style: TextStyle(
              color: colorScheme.primary,
              letterSpacing: 1.5,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your measurement',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _quality(context, colorScheme, themeColors),
          const SizedBox(height: 16),
          Row(
            children: [
              _card(
                context,
                'Heart rate',
                result.heartRateBpm.toStringAsFixed(0),
                'BPM',
                colorScheme,
                theme,
                themeColors,
              ),
              const SizedBox(width: 12),
              _card(
                context,
                'Blood oxygen',
                result.spo2Percent.toStringAsFixed(0),
                '%',
                colorScheme,
                theme,
                themeColors,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _bpCard(context, colorScheme, theme, themeColors),
          const SizedBox(height: 16),
          Text(
            'SpO2 and blood pressure are experimental, non-clinical estimates. Do not use them for medical decisions.',
            style: TextStyle(color: themeColors.muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.check),
            label: const Text('Save & Return to Dashboard'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan again'),
          ),
        ],
      ),
    );
  }

  Widget _quality(BuildContext context, ColorScheme colorScheme, SenvoThemeColors themeColors) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: themeColors.surface2,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.verified_rounded, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          'Signal quality  ${result.signalQuality >= .75 ? 'GOOD' : 'FAIR'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          '${(result.signalQuality * 100).round()}%',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _card(BuildContext context, String title, String value, String unit, ColorScheme colorScheme, ThemeData theme, SenvoThemeColors themeColors) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: themeColors.surface2,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: themeColors.muted)),
              const SizedBox(height: 16),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(unit, style: TextStyle(color: themeColors.muted)),
            ],
          ),
        ),
      );

  Widget _bpCard(BuildContext context, ColorScheme colorScheme, ThemeData theme, SenvoThemeColors themeColors) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: themeColors.surface2,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.favorite_outline, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          'Blood pressure',
          style: TextStyle(color: themeColors.muted),
        ),
        const Spacer(),
        Text(
          '${result.bloodPressure.systolic.toStringAsFixed(0)} / ${result.bloodPressure.diastolic.toStringAsFixed(0)} mmHg',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    ),
  );
}
