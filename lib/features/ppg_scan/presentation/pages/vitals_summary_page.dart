import 'package:flutter/material.dart';
import '../../domain/entities/vitals_result.dart';

class VitalsSummaryPage extends StatelessWidget {
  const VitalsSummaryPage({
    required this.result,
    required this.onScanAgain,
    super.key,
  });
  final VitalsResult result;
  final VoidCallback onScanAgain;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff0b1719),
    appBar: AppBar(
      title: const Text('Vitals summary'),
      backgroundColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'SCAN COMPLETE',
          style: TextStyle(
            color: const Color(0xff63d7b0),
            letterSpacing: 1.5,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your measurement',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        _quality(context),
        const SizedBox(height: 16),
        Row(
          children: [
            _card(
              context,
              'Heart rate',
              result.heartRateBpm.toStringAsFixed(0),
              'BPM',
            ),
            const SizedBox(width: 12),
            _card(
              context,
              'Blood oxygen',
              result.spo2Percent.toStringAsFixed(0),
              '%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _bpCard(context),
        const SizedBox(height: 16),
        const Text(
          'SpO2 and blood pressure are experimental, non-clinical estimates. Do not use them for medical decisions.',
          style: TextStyle(color: Color(0xffa4b8b7), height: 1.4),
        ),
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
  Widget _quality(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xff122426),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_rounded, color: Color(0xff63d7b0)),
        const SizedBox(width: 12),
        Text(
          'Signal quality  ${result.signalQuality >= .75 ? 'GOOD' : 'FAIR'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          '${(result.signalQuality * 100).round()}%',
          style: const TextStyle(
            color: Color(0xff63d7b0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
  Widget _card(BuildContext context, String title, String value, String unit) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xff122426),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xffa4b8b7))),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(unit, style: const TextStyle(color: Color(0xffa4b8b7))),
            ],
          ),
        ),
      );
  Widget _bpCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff122426),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.favorite_outline, color: Color(0xffff9a7a)),
        const SizedBox(width: 12),
        const Text(
          'Blood pressure',
          style: TextStyle(color: Color(0xffa4b8b7)),
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
