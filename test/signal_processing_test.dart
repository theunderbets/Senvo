import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/services/signal_processing/butterworth_filter.dart';
import 'package:senvo_health/services/signal_processing/sqi_calculator.dart';

void main() {
  test('detrend and normalize produce a zero-centred unit signal', () {
    final result = normalize(detrend([2, 4, 6, 8]));
    expect(result.reduce((a, b) => a + b) / result.length, closeTo(0, 1e-9));
    expect(
      result.map((value) => value * value).reduce((a, b) => a + b) /
          result.length,
      closeTo(1, 1e-9),
    );
  });

  test('bandpass retains a heart-rate frequency', () {
    final input = List.generate(
      600,
      (i) => math.sin(2 * math.pi * 1.2 * i / 30),
    );
    final output = ButterworthBandpass(
      lowHz: .7,
      highHz: 4,
      sampleRateHz: 30,
    ).filter(input);
    expect(
      output.skip(100).map((v) => v.abs()).reduce((a, b) => a + b) / 500,
      greaterThan(.05),
    );
  });

  test('SQI rejects a flat signal', () {
    expect(
      const SqiCalculator().calculate(List.filled(300, 0), 30).isAcceptable,
      isFalse,
    );
  });
}
