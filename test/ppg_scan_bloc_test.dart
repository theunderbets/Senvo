import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:senvo_health/features/ppg_scan/domain/entities/ppg_sample.dart';
import 'package:senvo_health/features/ppg_scan/domain/entities/vitals_result.dart';
import 'package:senvo_health/features/ppg_scan/domain/repositories/ppg_repository.dart';
import 'package:senvo_health/features/ppg_scan/domain/usecases/vital_estimators.dart';
import 'package:senvo_health/features/ppg_scan/presentation/bloc/ppg_scan_bloc.dart';
import 'package:senvo_health/features/ppg_scan/presentation/bloc/ppg_scan_event.dart';
import 'package:senvo_health/features/ppg_scan/presentation/bloc/ppg_scan_state.dart';

class FakeRepository implements PpgRepository {
  @override
  Future<List<PPGSample>> acquire({
    required void Function(PPGSample) onSample,
    required void Function(double) onProgress,
  }) async {
    final samples = List.generate(
      90,
      (i) => PPGSample(
        timestamp: i / 30,
        red: 100,
        green: 100 + math.sin(i * .3),
        blue: 90,
      ),
    );
    for (final sample in samples) {
      onSample(sample);
    }
    onProgress(1);
    return samples;
  }
}

class FakeEstimator implements VitalEstimator {
  @override
  VitalsResult estimate(List<PPGSample> samples) => VitalsResult(
    heartRateBpm: 72,
    spo2Percent: 98,
    bloodPressure: const BloodPressure(systolic: 118, diastolic: 76),
    signalQuality: .8,
    timestamp: DateTime(2026),
  );
}

void main() {
  test('scan transitions from scanning to completed', () async {
    final bloc = PpgScanBloc(
      repository: FakeRepository(),
      estimator: FakeEstimator(),
    );
    final completed = bloc.stream.firstWhere(
      (state) => state.status == ScanStatus.completed,
    );
    bloc.add(const BeginScan());
    expect((await completed).result?.heartRateBpm, 72);
    await bloc.close();
  });
}
