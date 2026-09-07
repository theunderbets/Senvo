import 'package:equatable/equatable.dart';
import '../../domain/disaster_models.dart';

abstract class DisasterModeEvent extends Equatable {
  const DisasterModeEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckDisasterReadiness extends DisasterModeEvent {}

class UpdateDisasterState extends DisasterModeEvent {
  final bool hasNetwork;
  final double currentRiskScore;
  
  const UpdateDisasterState({required this.hasNetwork, required this.currentRiskScore});
  
  @override
  List<Object?> get props => [hasNetwork, currentRiskScore];
}
