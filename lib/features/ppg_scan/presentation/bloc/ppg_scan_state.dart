import 'package:equatable/equatable.dart';
import '../../domain/entities/vitals_result.dart';

enum ScanStatus {
  initial,
  requestingPermission,
  initializingCamera,
  ready,
  scanning,
  processing,
  completed,
  insufficientSignal,
  error,
}

class PpgScanState extends Equatable {
  const PpgScanState({
    this.status = ScanStatus.initial,
    this.elapsedTime = 0,
    this.progress = 0,
    this.framesCaptured = 0,
    this.waveformSamples = const [],
    this.signalQuality = 0,
    this.torchEnabled = false,
    this.errorMessage,
    this.result,
  });
  final ScanStatus status;
  final double elapsedTime;
  final double progress;
  final int framesCaptured;
  final List<double> waveformSamples;
  final double signalQuality;
  final bool torchEnabled;
  final String? errorMessage;
  final VitalsResult? result;
  PpgScanState copyWith({
    ScanStatus? status,
    double? elapsedTime,
    double? progress,
    int? framesCaptured,
    List<double>? waveformSamples,
    double? signalQuality,
    bool? torchEnabled,
    String? errorMessage,
    VitalsResult? result,
  }) => PpgScanState(
    status: status ?? this.status,
    elapsedTime: elapsedTime ?? this.elapsedTime,
    progress: progress ?? this.progress,
    framesCaptured: framesCaptured ?? this.framesCaptured,
    waveformSamples: waveformSamples ?? this.waveformSamples,
    signalQuality: signalQuality ?? this.signalQuality,
    torchEnabled: torchEnabled ?? this.torchEnabled,
    errorMessage: errorMessage ?? this.errorMessage,
    result: result ?? this.result,
  );
  @override
  List<Object?> get props => [
    status,
    elapsedTime,
    progress,
    framesCaptured,
    waveformSamples,
    signalQuality,
    torchEnabled,
    errorMessage,
    result,
  ];
}
