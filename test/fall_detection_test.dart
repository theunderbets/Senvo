import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/features/emergency/domain/fall_detection.dart';

void main() {
  final start = DateTime(2026, 8, 27);
  MotionSample sample(
    int milliseconds,
    double acceleration, {
    double gyro = 0,
  }) => MotionSample(
    timestamp: start.add(Duration(milliseconds: milliseconds)),
    ax: acceleration,
    ay: 0,
    az: 0,
    gx: gyro,
    gy: 0,
    gz: 0,
  );

  test('requires free fall, impact, angular change and inactivity', () {
    final detector = FallDetectionEngine(
      config: const FallDetectionConfig(
        postImpactInactivityDuration: Duration(milliseconds: 200),
      ),
    );
    detector.process(sample(0, 1));
    detector.process(sample(150, 1));
    detector.process(sample(300, 30, gyro: 6));
    detector.process(sample(550, 1));
    final evidence = detector.process(sample(800, 1));
    expect(evidence, isNotNull);
    expect(evidence!.freeFallDetected, isTrue);
    expect(evidence.impactDetected, isTrue);
    expect(evidence.inactivityDetected, isTrue);
    expect(detector.state, FallDetectionState.probableFall);
  });

  test('a single impact does not produce a probable fall', () {
    final detector = FallDetectionEngine();
    detector.process(sample(0, 30));
    expect(detector.state, FallDetectionState.monitoring);
  });

  test('probable fall can recover or confirm', () {
    final detector = FallDetectionEngine(
      config: const FallDetectionConfig(
        postImpactInactivityDuration: Duration(milliseconds: 200),
      ),
    );
    detector.process(sample(0, 1));
    detector.process(sample(150, 1));
    detector.process(sample(300, 30, gyro: 6));
    detector.process(sample(550, 1));
    detector.process(sample(800, 1));
    detector.beginConfirmation();
    expect(detector.state, FallDetectionState.awaitingConfirmation);
    detector.recover();
    expect(detector.state, FallDetectionState.monitoring);
  });
}
