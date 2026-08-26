import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/features/ppg_scan/data/models/roi_config.dart';
import 'package:senvo_health/features/ppg_scan/domain/entities/ppg_sample.dart';
import 'package:senvo_health/features/ppg_scan/domain/entities/vitals_result.dart';

void main() {
  test('default ROI is the required 64 by 64 region', () {
    const roi = RoiConfig();
    expect(roi.width, 64);
    expect(roi.height, 64);
  });

  test('PPG sample and result retain channel and quality data', () {
    const sample = PPGSample(timestamp: 1, red: 10, green: 20, blue: 30);
    final result = VitalsResult(
      heartRateBpm: 72,
      spo2Percent: 98,
      bloodPressure: const BloodPressure(systolic: 118, diastolic: 76),
      signalQuality: .8,
      timestamp: DateTime(2026),
    );
    expect(sample.green, 20);
    expect(result.experimental, isTrue);
  });
}
