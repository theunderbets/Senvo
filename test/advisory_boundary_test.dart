import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/features/health_advisory/domain/advisory_models.dart';
import 'package:senvo_health/features/heat_stress/domain/heat_stress_models.dart';

void main() {
  test('advisory payload contains summary values only', () {
    final payload = HealthAdvisoryRequest(
      riskTier: 'watch',
      vitals: CurrentVitals(
        heartRateBpm: 92,
        spo2Percent: 97,
        systolicBp: 126,
        diastolicBp: 82,
        signalQuality: .9,
        timestamp: DateTime(2026),
      ),
      riskFactors: const ['Heart rate is elevated'],
    ).toJson();
    expect(payload.containsKey('raw_ppg'), isFalse);
    expect(payload.containsKey('filtered_signal'), isFalse);
    expect(payload.containsKey('feature_vector'), isFalse);
    expect(payload.containsKey('model_input_tensor'), isFalse);
    expect(payload['vitals']['heart_rate_bpm'], 92);
  });

  test('malformed advisory responses are rejected', () {
    expect(
      () => HealthAdvisoryResponse.fromJson(const {
        'advisory': '',
        'action_steps': [],
        'severity': 'normal',
      }),
      throwsFormatException,
    );
    expect(
      () => HealthAdvisoryResponse.fromJson(const {
        'advisory': 'ok',
        'action_steps': [],
        'severity': 'unknown',
      }),
      throwsFormatException,
    );
  });
}
