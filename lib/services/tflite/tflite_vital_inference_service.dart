import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'model_contract.dart';
import 'vital_model_input.dart';
import 'vitals_inference_result.dart';

class ModelLoadException implements Exception {
  const ModelLoadException(this.message);
  final String message;
  @override
  String toString() => 'ModelLoadException: $message';
}

class TFLiteVitalInferenceService {
  TFLiteVitalInferenceService({this.contract = ModelContract.supplied});

  final ModelContract contract;
  Interpreter? _interpreter;

  bool get isInitialized => _interpreter != null;

  Future<void> initialize() async {
    if (isInitialized) return;
    try {
      final interpreter = await Interpreter.fromAsset(contract.modelAsset);
      _verifyContract(interpreter);
      _interpreter = interpreter;
    } on ModelContractException {
      rethrow;
    } on PlatformException catch (error) {
      throw ModelLoadException(
        error.message ?? 'Unable to load the local model.',
      );
    } catch (error) {
      throw ModelLoadException('Unable to load the local model: $error');
    }
  }

  Future<VitalsInferenceResult> predict({
    required VitalModelInput input,
  }) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw const ModelInferenceException('Model is not initialized.');
    }
    final inputTensor = input.tensor;
    final outputTensor = <List<double>>[List<double>.filled(4, 0)];
    try {
      interpreter.run([inputTensor], outputTensor);
      final values = outputTensor.first
          .map((value) => value.toDouble())
          .toList(growable: false);
      if (values.length != 4 || values.any((value) => !value.isFinite)) {
        throw const ModelOutputException(
          'Model returned non-finite or incomplete values.',
        );
      }
      _validateRange(values[0], 'heart rate', 30, 260);
      _validateRange(values[1], 'SpO2', 50, 100);
      _validateRange(values[2], 'systolic blood pressure', 40, 300);
      _validateRange(values[3], 'diastolic blood pressure', 20, 200);
      return VitalsInferenceResult(
        heartRateBpm: values[0],
        spo2Percent: values[1],
        systolicBp: values[2],
        diastolicBp: values[3],
      );
    } on ModelOutputException {
      rethrow;
    } catch (error) {
      throw ModelInferenceException('Local inference failed: $error');
    }
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }

  void _verifyContract(Interpreter interpreter) {
    final inputs = interpreter.getInputTensors();
    final outputs = interpreter.getOutputTensors();
    if (inputs.length != 1 || outputs.length != 1) {
      throw const ModelContractException(
        'Expected one input tensor and one output tensor.',
      );
    }
    final input = inputs.first;
    final output = outputs.first;
    if (!_sameShape(input.shape, contract.inputShape) ||
        input.type.toString().toLowerCase() != contract.inputType ||
        !_sameShape(output.shape, contract.outputShape) ||
        output.type.toString().toLowerCase() != contract.outputType) {
      throw ModelContractException(
        'Unexpected tensor contract: input ${input.shape}/${input.type}, output ${output.shape}/${output.type}.',
      );
    }
  }

  bool _sameShape(List<int> actual, List<int> expected) =>
      actual.length == expected.length &&
      actual.asMap().entries.every(
        (entry) => entry.value == expected[entry.key],
      );

  void _validateRange(double value, String name, double min, double max) {
    if (value < min || value > max) {
      throw ModelOutputException('Invalid $name output: $value.');
    }
  }
}
