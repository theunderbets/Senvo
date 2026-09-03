import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/scan_exception.dart';
import '../../domain/repositories/ppg_repository.dart';
import '../../domain/usecases/vital_estimators.dart';
import '../../../../services/signal_processing/sqi_calculator.dart';
import '../../../../services/signal_processing/butterworth_filter.dart';
import '../../../vitals_history/domain/repositories/vitals_repository.dart';
import 'ppg_scan_event.dart';
import 'ppg_scan_state.dart';

class PpgScanBloc extends Bloc<PpgScanEvent, PpgScanState> {
  PpgScanBloc({
    required this.repository,
    required this.estimator,
    this.vitalsRepository,
    this.sqi = const SqiCalculator(),
  }) : super(const PpgScanState()) {
    on<BeginScan>(_begin);
    on<ResetScan>((event, emit) => emit(const PpgScanState()));
  }
  final PpgRepository repository;
  final VitalEstimator estimator;
  final VitalsRepository? vitalsRepository;
  final SqiCalculator sqi;

  Future<void> _begin(BeginScan event, Emitter<PpgScanState> emit) async {
    emit(
      state.copyWith(
        status: ScanStatus.requestingPermission,
        errorMessage: null,
      ),
    );
    final waveform = <double>[];
    try {
      emit(state.copyWith(status: ScanStatus.scanning, torchEnabled: true));
      final samples = await repository.acquire(
        onSample: (sample) {
          waveform.add(sample.green);
          if (waveform.length > 240) waveform.removeAt(0);
          emit(
            state.copyWith(
              framesCaptured: state.framesCaptured + 1,
              elapsedTime: sample.timestamp,
              waveformSamples: List.unmodifiable(waveform),
            ),
          );
        },
        onProgress: (progress) => emit(
          state.copyWith(progress: progress, elapsedTime: progress * 10),
        ),
      );
      emit(state.copyWith(status: ScanStatus.processing, torchEnabled: false));
      final result = await estimator.estimate(samples);
      final filtered = normalize(
        detrend(samples.map((sample) => sample.green).toList()),
      );
      final sampleRate =
          (samples.length - 1) /
          (samples.last.timestamp - samples.first.timestamp);
      final quality = sqi.calculate(filtered, sampleRate);
      if (!quality.isAcceptable) {
        emit(
          state.copyWith(
            status: ScanStatus.insufficientSignal,
            signalQuality: quality.score,
          ),
        );
        return;
      }
      await vitalsRepository?.saveVitalsResult(
        result,
        frameCount: samples.length,
        samplingRate: sampleRate,
      );
      emit(
        state.copyWith(
          status: ScanStatus.completed,
          result: result,
          signalQuality: quality.score,
        ),
      );
    } on PoorSignalQuality catch (error) {
      emit(
        state.copyWith(
          status: ScanStatus.insufficientSignal,
          errorMessage: error.userMessage,
          torchEnabled: false,
        ),
      );
    } on ScanException catch (error) {
      emit(
        state.copyWith(
          status: ScanStatus.error,
          errorMessage: error.userMessage,
          torchEnabled: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ScanStatus.error,
          errorMessage: 'The scan failed. Please try again.',
          torchEnabled: false,
        ),
      );
    }
  }
}
