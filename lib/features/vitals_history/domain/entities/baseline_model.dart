import 'package:equatable/equatable.dart';

class BaselineModel extends Equatable {
  const BaselineModel({
    required this.calculatedAt,
    required this.averageHeartRate,
    required this.averageSpo2,
    required this.averageSystolicBp,
    required this.averageDiastolicBp,
    required this.averageSqi,
    required this.sampleCount,
  });
  final DateTime calculatedAt;
  final double averageHeartRate;
  final double averageSpo2;
  final double averageSystolicBp;
  final double averageDiastolicBp;
  final double averageSqi;
  final int sampleCount;
  @override
  List<Object> get props => [
    calculatedAt,
    averageHeartRate,
    averageSpo2,
    averageSystolicBp,
    averageDiastolicBp,
    averageSqi,
    sampleCount,
  ];
}
