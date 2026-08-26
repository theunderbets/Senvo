import 'package:equatable/equatable.dart';

class VitalRecord extends Equatable {
  const VitalRecord({
    required this.id,
    required this.timestamp,
    required this.heartRateBpm,
    required this.spo2Percent,
    required this.systolicBp,
    required this.diastolicBp,
    required this.signalQualityIndex,
    required this.measurementStatus,
    this.frameCount,
    this.samplingRate,
    this.algorithmVersion = 'senvo-ppg-1',
  });
  final String id;
  final DateTime timestamp;
  final double heartRateBpm;
  final double spo2Percent;
  final double systolicBp;
  final double diastolicBp;
  final double signalQualityIndex;
  final int? frameCount;
  final double? samplingRate;
  final String measurementStatus;
  final String algorithmVersion;

  @override
  List<Object?> get props => [
    id,
    timestamp,
    heartRateBpm,
    spo2Percent,
    systolicBp,
    diastolicBp,
    signalQualityIndex,
    frameCount,
    samplingRate,
    measurementStatus,
    algorithmVersion,
  ];
}
