import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/services/tflite/model_contract.dart';
import 'package:senvo_health/services/tflite/tflite_vital_inference_service.dart';
import 'package:senvo_health/services/tflite/vital_model_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('supplied model contract describes the packaged feature tensor', () {
    expect(ModelContract.supplied.inputShape, [1, 23]);
    expect(ModelContract.supplied.inputType, 'float32');
    expect(ModelContract.supplied.outputShape, [1, 4]);
    expect(ModelContract.supplied.outputNames, [
      'heart_rate_bpm',
      'spo2_percent',
      'systolic_bp',
      'diastolic_bp',
    ]);
  });

  test('model input rejects wrong feature count and non-finite values', () {
    expect(() => const VitalModelInput([1, 2]).tensor, throwsArgumentError);
    expect(
      () => VitalModelInput([...List<double>.filled(22, 1), double.nan]).tensor,
      throwsArgumentError,
    );
  });

  test(
    'packaged model initializes and validates its tensor contract',
    () async {
      if (Platform.isLinux) {
        return;
      }
      final service = TFLiteVitalInferenceService();
      addTearDown(service.close);
      await service.initialize();
      expect(service.isInitialized, isTrue);
    },
  );
}
