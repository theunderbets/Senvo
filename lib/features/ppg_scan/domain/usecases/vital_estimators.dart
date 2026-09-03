import 'dart:math' as math;
import '../entities/ppg_sample.dart';
import '../entities/vitals_result.dart';
import '../../../../services/signal_processing/butterworth_filter.dart';
import '../../../../services/tflite/tflite_vital_inference_service.dart';
import '../../../../services/tflite/vital_model_input.dart';
import 'ppg_feature_extractor.dart';

abstract interface class VitalEstimator {
  Future<VitalsResult> estimate(List<PPGSample> samples);
}

class ExperimentalVitalEstimator implements VitalEstimator {
  const ExperimentalVitalEstimator();
  @override
  Future<VitalsResult> estimate(List<PPGSample> samples) async {
    if (samples.length < 30) throw StateError('Insufficient samples');
    final duration = samples.last.timestamp - samples.first.timestamp;
    if (!duration.isFinite || duration <= 0) {
      throw StateError('Invalid sample timing');
    }
    final fs = (samples.length - 1) / duration;
    if (!fs.isFinite || fs <= 0) {
      throw StateError('Invalid sample rate');
    }
    final green = samples.map((sample) => sample.green).toList();
    final filtered = normalize(
      ButterworthBandpass(
        lowHz: 0.7,
        highHz: 4,
        sampleRateHz: fs,
      ).filter(detrend(green)),
    );
    var peaks = <int>[];
    for (var i = 1; i < filtered.length - 1; i++) {
      if (filtered[i] > filtered[i - 1] &&
          filtered[i] >= filtered[i + 1] &&
          filtered[i] > 0.4 &&
          (peaks.isEmpty || i - peaks.last > fs * 0.35)) {
        peaks.add(i);
      }
    }
    final bpm = peaks.length > 1
        ? 60 * fs * (peaks.length - 1) / (peaks.last - peaks.first)
        : 72.0;
    final redAc = _range(samples.map((s) => s.red));
    final blueAc = _range(samples.map((s) => s.blue));
    final redDc =
        samples.map((s) => s.red).reduce((a, b) => a + b) / samples.length;
    final blueDc =
        samples.map((s) => s.blue).reduce((a, b) => a + b) / samples.length;
    final ratio = blueAc == 0 || blueDc == 0
        ? 0.5
        : (redAc / redDc) / (blueAc / blueDc);
    final spo2 = (110 - 25 * ratio).clamp(70, 100).toDouble();
    return VitalsResult(
      heartRateBpm: bpm.clamp(42, 240),
      spo2Percent: spo2,
      bloodPressure: const BloodPressure(systolic: 118, diastolic: 76),
      signalQuality: 0.75,
      timestamp: DateTime.now(),
    );
  }

  double _range(Iterable<double> values) {
    final list = values.toList();
    return list.reduce(math.max) - list.reduce(math.min);
  }
}

class TFLiteVitalEstimator implements VitalEstimator {
  TFLiteVitalEstimator(this.inferenceService);
  final TFLiteVitalInferenceService inferenceService;

  @override
  Future<VitalsResult> estimate(List<PPGSample> samples) async {
    if (samples.length < 30) throw StateError('Insufficient samples');
    
    // Extract features
    final features = PPGFeatureExtractor.extract(samples);
    
    if (!inferenceService.isInitialized) {
      await inferenceService.initialize();
    }
    
    final input = VitalModelInput(features);
    final prediction = await inferenceService.predict(input: input);
    
    return VitalsResult(
      heartRateBpm: prediction.heartRateBpm.clamp(42, 240),
      spo2Percent: prediction.spo2Percent.clamp(70, 100),
      bloodPressure: BloodPressure(
        systolic: prediction.systolicBp.round(),
        diastolic: prediction.diastolicBp.round(),
      ),
      signalQuality: 0.85,
      timestamp: DateTime.now(),
    );
  }
}
