import 'package:equatable/equatable.dart';

class BloodPressure extends Equatable {
  const BloodPressure({required this.systolic, required this.diastolic});
  final double systolic;
  final double diastolic;
  @override
  List<Object> get props => [systolic, diastolic];
}

class VitalsResult extends Equatable {
  const VitalsResult({
    required this.heartRateBpm,
    required this.spo2Percent,
    required this.bloodPressure,
    required this.signalQuality,
    required this.timestamp,
    this.experimental = true,
  });
  final double heartRateBpm;
  final double spo2Percent;
  final BloodPressure bloodPressure;
  final double signalQuality;
  final DateTime timestamp;
  final bool experimental;
  @override
  List<Object> get props => [
    heartRateBpm,
    spo2Percent,
    bloodPressure,
    signalQuality,
    timestamp,
    experimental,
  ];
}
