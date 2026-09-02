class ModelContract {
  const ModelContract({
    required this.modelAsset,
    required this.inputShape,
    required this.inputType,
    required this.outputShape,
    required this.outputType,
    required this.outputNames,
  });

  final String modelAsset;
  final List<int> inputShape;
  final String inputType;
  final List<int> outputShape;
  final String outputType;
  final List<String> outputNames;

  static const supplied = ModelContract(
    modelAsset: 'assets/models/senvo_vitals.tflite',
    inputShape: [1, 23],
    inputType: 'float32',
    outputShape: [1, 4],
    outputType: 'float32',
    outputNames: [
      'heart_rate_bpm',
      'spo2_percent',
      'systolic_bp',
      'diastolic_bp',
    ],
  );
}

class ModelContractException implements Exception {
  const ModelContractException(this.message);
  final String message;
  @override
  String toString() => 'ModelContractException: $message';
}

class ModelInferenceException implements Exception {
  const ModelInferenceException(this.message);
  final String message;
  @override
  String toString() => 'ModelInferenceException: $message';
}
