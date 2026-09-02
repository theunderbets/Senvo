class VitalsInferenceResult {
  const VitalsInferenceResult({
    required this.heartRateBpm,
    required this.spo2Percent,
    required this.systolicBp,
    required this.diastolicBp,
    this.confidence,
    this.signalQuality,
  });

  final double heartRateBpm;
  final double spo2Percent;
  final double? systolicBp;
  final double? diastolicBp;
  final double? confidence;
  final double? signalQuality;
}

class ModelOutputException implements Exception {
  const ModelOutputException(this.message);
  final String message;
  @override
  String toString() => 'ModelOutputException: $message';
}
