import 'dart:math' as math;

class SignalQuality {
  const SignalQuality({required this.score, required this.label});
  final double score;
  final String label;
  bool get isAcceptable => score >= 0.50;
}

class SqiCalculator {
  const SqiCalculator({this.minimumAmplitude = 0.01});
  final double minimumAmplitude;

  SignalQuality calculate(List<double> signal, double sampleRate) {
    if (signal.length < 30 || sampleRate <= 0) {
      return const SignalQuality(score: 0, label: 'POOR');
    }
    final mean = signal.reduce((a, b) => a + b) / signal.length;
    final variance =
        signal
            .map((value) => math.pow(value - mean, 2))
            .reduce((a, b) => a + b) /
        signal.length;
    final rms = math.sqrt(variance);
    if (rms < minimumAmplitude || signal.any((value) => value.abs() > 8)) {
      return const SignalQuality(score: 0.15, label: 'POOR');
    }
    var crossings = 0;
    for (var i = 1; i < signal.length; i++) {
      if ((signal[i - 1] < 0) != (signal[i] < 0)) crossings++;
    }
    final estimatedHz = crossings / 2 * sampleRate / signal.length;
    final periodicity = (1 - ((estimatedHz - 1.5).abs() / 2.5)).clamp(0.0, 1.0);
    final score = (0.55 * periodicity + 0.45 * (rms / (rms + 0.25))).clamp(
      0.0,
      1.0,
    );
    return SignalQuality(
      score: score,
      label: score >= 0.75
          ? 'GOOD'
          : score >= 0.50
          ? 'FAIR'
          : 'POOR',
    );
  }
}
