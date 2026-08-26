import 'dart:math' as math;

/// A numerically stable biquad band-pass section. Coefficients are rebuilt for measured Fs.
class ButterworthBandpass {
  ButterworthBandpass({
    required this.lowHz,
    required this.highHz,
    required this.sampleRateHz,
  });
  final double lowHz;
  final double highHz;
  final double sampleRateHz;

  List<double> filter(List<double> input) {
    if (input.length < 3 || sampleRateHz <= 2 * highHz) {
      return List<double>.from(input);
    }
    final center = math.sqrt(lowHz * highHz);
    final bandwidth = highHz - lowHz;
    final omega = 2 * math.pi * center / sampleRateHz;
    final sinhArgument = math.log(2) / 2 * bandwidth * omega / math.sin(omega);
    final sinh = (math.exp(sinhArgument) - math.exp(-sinhArgument)) / 2;
    final alpha = math.sin(omega) * sinh;
    final b0 = alpha, b1 = 0.0, b2 = -alpha;
    final a0 = 1 + alpha, a1 = -2 * math.cos(omega), a2 = 1 - alpha;
    var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    return input
        .map((x0) {
          final y0 = (b0 * x0 + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2) / a0;
          x2 = x1;
          x1 = x0;
          y2 = y1;
          y1 = y0;
          return y0;
        })
        .toList(growable: false);
  }
}

List<double> detrend(List<double> values) {
  if (values.isEmpty) return const [];
  final mean = values.reduce((a, b) => a + b) / values.length;
  return values.map((value) => value - mean).toList(growable: false);
}

List<double> normalize(List<double> values) {
  if (values.isEmpty) return const [];
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((value) => math.pow(value - mean, 2)).reduce((a, b) => a + b) /
      values.length;
  final std = math.sqrt(variance);
  return std < 1e-9
      ? List.filled(values.length, 0)
      : values.map((value) => (value - mean) / std).toList(growable: false);
}
